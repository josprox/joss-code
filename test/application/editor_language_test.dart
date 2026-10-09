import 'package:flutter_test/flutter_test.dart';
import 'package:joss_code/src/domain/editor/editor_models.dart';

void main() {
  test('detects common editor languages by extension', () {
    expect(EditorLanguage.fromPath('main.dart'), EditorLanguage.dart);
    expect(EditorLanguage.fromPath('app.tsx'), EditorLanguage.typescript);
    expect(EditorLanguage.fromPath('README.md'), EditorLanguage.markdown);
    expect(EditorLanguage.fromPath('Program.cs'), EditorLanguage.csharp);
    expect(EditorLanguage.fromPath('unknown.lock'), EditorLanguage.plainText);
  });
}
