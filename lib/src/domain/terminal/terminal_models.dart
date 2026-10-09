enum TerminalKind { powershell, cmd, bash, zsh, fallback }

class TerminalSession {
  const TerminalSession({
    required this.id,
    required this.title,
    required this.kind,
    required this.cwd,
    this.output = '',
    this.history = const [],
    this.isRunning = false,
  });

  final String id;
  final String title;
  final TerminalKind kind;
  final String cwd;
  final String output;
  final List<String> history;
  final bool isRunning;

  TerminalSession copyWith({
    String? id,
    String? title,
    TerminalKind? kind,
    String? cwd,
    String? output,
    List<String>? history,
    bool? isRunning,
  }) {
    return TerminalSession(
      id: id ?? this.id,
      title: title ?? this.title,
      kind: kind ?? this.kind,
      cwd: cwd ?? this.cwd,
      output: output ?? this.output,
      history: history ?? this.history,
      isRunning: isRunning ?? this.isRunning,
    );
  }
}

class TerminalStateModel {
  const TerminalStateModel({this.sessions = const [], this.activeSessionId});

  final List<TerminalSession> sessions;
  final String? activeSessionId;

  TerminalSession? get activeSession {
    for (final session in sessions) {
      if (session.id == activeSessionId) {
        return session;
      }
    }
    return sessions.isEmpty ? null : sessions.first;
  }

  TerminalStateModel copyWith({
    List<TerminalSession>? sessions,
    String? activeSessionId,
    bool clearActiveSessionId = false,
  }) {
    return TerminalStateModel(
      sessions: sessions ?? this.sessions,
      activeSessionId: clearActiveSessionId
          ? null
          : activeSessionId ?? this.activeSessionId,
    );
  }
}
