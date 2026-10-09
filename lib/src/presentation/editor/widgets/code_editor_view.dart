import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_code_editor/flutter_code_editor.dart';
import 'package:flutter_highlight/themes/vs2015.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:highlight/highlight.dart' show Mode;
import 'package:highlight/languages/cs.dart' as highlight_cs;
import 'package:highlight/languages/css.dart' as highlight_css;
import 'package:highlight/languages/dart.dart' as highlight_dart;
import 'package:highlight/languages/javascript.dart' as highlight_js;
import 'package:highlight/languages/json.dart' as highlight_json;
import 'package:highlight/languages/markdown.dart' as highlight_markdown;
import 'package:highlight/languages/python.dart' as highlight_python;
import 'package:highlight/languages/typescript.dart' as highlight_ts;
import 'package:highlight/languages/xml.dart' as highlight_xml;
import 'package:highlight/languages/yaml.dart' as highlight_yaml;

import '../../../application/editor/editor_controller.dart';
import '../../../application/settings/settings_controller.dart';
import '../../../domain/editor/editor_models.dart';
import '../../theme/app_theme.dart';

class CodeEditorView extends ConsumerStatefulWidget {
  const CodeEditorView({required this.document, super.key});

  final EditorDocument document;

  @override
  ConsumerState<CodeEditorView> createState() => _CodeEditorViewState();
}

class _CodeEditorViewState extends ConsumerState<CodeEditorView> {
  late CodeController _controller;
  final FocusNode _focusNode = FocusNode();
  bool _syncingFromState = false;

  @override
  void initState() {
    super.initState();
    _controller = _createController(widget.document);
  }

  @override
  void didUpdateWidget(covariant CodeEditorView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.document.id != widget.document.id) {
      _controller.dispose();
      _controller = _createController(widget.document);
      return;
    }
    _controller.language = _languageMode(widget.document.language);
    if (widget.document.content != _controller.text) {
      final selection = _controller.selection;
      _syncingFromState = true;
      _controller.text = widget.document.content;
      _controller.selection = selection.copyWith(
        baseOffset: math.min(selection.baseOffset, _controller.text.length),
        extentOffset: math.min(selection.extentOffset, _controller.text.length),
      );
      _syncingFromState = false;
    }
  }

  @override
  void dispose() {
    _focusNode.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsControllerProvider);
    final editor = ref.watch(editorControllerProvider);
    final fontSize = settings.fontSize + editor.fontZoom;

    return Column(
      children: [
        if (widget.document.isLargeFile || widget.document.error != null)
          _EditorBanner(document: widget.document),
        if (editor.showFind) const _FindReplaceBar(),
        Expanded(
          child: Shortcuts(
            shortcuts: const {
              SingleActivator(LogicalKeyboardKey.enter): _EnterIntent(),
              SingleActivator(LogicalKeyboardKey.numpadEnter): _EnterIntent(),
            },
            child: Actions(
              actions: {
                _EnterIntent: CallbackAction<_EnterIntent>(
                  onInvoke: (_) {
                    _insertSmartNewline(settings.tabSize);
                    return null;
                  },
                ),
              },
              child: CodeTheme(
                data: CodeThemeData(styles: vs2015Theme),
                child: CodeField(
                  controller: _controller,
                  focusNode: _focusNode,
                  expands: true,
                  wrap: settings.wordWrap,
                  cursorColor: context.workbenchColors.accent,
                  background: context.workbenchColors.editor,
                  padding: const EdgeInsets.fromLTRB(8, 12, 24, 24),
                  textStyle: TextStyle(
                    fontFamily: settings.fontFamily,
                    fontSize: fontSize,
                    height: 1.45,
                  ),
                  gutterStyle: GutterStyle(
                    textStyle: TextStyle(
                      fontFamily: settings.fontFamily,
                      fontSize: fontSize,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    background: context.workbenchColors.editor,
                    width: 56,
                    margin: 10,
                  ),
                  onChanged: (value) {
                    if (_syncingFromState) {
                      return;
                    }
                    ref
                        .read(editorControllerProvider.notifier)
                        .updateActiveContent(value);
                  },
                ),
              ),
            ),
          ),
        ),
        _SuggestionStrip(
          language: widget.document.language,
          controller: _controller,
        ),
      ],
    );
  }

  CodeController _createController(EditorDocument document) {
    return CodeController(
      text: document.content,
      language: _languageMode(document.language),
    );
  }

  void _insertSmartNewline(int tabSize) {
    final selection = _controller.selection;
    if (!selection.isValid) {
      _insertText('\n');
      return;
    }
    final text = _controller.text;
    final start = selection.start;
    final end = selection.end;
    final lineStart = text.lastIndexOf('\n', math.max(0, start - 1)) + 1;
    final currentLine = text.substring(lineStart, start);
    final baseIndent = RegExp(r'^\s*').firstMatch(currentLine)?.group(0) ?? '';
    final trimmedRight = currentLine.trimRight();
    final nextChar = start < text.length ? text[start] : '';
    final shouldIndent = _shouldIndentAfter(trimmedRight);
    final indent = shouldIndent ? ' ' * tabSize : '';

    late final String insert;
    late final int offset;
    if (_isBetweenPair(trimmedRight, nextChar) && shouldIndent) {
      insert = '\n$baseIndent$indent\n$baseIndent';
      offset = start + 1 + baseIndent.length + indent.length;
    } else {
      insert = '\n$baseIndent$indent';
      offset = start + insert.length;
    }

    final next = text.replaceRange(start, end, insert);
    _controller.value = TextEditingValue(
      text: next,
      selection: TextSelection.collapsed(offset: offset),
    );
    ref.read(editorControllerProvider.notifier).updateActiveContent(next);
  }

  void _insertText(String text) {
    final selection = _controller.selection;
    final next = _controller.text.replaceRange(
      selection.start,
      selection.end,
      text,
    );
    final offset = selection.start + text.length;
    _controller.value = TextEditingValue(
      text: next,
      selection: TextSelection.collapsed(offset: offset),
    );
    ref.read(editorControllerProvider.notifier).updateActiveContent(next);
  }

  bool _shouldIndentAfter(String line) {
    if (line.endsWith('{') || line.endsWith('[') || line.endsWith('(')) {
      return true;
    }
    return widget.document.language == EditorLanguage.python &&
        line.endsWith(':');
  }

  bool _isBetweenPair(String line, String nextChar) {
    return (line.endsWith('{') && nextChar == '}') ||
        (line.endsWith('[') && nextChar == ']') ||
        (line.endsWith('(') && nextChar == ')');
  }
}

class _FindReplaceBar extends ConsumerWidget {
  const _FindReplaceBar();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final editor = ref.watch(editorControllerProvider);
    return Container(
      decoration: BoxDecoration(
        color: context.workbenchColors.panel,
        border: Border(
          bottom: BorderSide(color: context.workbenchColors.border),
        ),
      ),
      padding: const EdgeInsets.all(8),
      child: Row(
        children: [
          SizedBox(
            width: 220,
            child: TextField(
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search),
                hintText: 'Find',
              ),
              onChanged: ref
                  .read(editorControllerProvider.notifier)
                  .setSearchQuery,
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 220,
            child: TextField(
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.find_replace),
                hintText: 'Replace',
              ),
              onChanged: ref
                  .read(editorControllerProvider.notifier)
                  .setReplaceQuery,
            ),
          ),
          const SizedBox(width: 8),
          FilledButton.icon(
            onPressed: editor.searchQuery.isEmpty
                ? null
                : ref
                      .read(editorControllerProvider.notifier)
                      .replaceAllInActive,
            icon: const Icon(Icons.swap_horiz),
            label: const Text('Replace All'),
          ),
          const Spacer(),
          IconButton(
            tooltip: 'Close',
            onPressed: () => ref
                .read(editorControllerProvider.notifier)
                .setFindVisible(false),
            icon: const Icon(Icons.close),
          ),
        ],
      ),
    );
  }
}

class _EditorBanner extends StatelessWidget {
  const _EditorBanner({required this.document});

  final EditorDocument document;

  @override
  Widget build(BuildContext context) {
    final message =
        document.error ??
        'Large file preview: only the first chunk was loaded.';
    return Container(
      width: double.infinity,
      color: context.workbenchColors.warning.withValues(alpha: 0.16),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      child: Text(message, style: const TextStyle(fontSize: 12)),
    );
  }
}

class _SuggestionStrip extends ConsumerWidget {
  const _SuggestionStrip({required this.language, required this.controller});

  final EditorLanguage language;
  final CodeController controller;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final suggestions = _keywords(language).take(8).toList();
    if (suggestions.isEmpty) {
      return const SizedBox.shrink();
    }
    return Container(
      height: 36,
      decoration: BoxDecoration(
        color: context.workbenchColors.panel,
        border: Border(top: BorderSide(color: context.workbenchColors.border)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: suggestions.length,
        separatorBuilder: (_, _) => const SizedBox(width: 6),
        itemBuilder: (context, index) {
          final suggestion = suggestions[index];
          return ActionChip(
            visualDensity: VisualDensity.compact,
            label: Text(suggestion),
            onPressed: () {
              final selection = controller.selection;
              final next = controller.text.replaceRange(
                selection.start,
                selection.end,
                suggestion,
              );
              controller.value = TextEditingValue(
                text: next,
                selection: TextSelection.collapsed(
                  offset: selection.start + suggestion.length,
                ),
              );
              ref
                  .read(editorControllerProvider.notifier)
                  .updateActiveContent(next);
            },
          );
        },
      ),
    );
  }

  List<String> _keywords(EditorLanguage language) {
    return switch (language) {
      EditorLanguage.dart => const [
        'class',
        'final',
        'const',
        'Future',
        'async',
        'await',
        'return',
        'Widget',
      ],
      EditorLanguage.javascript || EditorLanguage.typescript => const [
        'const',
        'let',
        'function',
        'async',
        'await',
        'return',
        'import',
        'export',
      ],
      EditorLanguage.python => const [
        'def',
        'class',
        'import',
        'from',
        'return',
        'async',
        'await',
        'self',
      ],
      EditorLanguage.csharp => const [
        'public',
        'private',
        'class',
        'async',
        'await',
        'return',
        'var',
        'string',
      ],
      _ => const [],
    };
  }
}

Mode? _languageMode(EditorLanguage language) {
  return switch (language) {
    EditorLanguage.dart => highlight_dart.dart,
    EditorLanguage.javascript => highlight_js.javascript,
    EditorLanguage.typescript => highlight_ts.typescript,
    EditorLanguage.python => highlight_python.python,
    EditorLanguage.csharp => highlight_cs.cs,
    EditorLanguage.html => highlight_xml.xml,
    EditorLanguage.css => highlight_css.css,
    EditorLanguage.json => highlight_json.json,
    EditorLanguage.markdown => highlight_markdown.markdown,
    EditorLanguage.yaml => highlight_yaml.yaml,
    _ => null,
  };
}

class _EnterIntent extends Intent {
  const _EnterIntent();
}
