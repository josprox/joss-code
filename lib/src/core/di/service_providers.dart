import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../infrastructure/filesystem/local_file_system_service.dart';
import '../../infrastructure/git/git_cli_service.dart';
import '../../infrastructure/lsp/lsp_client.dart';
import '../../infrastructure/plugins/vsix_extension_service.dart';
import '../../infrastructure/search/workspace_search_service.dart';
import '../../infrastructure/settings/json_settings_service.dart';
import '../../infrastructure/terminal/process_terminal_service.dart';
import '../commands/command_registry.dart';
import '../events/event_bus.dart';
import '../logging/app_logger.dart';
import '../security/path_guard.dart';

final loggerProvider = Provider<AppLogger>((ref) => AppLogger());

final eventBusProvider = Provider<AppEventBus>((ref) {
  final bus = AppEventBus();
  ref.onDispose(bus.dispose);
  return bus;
});

final pathGuardProvider = Provider<PathGuard>((ref) => const PathGuard());

final commandRegistryProvider = Provider<CommandRegistry>((ref) {
  return CommandRegistry(
    ref.watch(eventBusProvider),
    ref.watch(loggerProvider),
  );
});

final fileSystemServiceProvider = Provider<LocalFileSystemService>((ref) {
  return LocalFileSystemService(
    ref.watch(pathGuardProvider),
    ref.watch(loggerProvider),
  );
});

final settingsServiceProvider = Provider<JsonSettingsService>((ref) {
  return JsonSettingsService(ref.watch(loggerProvider));
});

final searchServiceProvider = Provider<WorkspaceSearchService>((ref) {
  return WorkspaceSearchService();
});

final pluginServiceProvider = Provider<VsixExtensionService>((ref) {
  return VsixExtensionService(
    ref.watch(pathGuardProvider),
    ref.watch(loggerProvider),
  );
});

final terminalServiceProvider = Provider<ProcessTerminalService>((ref) {
  return ProcessTerminalService(ref.watch(loggerProvider));
});

final gitServiceProvider = Provider<GitCliService>((ref) {
  return GitCliService(ref.watch(loggerProvider));
});

final lspClientProvider = Provider<GenericLspClient>((ref) {
  final client = GenericLspClient(ref.watch(loggerProvider));
  ref.onDispose(client.dispose);
  return client;
});
