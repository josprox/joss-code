import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../application/editor/editor_controller.dart';
import '../../../application/git/git_controller.dart';
import '../../../application/workspace/workspace_controller.dart';
import '../../theme/app_theme.dart';

class StatusBar extends ConsumerWidget {
  const StatusBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final workspace = ref.watch(workspaceControllerProvider).workspace;
    final editor = ref.watch(editorControllerProvider).activeDocument;
    final git = ref.watch(gitControllerProvider);
    final colors = context.workbenchColors;
    return Container(
      height: 24,
      color: colors.statusBar,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: DefaultTextStyle(
        style: TextStyle(
          color:
              ThemeData.estimateBrightnessForColor(colors.statusBar) ==
                  Brightness.dark
              ? Colors.white
              : Colors.black,
          fontSize: 12,
        ),
        child: Row(
          children: [
            Icon(
              workspace?.isTrusted ?? false
                  ? Icons.shield
                  : Icons.shield_outlined,
              size: 14,
            ),
            const SizedBox(width: 6),
            Text(workspace == null ? 'No workspace' : workspace.name),
            const SizedBox(width: 18),
            if (git.branch != null) ...[
              const Icon(Icons.account_tree_outlined, size: 14),
              const SizedBox(width: 5),
              Text(git.branch!),
            ],
            const Spacer(),
            if (editor != null) ...[
              Text(editor.language.displayName),
              const SizedBox(width: 18),
              Text('${editor.lineCount} lines'),
              const SizedBox(width: 18),
              Text(editor.isDirty ? 'Modified' : 'Saved'),
            ],
          ],
        ),
      ),
    );
  }
}
