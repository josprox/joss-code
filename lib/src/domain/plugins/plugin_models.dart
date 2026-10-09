enum PluginActivationEvent {
  onStartupFinished,
  onLanguage,
  onCommand,
  workspaceContains,
}

class PluginContribution {
  const PluginContribution({
    this.commands = const [],
    this.snippets = const {},
    this.themes = const [],
    this.languages = const [],
    this.grammars = const [],
    this.keybindings = const [],
    this.configuration = const {},
  });

  final List<PluginCommandContribution> commands;
  final Map<String, String> snippets;
  final List<PluginThemeContribution> themes;
  final List<PluginLanguageContribution> languages;
  final List<Map<String, Object?>> grammars;
  final List<Map<String, Object?>> keybindings;
  final Map<String, Object?> configuration;
}

class PluginCommandContribution {
  const PluginCommandContribution({
    required this.command,
    required this.title,
    this.category,
  });

  final String command;
  final String title;
  final String? category;
}

class PluginThemeContribution {
  const PluginThemeContribution({
    required this.label,
    required this.path,
    this.uiTheme,
  });

  final String label;
  final String path;
  final String? uiTheme;
}

class PluginLanguageContribution {
  const PluginLanguageContribution({
    required this.id,
    required this.aliases,
    required this.extensions,
  });

  final String id;
  final List<String> aliases;
  final List<String> extensions;
}

class InstalledPlugin {
  const InstalledPlugin({
    required this.id,
    required this.name,
    required this.displayName,
    required this.version,
    required this.publisher,
    required this.installPath,
    required this.activationEvents,
    required this.contribution,
    this.isEnabled = true,
    this.isTrusted = false,
  });

  final String id;
  final String name;
  final String displayName;
  final String version;
  final String publisher;
  final String installPath;
  final List<String> activationEvents;
  final PluginContribution contribution;
  final bool isEnabled;
  final bool isTrusted;

  InstalledPlugin copyWith({bool? isEnabled, bool? isTrusted}) {
    return InstalledPlugin(
      id: id,
      name: name,
      displayName: displayName,
      version: version,
      publisher: publisher,
      installPath: installPath,
      activationEvents: activationEvents,
      contribution: contribution,
      isEnabled: isEnabled ?? this.isEnabled,
      isTrusted: isTrusted ?? this.isTrusted,
    );
  }
}

class PluginStateModel {
  const PluginStateModel({
    this.installed = const [],
    this.isLoading = false,
    this.error,
  });

  final List<InstalledPlugin> installed;
  final bool isLoading;
  final String? error;

  PluginStateModel copyWith({
    List<InstalledPlugin>? installed,
    bool? isLoading,
    String? error,
    bool clearError = false,
  }) {
    return PluginStateModel(
      installed: installed ?? this.installed,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : error ?? this.error,
    );
  }
}
