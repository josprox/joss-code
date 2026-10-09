import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../application/editor/editor_controller.dart';
import '../../../application/settings/settings_controller.dart';
import '../../../domain/editor/editor_models.dart';
import '../../editor/widgets/code_editor_view.dart';
import '../../theme/app_theme.dart';

class EditorArea extends ConsumerWidget {
  const EditorArea({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final editor = ref.watch(editorControllerProvider);
    final colors = context.workbenchColors;
    return Container(
      decoration: BoxDecoration(
        color: colors.editor,
        border: Border(left: BorderSide(color: colors.border)),
      ),
      child: Column(
        children: [
          _TabsRow(
            documents: editor.openDocuments,
            activeId: editor.activeDocumentId,
          ),
          Expanded(child: _EditorBody(editor: editor)),
        ],
      ),
    );
  }
}

class _EditorBody extends StatelessWidget {
  const _EditorBody({required this.editor});

  final EditorStateModel editor;

  @override
  Widget build(BuildContext context) {
    final document = editor.activeDocument;
    if (document == null) {
      return const _NoEditorOpen();
    }
    if (editor.splitAxis == 'vertical') {
      return Row(
        children: [
          Expanded(
            child: CodeEditorView(
              key: ValueKey('${document.id}:left'),
              document: document,
            ),
          ),
          VerticalDivider(width: 1, color: context.workbenchColors.border),
          Expanded(
            child: CodeEditorView(
              key: ValueKey('${document.id}:right'),
              document: document,
            ),
          ),
        ],
      );
    }
    if (editor.splitAxis == 'horizontal') {
      return Column(
        children: [
          Expanded(
            child: CodeEditorView(
              key: ValueKey('${document.id}:top'),
              document: document,
            ),
          ),
          Divider(height: 1, color: context.workbenchColors.border),
          Expanded(
            child: CodeEditorView(
              key: ValueKey('${document.id}:bottom'),
              document: document,
            ),
          ),
        ],
      );
    }
    return CodeEditorView(document: document);
  }
}

class _TabsRow extends ConsumerWidget {
  const _TabsRow({required this.documents, required this.activeId});

  final List<EditorDocument> documents;
  final String? activeId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.workbenchColors;
    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: colors.tabInactive,
        border: Border(bottom: BorderSide(color: colors.border)),
      ),
      child: documents.isEmpty
          ? const SizedBox.shrink()
          : ListView(
              scrollDirection: Axis.horizontal,
              children: [
                for (final document in documents)
                  InkWell(
                    onTap: () => ref
                        .read(editorControllerProvider.notifier)
                        .activate(document.id),
                    child: Container(
                      constraints: const BoxConstraints(
                        minWidth: 156,
                        maxWidth: 260,
                      ),
                      margin: const EdgeInsets.fromLTRB(6, 6, 0, 5),
                      decoration: BoxDecoration(
                        color: document.id == activeId
                            ? colors.tabActive
                            : colors.tabInactive,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: document.id == activeId
                              ? colors.accent.withValues(alpha: 0.42)
                              : colors.border,
                        ),
                      ),
                      padding: const EdgeInsets.only(left: 12, right: 2),
                      child: Row(
                        children: [
                          Icon(_languageIcon(document.language), size: 16),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              '${document.isDirty ? '* ' : ''}${document.name}',
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: document.id == activeId
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                              ),
                            ),
                          ),
                          IconButton(
                            tooltip: 'Close',
                            iconSize: 15,
                            visualDensity: VisualDensity.compact,
                            onPressed: () => ref
                                .read(editorControllerProvider.notifier)
                                .close(document.id),
                            icon: const Icon(Icons.close),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
    );
  }

  IconData _languageIcon(EditorLanguage language) {
    return switch (language) {
      EditorLanguage.dart => Icons.flutter_dash,
      EditorLanguage.javascript || EditorLanguage.typescript => Icons.code,
      EditorLanguage.python => Icons.terminal,
      EditorLanguage.csharp => Icons.tag,
      EditorLanguage.html => Icons.html,
      EditorLanguage.css => Icons.css,
      EditorLanguage.json => Icons.data_object,
      EditorLanguage.markdown => Icons.article_outlined,
      _ => Icons.description_outlined,
    };
  }
}

class _NoEditorOpen extends ConsumerWidget {
  const _NoEditorOpen();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsControllerProvider);
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: context.workbenchColors.tabActive,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: context.workbenchColors.border),
              ),
              child: Icon(
                Icons.edit_note_rounded,
                size: 42,
                color: context.workbenchColors.accent,
              ),
            ),
            const SizedBox(height: 18),
            Text(
              'Joss Code',
              style: Theme.of(
                context,
              ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 10),
            Text(
              'Open a workspace and start shaping code with a focused Material 3 workbench. Font size: ${settings.fontSize.toStringAsFixed(0)}.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}
