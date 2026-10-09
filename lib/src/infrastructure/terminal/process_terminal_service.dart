import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:uuid/uuid.dart';

import '../../core/logging/app_logger.dart';
import '../../domain/terminal/terminal_models.dart';

class ProcessTerminalService {
  ProcessTerminalService(this._logger);

  final AppLogger _logger;
  final Map<String, Process> _processes = {};
  final Map<String, TerminalSession> _sessions = {};
  final StreamController<TerminalSession> _updates =
      StreamController<TerminalSession>.broadcast();
  final Uuid _uuid = const Uuid();

  Stream<TerminalSession> get updates => _updates.stream;

  Future<TerminalSession> createSession({
    required String cwd,
    String? preferredShell,
  }) async {
    final id = _uuid.v4();
    final shell = _resolveShell(preferredShell);
    var session = TerminalSession(
      id: id,
      title: shell.title,
      kind: shell.kind,
      cwd: cwd,
      isRunning: false,
    );

    if (Platform.isAndroid || Platform.isIOS) {
      session = session.copyWith(
        kind: TerminalKind.fallback,
        title: 'Tasks',
        output:
            'Interactive PTY is not available on mobile. Use tasks or remote shells.\n',
      );
      _emit(session);
      return session;
    }

    try {
      final process = await Process.start(
        shell.executable,
        shell.arguments,
        workingDirectory: cwd,
        runInShell: false,
      );
      _processes[id] = process;
      session = session.copyWith(
        isRunning: true,
        output: '${shell.title} started in $cwd\n',
      );
      _emit(session);
      process.stdout.transform(utf8.decoder).listen((chunk) {
        _appendOutput(id, chunk);
      });
      process.stderr.transform(utf8.decoder).listen((chunk) {
        _appendOutput(id, chunk);
      });
      process.exitCode.then((exitCode) {
        _processes.remove(id);
        if (!_sessions.containsKey(id)) {
          return;
        }
        final current = _sessions[id] ?? session;
        _emit(
          current.copyWith(
            isRunning: false,
            output:
                '${current.output}\n[terminal closed: exit code $exitCode]\n',
          ),
        );
      });
      return session;
    } on Object catch (error) {
      _logger.error('Failed to start terminal', error);
      session = session.copyWith(output: 'Failed to start shell: $error\n');
      _emit(session);
      return session;
    }
  }

  void sendInput(TerminalSession session, String command) {
    final current = _sessions[session.id] ?? session;
    final normalized = command.trim().toLowerCase();
    if (normalized == 'clear' || normalized == 'cls') {
      _emit(
        current.copyWith(output: '', history: [...current.history, command]),
      );
      return;
    }
    if (normalized == 'exit') {
      _processes.remove(current.id)?.kill();
      _emit(
        current.copyWith(
          output: '${current.output}\n[terminal closed]\n',
          history: [...current.history, command],
          isRunning: false,
        ),
      );
      return;
    }

    final process = _processes[current.id];
    if (process == null) {
      _emit(
        current.copyWith(
          output:
              '${current.output}\n> $command\nTerminal process is not running.\n',
          history: [...current.history, command],
        ),
      );
      return;
    }
    process.stdin.writeln(command);
    _emit(current.copyWith(history: [...current.history, command]));
  }

  void sendRawInput(String sessionId, String data) {
    final process = _processes[sessionId];
    final session = _sessions[sessionId];
    if (process == null || session == null) {
      return;
    }
    process.stdin.add(utf8.encode(data));
  }

  Future<void> disposeSession(String id) async {
    final process = _processes.remove(id);
    _sessions.remove(id);
    process?.kill();
  }

  void _appendOutput(String id, String chunk) {
    final session = _sessions[id];
    if (session == null) {
      return;
    }
    _emit(session.copyWith(output: session.output + chunk));
  }

  void _emit(TerminalSession session) {
    _sessions[session.id] = session;
    _updates.add(session);
  }

  _ShellDefinition _resolveShell(String? preferredShell) {
    final preferred = preferredShell?.trim().toLowerCase();
    if (preferred != null && preferred.isNotEmpty) {
      if (preferred == 'powershell' || preferred == 'powershell.exe') {
        return const _ShellDefinition(
          'powershell.exe',
          ['-NoLogo'],
          TerminalKind.powershell,
          'PowerShell',
        );
      }
      if (preferred == 'cmd' || preferred == 'cmd.exe') {
        return const _ShellDefinition('cmd.exe', [], TerminalKind.cmd, 'CMD');
      }
      if (preferred == 'bash') {
        return const _ShellDefinition(
          'bash',
          ['-l'],
          TerminalKind.bash,
          'Bash',
        );
      }
      if (preferred == 'zsh') {
        return const _ShellDefinition('zsh', ['-l'], TerminalKind.zsh, 'Zsh');
      }
      return _ShellDefinition(
        preferredShell!,
        const [],
        TerminalKind.fallback,
        preferredShell,
      );
    }
    if (Platform.isWindows) {
      return const _ShellDefinition(
        'powershell.exe',
        ['-NoLogo'],
        TerminalKind.powershell,
        'PowerShell',
      );
    }
    final shell = Platform.environment['SHELL'] ?? '/bin/bash';
    if (shell.endsWith('zsh')) {
      return _ShellDefinition(shell, const ['-l'], TerminalKind.zsh, 'Zsh');
    }
    return _ShellDefinition(shell, const ['-l'], TerminalKind.bash, 'Bash');
  }
}

class _ShellDefinition {
  const _ShellDefinition(
    this.executable,
    this.arguments,
    this.kind,
    this.title,
  );

  final String executable;
  final List<String> arguments;
  final TerminalKind kind;
  final String title;
}
