import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../application/workbench/workbench_controller.dart';
import '../../../application/workspace/workspace_controller.dart';
import '../../../domain/workspace/workspace_models.dart';
import '../../theme/app_theme.dart';

class ActivityBar extends ConsumerWidget {
  const ActivityBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final workspace = ref.watch(workspaceControllerProvider);
    final workbench = ref.watch(workbenchControllerProvider);
    final colors = context.workbenchColors;
    return Container(
      width: 72,
      decoration: BoxDecoration(
        color: colors.activityBar,
        border: Border(right: BorderSide(color: colors.border)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 10),
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: colors.accent,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.code_rounded,
              color:
                  ThemeData.estimateBrightnessForColor(colors.accent) ==
                      Brightness.dark
                  ? Colors.white
                  : Colors.black,
            ),
          ),
          const SizedBox(height: 14),
          _ActivityButton(
            icon: Icons.folder_outlined,
            tooltip: 'Explorer',
            selected:
                workspace.activePanel == WorkspacePanel.explorer &&
                workbench.isSidebarVisible,
            onPressed: () => _select(ref, WorkspacePanel.explorer),
          ),
          _ActivityButton(
            icon: Icons.search,
            tooltip: 'Search',
            selected:
                workspace.activePanel == WorkspacePanel.search &&
                workbench.isSidebarVisible,
            onPressed: () => _select(ref, WorkspacePanel.search),
          ),
          _ActivityButton(
            icon: Icons.account_tree_outlined,
            tooltip: 'Source Control',
            selected:
                workspace.activePanel == WorkspacePanel.sourceControl &&
                workbench.isSidebarVisible,
            onPressed: () => _select(ref, WorkspacePanel.sourceControl),
          ),
          _ActivityButton(
            icon: Icons.extension_outlined,
            tooltip: 'Extensions',
            selected:
                workspace.activePanel == WorkspacePanel.extensions &&
                workbench.isSidebarVisible,
            onPressed: () => _select(ref, WorkspacePanel.extensions),
          ),
          const Spacer(),
          _ActivityButton(
            icon: Icons.settings_outlined,
            tooltip: 'Settings',
            selected:
                workspace.activePanel == WorkspacePanel.settings &&
                workbench.isSidebarVisible,
            onPressed: () => _select(ref, WorkspacePanel.settings),
          ),
          const SizedBox(height: 6),
        ],
      ),
    );
  }

  void _select(WidgetRef ref, WorkspacePanel panel) {
    ref.read(workspaceControllerProvider.notifier).setActivePanel(panel);
    final workbench = ref.read(workbenchControllerProvider);
    if (!workbench.isSidebarVisible) {
      ref.read(workbenchControllerProvider.notifier).toggleSidebar();
    }
  }
}

class _ActivityButton extends StatelessWidget {
  const _ActivityButton({
    required this.icon,
    required this.tooltip,
    required this.selected,
    required this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final bool selected;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = context.workbenchColors;
    final foreground = selected
        ? Theme.of(context).colorScheme.onSecondaryContainer
        : Theme.of(context).colorScheme.onSurfaceVariant;
    return Tooltip(
      message: tooltip,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: onPressed,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            width: 52,
            height: 44,
            decoration: BoxDecoration(
              color: selected
                  ? Theme.of(context).colorScheme.secondaryContainer
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
              border: selected
                  ? Border.all(color: colors.accent.withValues(alpha: 0.45))
                  : null,
            ),
            child: Icon(icon, color: foreground, size: selected ? 24 : 22),
          ),
        ),
      ),
    );
  }
}
