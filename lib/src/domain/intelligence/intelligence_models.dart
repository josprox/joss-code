class IntelligenceInsight {
  const IntelligenceInsight({
    required this.title,
    required this.detail,
    required this.severity,
  });

  final String title;
  final String detail;
  final IntelligenceSeverity severity;
}

enum IntelligenceSeverity { info, suggestion, warning }

class CodeSymbolSummary {
  const CodeSymbolSummary({
    required this.classes,
    required this.functions,
    required this.imports,
  });

  final List<String> classes;
  final List<String> functions;
  final List<String> imports;
}

class IntelligenceReport {
  const IntelligenceReport({
    required this.language,
    required this.lineCount,
    required this.nonEmptyLineCount,
    required this.symbols,
    required this.insights,
    required this.complexityScore,
  });

  final String language;
  final int lineCount;
  final int nonEmptyLineCount;
  final CodeSymbolSummary symbols;
  final List<IntelligenceInsight> insights;
  final int complexityScore;

  bool get isEmpty => lineCount == 0 && insights.isEmpty;
}
