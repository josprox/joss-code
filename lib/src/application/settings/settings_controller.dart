import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/di/service_providers.dart';
import '../../domain/settings/app_settings.dart';

final settingsControllerProvider =
    NotifierProvider<SettingsController, AppSettings>(SettingsController.new);

class SettingsController extends Notifier<AppSettings> {
  @override
  AppSettings build() => const AppSettings();

  Future<void> load() async {
    state = await ref.read(settingsServiceProvider).loadGlobal();
  }

  Future<void> save() async {
    await ref.read(settingsServiceProvider).saveGlobal(state);
  }

  Future<void> setTheme(EditorThemeMode mode) async {
    state = state.copyWith(themeModeSetting: mode);
    await save();
  }

  Future<void> setFontSize(double size) async {
    state = state.copyWith(fontSize: size.clamp(10, 32));
    await save();
  }

  Future<void> setWordWrap(bool enabled) async {
    state = state.copyWith(wordWrap: enabled);
    await save();
  }

  Future<void> setAutoSave(bool enabled) async {
    state = state.copyWith(autoSave: enabled);
    await save();
  }

  Future<void> setDefaultTerminal(String? terminal) async {
    state = state.copyWith(
      defaultTerminal: terminal,
      clearDefaultTerminal: terminal == null,
    );
    await save();
  }

  Future<void> rememberWorkspace(String path) async {
    final recent = [
      path,
      ...state.recentWorkspaces.where((item) => item != path),
    ].take(12).toList();
    state = state.copyWith(recentWorkspaces: recent);
    await save();
  }

  Future<void> trustWorkspace(String path) async {
    state = state.copyWith(
      trustedWorkspaces: {...state.trustedWorkspaces, path},
    );
    await save();
  }

  Future<void> registerLspServer(String languageId, String command) async {
    state = state.copyWith(
      lspServers: {...state.lspServers, languageId: command},
    );
    await save();
  }
}
