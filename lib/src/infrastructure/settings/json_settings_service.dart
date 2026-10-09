import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../core/logging/app_logger.dart';
import '../../domain/settings/app_settings.dart';

class JsonSettingsService {
  JsonSettingsService(this._logger);

  static const workspaceSettingsDirectory = '.joss-code';
  static const settingsFileName = 'settings.json';

  final AppLogger _logger;

  Future<AppSettings> loadGlobal() async {
    final file = await _globalSettingsFile();
    if (!await file.exists()) {
      return const AppSettings();
    }
    try {
      final json =
          jsonDecode(await file.readAsString()) as Map<String, Object?>;
      return AppSettings.fromJson(json);
    } on Object catch (error) {
      _logger.error('Failed to read global settings', error);
      return const AppSettings();
    }
  }

  Future<void> saveGlobal(AppSettings settings) async {
    final file = await _globalSettingsFile();
    await file.parent.create(recursive: true);
    await file.writeAsString(_prettyJson(settings.toJson()));
  }

  Future<AppSettings?> loadWorkspace(String workspacePath) async {
    final file = File(
      p.join(workspacePath, workspaceSettingsDirectory, settingsFileName),
    );
    if (!await file.exists()) {
      return null;
    }
    try {
      final json =
          jsonDecode(await file.readAsString()) as Map<String, Object?>;
      return AppSettings.fromJson(json);
    } on Object catch (error) {
      _logger.error('Failed to read workspace settings', error);
      return null;
    }
  }

  Future<void> saveWorkspace(String workspacePath, AppSettings settings) async {
    final file = File(
      p.join(workspacePath, workspaceSettingsDirectory, settingsFileName),
    );
    await file.parent.create(recursive: true);
    await file.writeAsString(_prettyJson(settings.toJson()));
  }

  Future<File> _globalSettingsFile() async {
    final support = await getApplicationSupportDirectory();
    return File(p.join(support.path, 'JossCode', settingsFileName));
  }

  String _prettyJson(Map<String, Object?> json) {
    return const JsonEncoder.withIndent('  ').convert(json);
  }
}
