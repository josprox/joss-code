import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/editor/editor_models.dart';
import '../../domain/intelligence/intelligence_models.dart';
import '../editor/editor_controller.dart';

final intelligenceReportProvider = Provider<IntelligenceReport?>((ref) {
  final document = ref.watch(editorControllerProvider).activeDocument;
  if (document == null) {
    return null;
  }
  return LocalCodeIntelligence().analyze(document);
});

class LocalCodeIntelligence {
  IntelligenceReport analyze(EditorDocument document) {
    final lines = document.content.split('\n');
    final nonEmpty = lines.where((line) => line.trim().isNotEmpty).length;
    final classes = _matches(
      document.content,
      _classPattern(document.language),
    );
    final functions = _matches(
      document.content,
      _functionPattern(document.language),
    );
    final imports = _matches(
      document.content,
      _importPattern(document.language),
    );
    final insights = <IntelligenceInsight>[
      ..._todoInsights(lines),
      ..._delimiterInsights(document.content),
      ..._sizeInsights(lines.length),
      ..._languageInsights(document.language, document.content),
    ];

    final complexity = _complexityScore(document.content, lines.length);
    if (complexity > 18) {
      insights.add(
        const IntelligenceInsight(
          title: 'High local complexity',
          detail:
              'This file has several branches. Consider extracting smaller functions.',
          severity: IntelligenceSeverity.suggestion,
        ),
      );
    }

    return IntelligenceReport(
      language: document.language.displayName,
      lineCount: lines.length,
      nonEmptyLineCount: nonEmpty,
      symbols: CodeSymbolSummary(
        classes: classes.take(12).toList(),
        functions: functions.take(16).toList(),
        imports: imports.take(12).toList(),
      ),
      insights: insights.take(24).toList(),
      complexityScore: complexity,
    );
  }

  Iterable<IntelligenceInsight> _todoInsights(List<String> lines) sync* {
    for (var index = 0; index < lines.length; index++) {
      final line = lines[index];
      if (RegExp(
        r'\b(TODO|FIXME|HACK)\b',
        caseSensitive: false,
      ).hasMatch(line)) {
        yield IntelligenceInsight(
          title: 'Follow-up marker',
          detail: 'Line ${index + 1}: ${line.trim()}',
          severity: IntelligenceSeverity.info,
        );
      }
    }
  }

  Iterable<IntelligenceInsight> _delimiterInsights(String content) sync* {
    final pairs = {'{': '}', '[': ']', '(': ')'};
    for (final entry in pairs.entries) {
      final open = entry.key.allMatches(content).length;
      final close = entry.value.allMatches(content).length;
      if (open != close) {
        yield IntelligenceInsight(
          title: 'Possible delimiter mismatch',
          detail: 'Found $open "${entry.key}" and $close "${entry.value}".',
          severity: IntelligenceSeverity.warning,
        );
      }
    }
  }

  Iterable<IntelligenceInsight> _sizeInsights(int lineCount) sync* {
    if (lineCount > 500) {
      yield const IntelligenceInsight(
        title: 'Large file',
        detail:
            'This file is getting large. Split responsibilities before it becomes hard to navigate.',
        severity: IntelligenceSeverity.suggestion,
      );
    }
  }

  Iterable<IntelligenceInsight> _languageInsights(
    EditorLanguage language,
    String content,
  ) sync* {
    if (language == EditorLanguage.dart && !content.contains('const ')) {
      yield const IntelligenceInsight(
        title: 'Dart const opportunities',
        detail:
            'No const usage detected. Stateless widget trees may benefit from const constructors.',
        severity: IntelligenceSeverity.suggestion,
      );
    }
    if ((language == EditorLanguage.javascript ||
            language == EditorLanguage.typescript) &&
        content.contains('var ')) {
      yield const IntelligenceInsight(
        title: 'Prefer block scoped bindings',
        detail: 'Use const or let instead of var where possible.',
        severity: IntelligenceSeverity.suggestion,
      );
    }
  }

  int _complexityScore(String content, int lineCount) {
    final branchCount = RegExp(
      r'\b(if|for|while|switch|case|catch|&&|\|\|)\b',
    ).allMatches(content).length;
    return branchCount + (lineCount ~/ 120);
  }

  List<String> _matches(String content, RegExp pattern) {
    return pattern
        .allMatches(content)
        .map(_firstCapturedGroup)
        .where((value) => value.trim().isNotEmpty)
        .toSet()
        .toList()
      ..sort();
  }

  String _firstCapturedGroup(RegExpMatch match) {
    for (var index = 1; index <= match.groupCount; index++) {
      final value = match.group(index);
      if (value != null && value.trim().isNotEmpty) {
        return value.trim();
      }
    }
    return match.group(0)?.trim() ?? '';
  }

  RegExp _classPattern(EditorLanguage language) {
    return switch (language) {
      EditorLanguage.python => RegExp(
        r'^\s*class\s+([A-Za-z_]\w*)',
        multiLine: true,
      ),
      _ => RegExp(r'\bclass\s+([A-Za-z_]\w*)', multiLine: true),
    };
  }

  RegExp _functionPattern(EditorLanguage language) {
    return switch (language) {
      EditorLanguage.python => RegExp(
        r'^\s*def\s+([A-Za-z_]\w*)',
        multiLine: true,
      ),
      EditorLanguage.javascript || EditorLanguage.typescript => RegExp(
        r'\b(?:function\s+([A-Za-z_]\w*)|const\s+([A-Za-z_]\w*)\s*=\s*(?:async\s*)?\()',
        multiLine: true,
      ),
      EditorLanguage.csharp => RegExp(
        r'\b(?:public|private|protected|internal|static|async|\s)+\s+[A-Za-z_<>,\[\]]+\s+([A-Za-z_]\w*)\s*\(',
        multiLine: true,
      ),
      _ => RegExp(
        r'\b([A-Za-z_]\w*)\s*\([^;]*\)\s*(?:async\s*)?\{',
        multiLine: true,
      ),
    };
  }

  RegExp _importPattern(EditorLanguage language) {
    return switch (language) {
      EditorLanguage.python => RegExp(
        r'^\s*(?:from\s+[\w.]+\s+import\s+.+|import\s+.+)$',
        multiLine: true,
      ),
      EditorLanguage.csharp => RegExp(r'^\s*using\s+([^;]+);', multiLine: true),
      _ => RegExp(r'^\s*import\s+(.+);?', multiLine: true),
    };
  }
}
