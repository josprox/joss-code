import 'package:flutter/material.dart';

enum EditorThemeMode { system, dark, light, highContrast }

class AppSettings {
  const AppSettings({
    this.themeModeSetting = EditorThemeMode.dark,
    this.fontFamily = 'Cascadia Mono',
    this.fontSize = 14,
    this.tabSize = 2,
    this.wordWrap = false,
    this.autoSave = false,
    this.defaultTerminal,
    this.lspServers = const {},
    this.enabledExtensions = const {},
    this.keybindings = const {},
    this.trustedWorkspaces = const {},
    this.recentWorkspaces = const [],
    this.colorOverrides = const {},
  });

  final EditorThemeMode themeModeSetting;
  final String fontFamily;
  final double fontSize;
  final int tabSize;
  final bool wordWrap;
  final bool autoSave;
  final String? defaultTerminal;
  final Map<String, String> lspServers;
  final Set<String> enabledExtensions;
  final Map<String, String> keybindings;
  final Set<String> trustedWorkspaces;
  final List<String> recentWorkspaces;
  final Map<String, String> colorOverrides;

  ThemeMode get themeMode {
    return switch (themeModeSetting) {
      EditorThemeMode.system => ThemeMode.system,
      EditorThemeMode.light => ThemeMode.light,
      EditorThemeMode.dark => ThemeMode.dark,
      EditorThemeMode.highContrast => ThemeMode.dark,
    };
  }

  bool isTrusted(String workspacePath) =>
      trustedWorkspaces.contains(workspacePath);

  AppSettings copyWith({
    EditorThemeMode? themeModeSetting,
    String? fontFamily,
    double? fontSize,
    int? tabSize,
    bool? wordWrap,
    bool? autoSave,
    String? defaultTerminal,
    Map<String, String>? lspServers,
    Set<String>? enabledExtensions,
    Map<String, String>? keybindings,
    Set<String>? trustedWorkspaces,
    List<String>? recentWorkspaces,
    Map<String, String>? colorOverrides,
    bool clearDefaultTerminal = false,
  }) {
    return AppSettings(
      themeModeSetting: themeModeSetting ?? this.themeModeSetting,
      fontFamily: fontFamily ?? this.fontFamily,
      fontSize: fontSize ?? this.fontSize,
      tabSize: tabSize ?? this.tabSize,
      wordWrap: wordWrap ?? this.wordWrap,
      autoSave: autoSave ?? this.autoSave,
      defaultTerminal: clearDefaultTerminal
          ? null
          : defaultTerminal ?? this.defaultTerminal,
      lspServers: lspServers ?? this.lspServers,
      enabledExtensions: enabledExtensions ?? this.enabledExtensions,
      keybindings: keybindings ?? this.keybindings,
      trustedWorkspaces: trustedWorkspaces ?? this.trustedWorkspaces,
      recentWorkspaces: recentWorkspaces ?? this.recentWorkspaces,
      colorOverrides: colorOverrides ?? this.colorOverrides,
    );
  }

  Map<String, Object?> toJson() {
    return {
      'theme': themeModeSetting.name,
      'fontFamily': fontFamily,
      'fontSize': fontSize,
      'tabSize': tabSize,
      'wordWrap': wordWrap,
      'autoSave': autoSave,
      'defaultTerminal': defaultTerminal,
      'lspServers': lspServers,
      'enabledExtensions': enabledExtensions.toList()..sort(),
      'keybindings': keybindings,
      'trustedWorkspaces': trustedWorkspaces.toList()..sort(),
      'recentWorkspaces': recentWorkspaces,
      'colorOverrides': colorOverrides,
    };
  }

  factory AppSettings.fromJson(Map<String, Object?> json) {
    final themeName = json['theme'] as String? ?? EditorThemeMode.dark.name;
    return AppSettings(
      themeModeSetting: EditorThemeMode.values.firstWhere(
        (value) => value.name == themeName,
        orElse: () => EditorThemeMode.dark,
      ),
      fontFamily: json['fontFamily'] as String? ?? 'Cascadia Mono',
      fontSize: (json['fontSize'] as num?)?.toDouble() ?? 14,
      tabSize: (json['tabSize'] as num?)?.toInt() ?? 2,
      wordWrap: json['wordWrap'] as bool? ?? false,
      autoSave: json['autoSave'] as bool? ?? false,
      defaultTerminal: json['defaultTerminal'] as String?,
      lspServers: _stringMap(json['lspServers']),
      enabledExtensions: _stringSet(json['enabledExtensions']),
      keybindings: _stringMap(json['keybindings']),
      trustedWorkspaces: _stringSet(json['trustedWorkspaces']),
      recentWorkspaces: _stringList(json['recentWorkspaces']),
      colorOverrides: _stringMap(json['colorOverrides']),
    );
  }
}

Map<String, String> _stringMap(Object? value) {
  if (value is! Map) {
    return {};
  }
  return value.map(
    (key, value) => MapEntry(key.toString(), value?.toString() ?? ''),
  );
}

Set<String> _stringSet(Object? value) => _stringList(value).toSet();

List<String> _stringList(Object? value) {
  if (value is! Iterable) {
    return const [];
  }
  return value.map((entry) => entry.toString()).toList();
}
