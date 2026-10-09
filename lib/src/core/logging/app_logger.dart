enum LogLevel { debug, info, warning, error, security }

class LogEntry {
  const LogEntry({
    required this.level,
    required this.message,
    required this.timestamp,
    this.error,
  });

  final LogLevel level;
  final String message;
  final DateTime timestamp;
  final Object? error;
}

class AppLogger {
  final List<LogEntry> _entries = [];

  List<LogEntry> get entries => List.unmodifiable(_entries);

  void debug(String message) => _add(LogLevel.debug, message);

  void info(String message) => _add(LogLevel.info, message);

  void warning(String message, [Object? error]) =>
      _add(LogLevel.warning, message, error);

  void error(String message, [Object? error]) =>
      _add(LogLevel.error, message, error);

  void security(String message, [Object? error]) =>
      _add(LogLevel.security, message, error);

  void _add(LogLevel level, String message, [Object? error]) {
    _entries.add(
      LogEntry(
        level: level,
        message: message,
        timestamp: DateTime.now(),
        error: error,
      ),
    );
    if (_entries.length > 1000) {
      _entries.removeRange(0, _entries.length - 1000);
    }
  }
}
