import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:multi_split_view/multi_split_view.dart';

import '../../application/commands/command_bootstrap.dart';
import '../../application/workbench/workbench_controller.dart';
import '../../core/commands/command.dart';
import '../../core/di/service_providers.dart';
import '../theme/app_theme.dart';
import 'widgets/activity_bar.dart';
import 'widgets/bottom_panel.dart';
import 'widgets/command_palette.dart';
import 'widgets/editor_area.dart';
import 'widgets/sidebar.dart';
import 'widgets/status_bar.dart';

class WorkbenchScreen extends ConsumerWidget {
  const WorkbenchScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(commandBootstrapProvider);
    final workbench = ref.watch(workbenchControllerProvider);
    final colors = context.workbenchColors;

    return Shortcuts(
      shortcuts: {
        const SingleActivator(
          LogicalKeyboardKey.keyP,
          control: true,
          shift: true,
        ): const _CommandIntent(
          'workbench.commandPalette',
        ),
        const SingleActivator(LogicalKeyboardKey.keyS, control: true):
            const _CommandIntent('editor.save'),
        const SingleActivator(LogicalKeyboardKey.keyF, control: true):
            const _CommandIntent('editor.find'),
        const SingleActivator(LogicalKeyboardKey.keyJ, control: true):
            const _CommandIntent('workbench.togglePanel'),
        const CharacterActivator('\u00f1', control: true): const _CommandIntent(
          'terminal.new',
        ),
        const CharacterActivator('\u00d1', control: true): const _CommandIntent(
          'terminal.new',
        ),
        const SingleActivator(LogicalKeyboardKey.semicolon, control: true):
            const _CommandIntent('terminal.new'),
        const SingleActivator(LogicalKeyboardKey.equal, control: true):
            const _CommandIntent('editor.zoomIn'),
        const SingleActivator(LogicalKeyboardKey.minus, control: true):
            const _CommandIntent('editor.zoomOut'),
      },
      child: Actions(
        actions: {
          _CommandIntent: CallbackAction<_CommandIntent>(
            onInvoke: (intent) async {
              if (intent.commandId == 'workbench.commandPalette') {
                ref
                    .read(workbenchControllerProvider.notifier)
                    .openCommandPalette();
              } else {
                await ref
                    .read(commandRegistryProvider)
                    .execute(
                      intent.commandId,
                      CommandContext(context: context),
                    );
              }
              return null;
            },
          ),
        },
        child: Focus(
          autofocus: true,
          child: Scaffold(
            body: LayoutBuilder(
              builder: (context, constraints) {
                final compact = constraints.maxWidth < 850;
                Future.microtask(
                  () => ref
                      .read(workbenchControllerProvider.notifier)
                      .setCompactMode(compact),
                );
                final sidebarVisible = workbench.isSidebarVisible && !compact;
                return Stack(
                  children: [
                    Column(
                      children: [
                        Expanded(
                          child: Row(
                            children: [
                              const ActivityBar(),
                              if (sidebarVisible)
                                SizedBox(
                                  width: constraints.maxWidth < 1100
                                      ? 292
                                      : 336,
                                  child: const Sidebar(),
                                ),
                              Expanded(
                                child: WorkbenchEditorStack(
                                  showBottomPanel:
                                      workbench.isBottomPanelVisible,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const StatusBar(),
                      ],
                    ),
                    if (compact && workbench.isSidebarVisible)
                      Positioned(
                        left: 72,
                        top: 0,
                        bottom: 24,
                        width: constraints.maxWidth.clamp(280, 360).toDouble(),
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: colors.sideBar,
                            border: Border(
                              right: BorderSide(color: colors.border),
                            ),
                          ),
                          child: const Sidebar(),
                        ),
                      ),
                    if (workbench.isCommandPaletteOpen) const CommandPalette(),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _CommandIntent extends Intent {
  const _CommandIntent(this.commandId);

  final String commandId;
}

class WorkbenchEditorStack extends StatefulWidget {
  const WorkbenchEditorStack({required this.showBottomPanel, super.key});

  final bool showBottomPanel;

  @override
  State<WorkbenchEditorStack> createState() => _WorkbenchEditorStackState();
}

class _WorkbenchEditorStackState extends State<WorkbenchEditorStack> {
  late final MultiSplitViewController _controller;

  @override
  void initState() {
    super.initState();
    _controller = MultiSplitViewController(
      areas: [
        Area(flex: 1, id: 'editor'),
        Area(size: 260, min: 140, max: 520, id: 'panel'),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.showBottomPanel) {
      return const EditorArea();
    }
    final colors = context.workbenchColors;
    return MultiSplitViewTheme(
      data: MultiSplitViewThemeData(
        dividerThickness: 7,
        dividerPainter: DividerPainters.grooved1(
          color: colors.border,
          highlightedColor: colors.accent,
        ),
      ),
      child: MultiSplitView(
        axis: Axis.vertical,
        controller: _controller,
        builder: (context, area) =>
            area.id == 'panel' ? const BottomPanel() : const EditorArea(),
      ),
    );
  }
}
