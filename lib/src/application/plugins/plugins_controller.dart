import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/di/service_providers.dart';
import '../../domain/plugins/plugin_models.dart';

final pluginsControllerProvider =
    NotifierProvider<PluginsController, PluginStateModel>(
      PluginsController.new,
    );

class PluginsController extends Notifier<PluginStateModel> {
  @override
  PluginStateModel build() => const PluginStateModel();

  Future<void> scan() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final installed = await ref.read(pluginServiceProvider).scanInstalled();
      state = state.copyWith(installed: installed, isLoading: false);
    } on Object catch (error) {
      state = state.copyWith(error: error.toString(), isLoading: false);
    }
  }

  Future<void> installVsix(String path) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final plugin = await ref.read(pluginServiceProvider).installVsix(path);
      state = state.copyWith(
        installed: [
          plugin,
          ...state.installed.where((item) => item.id != plugin.id),
        ],
        isLoading: false,
      );
    } on Object catch (error) {
      state = state.copyWith(error: error.toString(), isLoading: false);
    }
  }

  void setEnabled(String id, bool enabled) {
    state = state.copyWith(
      installed: [
        for (final plugin in state.installed)
          plugin.id == id ? plugin.copyWith(isEnabled: enabled) : plugin,
      ],
    );
  }
}
