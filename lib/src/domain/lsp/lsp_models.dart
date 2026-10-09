import '../editor/editor_models.dart';

class LspServerDefinition {
  const LspServerDefinition({
    required this.language,
    required this.command,
    this.arguments = const [],
    this.initializationOptions = const {},
  });

  final EditorLanguage language;
  final String command;
  final List<String> arguments;
  final Map<String, Object?> initializationOptions;
}

class LspDiagnostic {
  const LspDiagnostic({
    required this.path,
    required this.message,
    required this.severity,
    required this.line,
    required this.character,
  });

  final String path;
  final String message;
  final int severity;
  final int line;
  final int character;
}

class LspCompletionItem {
  const LspCompletionItem({required this.label, this.detail, this.insertText});

  final String label;
  final String? detail;
  final String? insertText;
}

class LspStateModel {
  const LspStateModel({
    this.servers = const [],
    this.diagnostics = const [],
    this.isBusy = false,
    this.error,
  });

  final List<LspServerDefinition> servers;
  final List<LspDiagnostic> diagnostics;
  final bool isBusy;
  final String? error;

  LspStateModel copyWith({
    List<LspServerDefinition>? servers,
    List<LspDiagnostic>? diagnostics,
    bool? isBusy,
    String? error,
    bool clearError = false,
  }) {
    return LspStateModel(
      servers: servers ?? this.servers,
      diagnostics: diagnostics ?? this.diagnostics,
      isBusy: isBusy ?? this.isBusy,
      error: clearError ? null : error ?? this.error,
    );
  }
}
