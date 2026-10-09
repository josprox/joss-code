import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../core/logging/app_logger.dart';
import '../../core/security/path_guard.dart';
import '../../domain/plugins/plugin_models.dart';

class VsixExtensionService {
  VsixExtensionService(this._pathGuard, this._logger);

  final PathGuard _pathGuard;
  final AppLogger _logger;

  Future<Directory> extensionsDirectory() async {
    final support = await getApplicationSupportDirectory();
    final directory = Directory(p.join(support.path, 'JossCode', 'extensions'));
    await directory.create(recursive: true);
    return directory;
  }

  Future<List<InstalledPlugin>> scanInstalled() async {
    final root = await extensionsDirectory();
    final plugins = <InstalledPlugin>[];
    await for (final entity in root.list(followLinks: false)) {
      if (entity is! Directory) {
        continue;
      }
      final packageFile = File(
        p.join(entity.path, 'extension', 'package.json'),
      );
      final fallbackFile = File(p.join(entity.path, 'package.json'));
      final file = await packageFile.exists() ? packageFile : fallbackFile;
      if (!await file.exists()) {
        continue;
      }
      try {
        plugins.add(await _readPlugin(entity.path, file));
      } on Object catch (error) {
        _logger.error('Failed to read extension at ${entity.path}', error);
      }
    }
    plugins.sort((a, b) => a.displayName.compareTo(b.displayName));
    return plugins;
  }

  Future<InstalledPlugin> installVsix(String vsixPath) async {
    final bytes = await File(vsixPath).readAsBytes();
    final archive = ZipDecoder().decodeBytes(bytes);
    final packageEntry = archive.files.firstWhere(
      (file) => file.isFile && file.name.endsWith('extension/package.json'),
      orElse: () => throw const FormatException(
        'VSIX does not contain extension/package.json',
      ),
    );
    final packageJson =
        jsonDecode(utf8.decode(packageEntry.content)) as Map<String, Object?>;
    final publisher = packageJson['publisher']?.toString() ?? 'unknown';
    final name =
        packageJson['name']?.toString() ?? p.basenameWithoutExtension(vsixPath);
    final version = packageJson['version']?.toString() ?? '0.0.0';
    final root = await extensionsDirectory();
    final target = Directory(p.join(root.path, '$publisher.$name-$version'));
    if (await target.exists()) {
      await target.delete(recursive: true);
    }
    await target.create(recursive: true);

    for (final file in archive.files) {
      final relative = p.normalize(file.name);
      final outPath = p.join(target.path, relative);
      if (!_pathGuard.isWithin(outPath, target.path)) {
        _logger.security('Blocked path traversal while extracting $relative');
        continue;
      }
      if (file.isFile) {
        final outFile = File(outPath);
        await outFile.parent.create(recursive: true);
        await outFile.writeAsBytes(file.content);
      } else {
        await Directory(outPath).create(recursive: true);
      }
    }

    return _readPlugin(
      target.path,
      File(p.join(target.path, 'extension', 'package.json')),
    );
  }

  Future<InstalledPlugin> _readPlugin(
    String installPath,
    File packageFile,
  ) async {
    final json =
        jsonDecode(await packageFile.readAsString()) as Map<String, Object?>;
    final publisher = json['publisher']?.toString() ?? 'local';
    final name = json['name']?.toString() ?? p.basename(installPath);
    return InstalledPlugin(
      id: '$publisher.$name',
      name: name,
      displayName: json['displayName']?.toString() ?? name,
      version: json['version']?.toString() ?? '0.0.0',
      publisher: publisher,
      installPath: installPath,
      activationEvents: _stringList(json['activationEvents']),
      contribution: _parseContributions(json['contributes']),
      isEnabled: true,
      isTrusted: false,
    );
  }

  PluginContribution _parseContributions(Object? contributes) {
    final map = contributes is Map ? contributes : const {};
    return PluginContribution(
      commands: _mapList(map['commands'])
          .map(
            (item) => PluginCommandContribution(
              command: item['command']?.toString() ?? '',
              title: item['title']?.toString() ?? '',
              category: item['category']?.toString(),
            ),
          )
          .where((command) => command.command.isNotEmpty)
          .toList(),
      snippets: {
        for (final item in _mapList(map['snippets']))
          if (item['language'] != null && item['path'] != null)
            item['language'].toString(): item['path'].toString(),
      },
      themes: _mapList(map['themes'])
          .map(
            (item) => PluginThemeContribution(
              label: item['label']?.toString() ?? 'Theme',
              path: item['path']?.toString() ?? '',
              uiTheme: item['uiTheme']?.toString(),
            ),
          )
          .toList(),
      languages: _mapList(map['languages'])
          .map(
            (item) => PluginLanguageContribution(
              id: item['id']?.toString() ?? '',
              aliases: _stringList(item['aliases']),
              extensions: _stringList(item['extensions']),
            ),
          )
          .where((language) => language.id.isNotEmpty)
          .toList(),
      grammars: _mapList(map['grammars']),
      keybindings: _mapList(map['keybindings']),
      configuration: map['configuration'] is Map
          ? Map<String, Object?>.from(
              (map['configuration'] as Map).cast<String, Object?>(),
            )
          : const {},
    );
  }

  List<Map<String, Object?>> _mapList(Object? value) {
    if (value is! List) {
      return const [];
    }
    return value
        .whereType<Map>()
        .map((item) => Map<String, Object?>.from(item.cast<String, Object?>()))
        .toList();
  }

  List<String> _stringList(Object? value) {
    if (value is! Iterable) {
      return const [];
    }
    return value.map((entry) => entry.toString()).toList();
  }
}
