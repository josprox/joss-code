import 'package:flutter_test/flutter_test.dart';
import 'package:joss_code/src/application/intelligence/intelligence_controller.dart';
import 'package:joss_code/src/domain/editor/editor_models.dart';
import 'package:joss_code/src/domain/intelligence/intelligence_models.dart';

void main() {
  test('local intelligence extracts symbols and TODO insights', () {
    final report = LocalCodeIntelligence().analyze(
      EditorDocument(
        id: 'main.dart',
        path: 'main.dart',
        name: 'main.dart',
        language: EditorLanguage.dart,
        content: '''
import 'package:flutter/widgets.dart';

// TODO: polish this
class HomePage {
  Widget build() {
    if (true) {
      return const SizedBox();
    }
    return const SizedBox();
  }
}
''',
      ),
    );

    expect(report.symbols.classes, contains('HomePage'));
    expect(report.symbols.imports.first, contains('flutter/widgets.dart'));
    expect(
      report.insights.map((insight) => insight.severity),
      contains(IntelligenceSeverity.info),
    );
  });
}
