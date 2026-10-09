import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/commands/command.dart';
import '../../core/commands/command_registry.dart';
import '../../core/di/service_providers.dart';
import '../../domain/settings/app_settings.dart';
import '../editor/editor_controller.dart';
import '../git/git_controller.dart';
import '../lsp/lsp_controller.dart';
import '../plugins/plugins_controller.dart';
import '../settings/settings_controller.dart';
import '../terminal/terminal_controller.dart';
import '../workbench/workbench_controller.dart';
import '../workspace/workspace_controller.dart';

final commandBootstrapProvider = Provider<void>((ref) {
  final registry = ref.watch(commandRegistryProvider);
  registry.registerAll(_commands(ref, registry));
});

List<AppCommand> _commands(Ref ref, CommandRegistry registry) {
  return [
    AppCommand(
      id: 'workbench.openWorkspace',
      title: 'Open Workspace',
      category: 'Workspace',
      keybinding: 'Ctrl+K Ctrl+O',
      handler: (_) =>
          ref.read(workspaceControllerProvider.notifier).pickAndOpenWorkspace(),
    ),
    AppCommand(
      id: 'workbench.refreshExplorer',
      title: 'Refresh Explorer',
      category: 'Workspace',
      handler: (_) =>
          ref.read(workspaceControllerProvider.notifier).refreshTree(),
    ),
    AppCommand(
      id: 'workbench.trustWorkspace',
      title: 'Trust Workspace',
      category: 'Security',
      isSensitive: true,
      handler: (_) => ref
          .read(workspaceControllerProvider.notifier)
          .trustCurrentWorkspace(),
    ),
    AppCommand(
      id: 'workbench.toggleSidebar',
      title: 'Toggle Sidebar',
      category: 'View',
      handler: (_) async =>
          ref.read(workbenchControllerProvider.notifier).toggleSidebar(),
    ),
    AppCommand(
      id: 'workbench.togglePanel',
      title: 'Toggle Bottom Panel',
      category: 'View',
      keybinding: 'Ctrl+J',
      handler: (_) async =>
          ref.read(workbenchControllerProvider.notifier).toggleBottomPanel(),
    ),
    AppCommand(
      id: 'workbench.toggleTheme',
      title: 'Toggle Light/Dark Theme',
      category: 'Preferences',
      handler: (_) async {
        final settings = ref.read(settingsControllerProvider);
        final next = settings.themeModeSetting == EditorThemeMode.dark
            ? EditorThemeMode.light
            : EditorThemeMode.dark;
        await ref.read(settingsControllerProvider.notifier).setTheme(next);
      },
    ),
    AppCommand(
      id: 'editor.save',
      title: 'Save File',
      category: 'Editor',
      keybinding: 'Ctrl+S',
      handler: (_) => ref.read(editorControllerProvider.notifier).saveActive(),
    ),
    AppCommand(
      id: 'editor.find',
      title: 'Find in File',
      category: 'Editor',
      keybinding: 'Ctrl+F',
      handler: (_) async =>
          ref.read(editorControllerProvider.notifier).setFindVisible(true),
    ),
    AppCommand(
      id: 'editor.zoomIn',
      title: 'Zoom In',
      category: 'Editor',
      keybinding: 'Ctrl+=',
      handler: (_) async =>
          ref.read(editorControllerProvider.notifier).zoomIn(),
    ),
    AppCommand(
      id: 'editor.zoomOut',
      title: 'Zoom Out',
      category: 'Editor',
      keybinding: 'Ctrl+-',
      handler: (_) async =>
          ref.read(editorControllerProvider.notifier).zoomOut(),
    ),
    AppCommand(
      id: 'editor.splitVertical',
      title: 'Split Editor Vertical',
      category: 'Editor',
      handler: (_) async =>
          ref.read(editorControllerProvider.notifier).splitVertical(),
    ),
    AppCommand(
      id: 'editor.splitHorizontal',
      title: 'Split Editor Horizontal',
      category: 'Editor',
      handler: (_) async =>
          ref.read(editorControllerProvider.notifier).splitHorizontal(),
    ),
    AppCommand(
      id: 'editor.closeSplit',
      title: 'Close Split Editor',
      category: 'Editor',
      handler: (_) async =>
          ref.read(editorControllerProvider.notifier).closeSplit(),
    ),
    AppCommand(
      id: 'terminal.new',
      title: 'Create New Terminal',
      category: 'Terminal',
      keybinding: 'Ctrl+ñ',
      handler: (_) async {
        ref
            .read(workbenchControllerProvider.notifier)
            .showPanel(BottomPanelKind.terminal);
        await ref.read(terminalControllerProvider.notifier).createSession();
      },
    ),
    AppCommand(
      id: 'lsp.startActiveLanguage',
      title: 'Start Language Server for Active File',
      category: 'Language Server',
      handler: (_) async {
        final active = ref.read(editorControllerProvider).activeDocument;
        if (active != null) {
          await ref
              .read(lspControllerProvider.notifier)
              .startForLanguage(active.language);
        }
      },
    ),
    AppCommand(
      id: 'intelligence.inspectActiveFile',
      title: 'Inspect Active File',
      category: 'Intelligence',
      handler: (_) async {
        ref
            .read(workbenchControllerProvider.notifier)
            .showPanel(BottomPanelKind.intelligence);
      },
    ),
    AppCommand(
      id: 'git.refresh',
      title: 'Refresh Source Control',
      category: 'Git',
      handler: (_) => ref.read(gitControllerProvider.notifier).refresh(),
    ),
    AppCommand(
      id: 'git.pull',
      title: 'Git Pull',
      category: 'Git',
      isSensitive: true,
      handler: (_) => ref.read(gitControllerProvider.notifier).pull(),
    ),
    AppCommand(
      id: 'git.push',
      title: 'Git Push',
      category: 'Git',
      isSensitive: true,
      handler: (_) => ref.read(gitControllerProvider.notifier).push(),
    ),
    AppCommand(
      id: 'extensions.refresh',
      title: 'Refresh Extensions',
      category: 'Extensions',
      handler: (_) => ref.read(pluginsControllerProvider.notifier).scan(),
    ),
  ];
}
