import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/di/service_providers.dart';
import '../../domain/editor/editor_models.dart';
import '../../domain/lsp/lsp_models.dart';
import '../editor/editor_controller.dart';
import '../workspace/workspace_controller.dart';

final lspControllerProvider = NotifierProvider<LspController, LspStateModel>(
  LspController.new,
);

class LspController extends Notifier<LspStateModel> {
  StreamSubscription<List<LspDiagnostic>>? _diagnosticsSubscription;

  @override
  LspStateModel build() {
    _diagnosticsSubscription = ref
        .read(lspClientProvider)
        .diagnostics
        .listen(updateDiagnostics);
    ref.onDispose(() => _diagnosticsSubscription?.cancel());
    return LspStateModel(servers: defaultLspServers);
  }

  void setServer(LspServerDefinition definition) {
    state = state.copyWith(
      servers: [
        definition,
        ...state.servers.where(
          (server) => server.language != definition.language,
        ),
      ],
    );
  }

  Future<void> startForLanguage(EditorLanguage language) async {
    final workspace = ref.read(workspaceControllerProvider).workspace;
    final definition = _serverFor(language);
    if (workspace == null || definition == null) {
      return;
    }
    state = state.copyWith(isBusy: true, clearError: true);
    try {
      await ref
          .read(lspClientProvider)
          .start(definition: definition, workspacePath: workspace.path);
      final active = ref.read(editorControllerProvider).activeDocument;
      if (active != null && active.language == language) {
        ref
            .read(lspClientProvider)
            .didOpen(
              language: language,
              path: active.path,
              content: active.content,
            );
      }
      state = state.copyWith(isBusy: false);
    } on Object catch (error) {
      state = state.copyWith(isBusy: false, error: error.toString());
    }
  }

  void updateDiagnostics(List<LspDiagnostic> diagnostics) {
    state = state.copyWith(diagnostics: diagnostics);
  }

  LspServerDefinition? _serverFor(EditorLanguage language) {
    for (final server in state.servers) {
      if (server.language == language) {
        return server;
      }
    }
    return null;
  }
}

final defaultLspServers = <LspServerDefinition>[
  const LspServerDefinition(
    language: EditorLanguage.dart,
    command: 'dart',
    arguments: ['language-server', '--protocol=lsp'],
  ),
  const LspServerDefinition(
    language: EditorLanguage.javascript,
    command: 'typescript-language-server',
    arguments: ['--stdio'],
  ),
  const LspServerDefinition(
    language: EditorLanguage.typescript,
    command: 'typescript-language-server',
    arguments: ['--stdio'],
  ),
  const LspServerDefinition(language: EditorLanguage.python, command: 'pylsp'),
  const LspServerDefinition(
    language: EditorLanguage.csharp,
    command: 'csharp-ls',
  ),
  const LspServerDefinition(
    language: EditorLanguage.html,
    command: 'vscode-html-language-server',
    arguments: ['--stdio'],
  ),
  const LspServerDefinition(
    language: EditorLanguage.css,
    command: 'vscode-css-language-server',
    arguments: ['--stdio'],
  ),
  const LspServerDefinition(
    language: EditorLanguage.json,
    command: 'vscode-json-language-server',
    arguments: ['--stdio'],
  ),
  const LspServerDefinition(
    language: EditorLanguage.markdown,
    command: 'marksman',
    arguments: ['server'],
  ),
];
