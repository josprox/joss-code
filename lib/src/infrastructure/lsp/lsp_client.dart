import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import '../../core/logging/app_logger.dart';
import '../../domain/editor/editor_models.dart';
import '../../domain/lsp/lsp_models.dart';

class GenericLspClient {
  GenericLspClient(this._logger);

  final AppLogger _logger;
  final Map<EditorLanguage, _LspProcess> _servers = {};
  final StreamController<List<LspDiagnostic>> _diagnosticsController =
      StreamController<List<LspDiagnostic>>.broadcast();

  Stream<List<LspDiagnostic>> get diagnostics => _diagnosticsController.stream;

  Future<void> start({
    required LspServerDefinition definition,
    required String workspacePath,
  }) async {
    if (_servers.containsKey(definition.language)) {
      return;
    }
    try {
      final process = await Process.start(
        definition.command,
        definition.arguments,
        workingDirectory: workspacePath,
        runInShell: Platform.isWindows,
      );
      final server = _LspProcess(process, _handleNotification);
      _servers[definition.language] = server;
      process.stdout.listen(server.handleBytes);
      process.stderr
          .transform(utf8.decoder)
          .listen((line) => _logger.warning('LSP stderr: $line'));
      await request(definition.language, 'initialize', {
        'processId': pid,
        'rootUri': Uri.directory(workspacePath).toString(),
        'capabilities': _clientCapabilities,
        'initializationOptions': definition.initializationOptions,
      });
      notify(definition.language, 'initialized', {});
    } on Object catch (error) {
      _logger.error('Failed to start LSP ${definition.language.name}', error);
      rethrow;
    }
  }

  Future<Map<String, Object?>?> request(
    EditorLanguage language,
    String method,
    Object? params,
  ) {
    final server = _servers[language];
    if (server == null) {
      throw StateError('LSP server is not running for ${language.name}');
    }
    return server.sendRequest(method, params);
  }

  void notify(EditorLanguage language, String method, Object? params) {
    final server = _servers[language];
    if (server == null) {
      return;
    }
    server.sendNotification(method, params);
  }

  void didOpen({
    required EditorLanguage language,
    required String path,
    required String content,
  }) {
    notify(language, 'textDocument/didOpen', {
      'textDocument': {
        'uri': Uri.file(path).toString(),
        'languageId': language.name,
        'version': 1,
        'text': content,
      },
    });
  }

  Future<List<LspCompletionItem>> completion({
    required EditorLanguage language,
    required String path,
    required int line,
    required int character,
  }) async {
    final response = await request(language, 'textDocument/completion', {
      'textDocument': {'uri': Uri.file(path).toString()},
      'position': {'line': line, 'character': character},
    });
    final result = response?['result'];
    final items = result is Map ? result['items'] : result;
    if (items is! List) {
      return const [];
    }
    return items
        .whereType<Map>()
        .map((item) {
          return LspCompletionItem(
            label: item['label']?.toString() ?? '',
            detail: item['detail']?.toString(),
            insertText: item['insertText']?.toString(),
          );
        })
        .where((item) => item.label.isNotEmpty)
        .toList();
  }

  Future<void> dispose() async {
    for (final entry in _servers.entries) {
      entry.value.process.kill();
    }
    _servers.clear();
    await _diagnosticsController.close();
  }

  void _handleNotification(Map<String, Object?> message) {
    if (message['method'] != 'textDocument/publishDiagnostics') {
      return;
    }
    final params = message['params'];
    if (params is! Map) {
      return;
    }
    final uri = params['uri']?.toString();
    final diagnostics = params['diagnostics'];
    if (uri == null || diagnostics is! List) {
      return;
    }
    final path = Uri.parse(uri).toFilePath(windows: Platform.isWindows);
    _diagnosticsController.add(
      diagnostics.whereType<Map>().map((item) {
        final range = item['range'];
        final start = range is Map ? range['start'] : null;
        return LspDiagnostic(
          path: path,
          message: item['message']?.toString() ?? 'Diagnostic',
          severity: (item['severity'] as num?)?.toInt() ?? 3,
          line: start is Map ? (start['line'] as num?)?.toInt() ?? 0 : 0,
          character: start is Map
              ? (start['character'] as num?)?.toInt() ?? 0
              : 0,
        );
      }).toList(),
    );
  }
}

class _LspProcess {
  _LspProcess(this.process, this.onNotification);

  final Process process;
  final void Function(Map<String, Object?> message) onNotification;
  final Map<int, Completer<Map<String, Object?>?>> _pending = {};
  final BytesBuilder _buffer = BytesBuilder(copy: false);
  int _nextId = 1;

  Future<Map<String, Object?>?> sendRequest(String method, Object? params) {
    final id = _nextId++;
    final completer = Completer<Map<String, Object?>?>();
    _pending[id] = completer;
    _write({'jsonrpc': '2.0', 'id': id, 'method': method, 'params': params});
    return completer.future.timeout(
      const Duration(seconds: 20),
      onTimeout: () {
        _pending.remove(id);
        return null;
      },
    );
  }

  void sendNotification(String method, Object? params) {
    _write({'jsonrpc': '2.0', 'method': method, 'params': params});
  }

  void _write(Map<String, Object?> message) {
    final payload = utf8.encode(jsonEncode(message));
    process.stdin.add(utf8.encode('Content-Length: ${payload.length}\r\n\r\n'));
    process.stdin.add(payload);
  }

  void handleBytes(List<int> chunk) {
    _buffer.add(chunk);
    while (true) {
      final bytes = _buffer.toBytes();
      final headerEnd = _indexOfHeaderEnd(bytes);
      if (headerEnd == -1) {
        return;
      }
      final header = ascii.decode(bytes.sublist(0, headerEnd));
      final lengthMatch = RegExp(
        r'Content-Length:\s*(\d+)',
        caseSensitive: false,
      ).firstMatch(header);
      if (lengthMatch == null) {
        _resetBuffer(bytes.sublist(headerEnd + 4));
        continue;
      }
      final length = int.parse(lengthMatch.group(1)!);
      final messageStart = headerEnd + 4;
      final messageEnd = messageStart + length;
      if (bytes.length < messageEnd) {
        return;
      }
      final json =
          jsonDecode(utf8.decode(bytes.sublist(messageStart, messageEnd)))
              as Map<String, Object?>;
      final id = json['id'];
      if (id is int) {
        _pending.remove(id)?.complete(json);
      } else {
        onNotification(json);
      }
      _resetBuffer(bytes.sublist(messageEnd));
    }
  }

  int _indexOfHeaderEnd(List<int> bytes) {
    for (var i = 0; i <= bytes.length - 4; i++) {
      if (bytes[i] == 13 &&
          bytes[i + 1] == 10 &&
          bytes[i + 2] == 13 &&
          bytes[i + 3] == 10) {
        return i;
      }
    }
    return -1;
  }

  void _resetBuffer(List<int> bytes) {
    _buffer.clear();
    if (bytes.isNotEmpty) {
      _buffer.add(bytes);
    }
  }
}

const Map<String, Object?> _clientCapabilities = {
  'textDocument': {
    'completion': {
      'completionItem': {'snippetSupport': true},
    },
    'hover': {
      'contentFormat': ['markdown', 'plaintext'],
    },
    'definition': {},
    'documentSymbol': {},
    'formatting': {},
    'codeAction': {},
    'rename': {'prepareSupport': true},
  },
  'workspace': {'workspaceFolders': true, 'configuration': true},
};
