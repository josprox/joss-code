import 'package:flutter_test/flutter_test.dart';
import 'package:joss_code/src/domain/settings/app_settings.dart';

void main() {
  test('round trips settings JSON', () {
    final settings = AppSettings(
      themeModeSetting: EditorThemeMode.light,
      fontFamily: 'Cascadia Mono',
      fontSize: 16,
      tabSize: 4,
      wordWrap: true,
      autoSave: true,
      lspServers: const {'dart': 'dart language-server --protocol=lsp'},
      enabledExtensions: const {'joss.hello-joss'},
      trustedWorkspaces: const {r'C:\workspace'},
    );

    final decoded = AppSettings.fromJson(settings.toJson());

    expect(decoded.themeModeSetting, EditorThemeMode.light);
    expect(decoded.fontSize, 16);
    expect(decoded.tabSize, 4);
    expect(decoded.wordWrap, isTrue);
    expect(decoded.enabledExtensions, contains('joss.hello-joss'));
    expect(decoded.trustedWorkspaces, contains(r'C:\workspace'));
  });
}
