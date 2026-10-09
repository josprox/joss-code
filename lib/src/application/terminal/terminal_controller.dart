import 'dart:async';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/di/service_providers.dart';
import '../../domain/terminal/terminal_models.dart';
import '../settings/settings_controller.dart';
import '../workspace/workspace_controller.dart';

final terminalControllerProvider =
    NotifierProvider<TerminalController, TerminalStateModel>(
      TerminalController.new,
    );

class TerminalController extends Notifier<TerminalStateModel> {
  StreamSubscription<TerminalSession>? _subscription;

  @override
  TerminalStateModel build() {
    _subscription = ref
        .read(terminalServiceProvider)
        .updates
        .listen(_updateSession);
    ref.onDispose(() => _subscription?.cancel());
    return const TerminalStateModel();
  }

  Future<void> createSession() async {
    final workspace = ref.read(workspaceControllerProvider).workspace;
    final cwd = workspace?.path ?? Directory.current.path;
    final settings = ref.read(settingsControllerProvider);
    final session = await ref
        .read(terminalServiceProvider)
        .createSession(cwd: cwd, preferredShell: settings.defaultTerminal);
    state = state.copyWith(
      sessions: [...state.sessions, session],
      activeSessionId: session.id,
    );
  }

  void activate(String id) {
    state = state.copyWith(activeSessionId: id);
  }

  void sendInput(String command) {
    final session = state.activeSession;
    if (session == null || command.trim().isEmpty) {
      return;
    }
    if (command.trim().toLowerCase() == 'exit') {
      close(session.id);
      return;
    }
    ref.read(terminalServiceProvider).sendInput(session, command);
  }

  void sendRawInput(String sessionId, String data) {
    ref.read(terminalServiceProvider).sendRawInput(sessionId, data);
  }

  Future<void> close(String id) async {
    await ref.read(terminalServiceProvider).disposeSession(id);
    final sessions = state.sessions
        .where((session) => session.id != id)
        .toList();
    state = state.copyWith(
      sessions: sessions,
      activeSessionId: sessions.isEmpty ? null : sessions.last.id,
      clearActiveSessionId: sessions.isEmpty,
    );
  }

  void _updateSession(TerminalSession session) {
    final exists = state.sessions.any((item) => item.id == session.id);
    if (exists &&
        !session.isRunning &&
        session.output.contains('[terminal closed]')) {
      final sessions = state.sessions
          .where((item) => item.id != session.id)
          .toList();
      state = state.copyWith(
        sessions: sessions,
        activeSessionId: sessions.isEmpty ? null : sessions.last.id,
        clearActiveSessionId: sessions.isEmpty,
      );
      return;
    }
    state = state.copyWith(
      sessions: exists
          ? [
              for (final item in state.sessions)
                item.id == session.id ? session : item,
            ]
          : [...state.sessions, session],
      activeSessionId: state.activeSessionId ?? session.id,
    );
  }
}
