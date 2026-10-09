import '../events/event_bus.dart';
import '../logging/app_logger.dart';
import 'command.dart';

class CommandRegistry {
  CommandRegistry(this._eventBus, this._logger);

  final AppEventBus _eventBus;
  final AppLogger _logger;
  final Map<String, AppCommand> _commands = {};

  List<AppCommand> get commands {
    final values = _commands.values.toList()
      ..sort(
        (a, b) =>
            '${a.category}.${a.title}'.compareTo('${b.category}.${b.title}'),
      );
    return values;
  }

  AppCommand? byId(String id) => _commands[id];

  void register(AppCommand command, {bool replace = true}) {
    if (!replace && _commands.containsKey(command.id)) {
      throw StateError('Command already registered: ${command.id}');
    }
    _commands[command.id] = command;
    _logger.debug('Registered command ${command.id}');
  }

  void registerAll(Iterable<AppCommand> commands) {
    for (final command in commands) {
      register(command);
    }
  }

  Future<void> execute(
    String id, [
    CommandContext context = const CommandContext(),
  ]) async {
    final command = _commands[id];
    if (command == null) {
      throw StateError('Unknown command: $id');
    }
    if (command.isSensitive) {
      _eventBus.emit(SensitiveActionEvent(command.title));
      _logger.security('Executing sensitive command ${command.id}');
    }
    await command.handler(context);
    _eventBus.emit(CommandExecutedEvent(id));
  }

  List<AppCommand> search(String query) {
    final normalized = query.trim().toLowerCase();
    if (normalized.isEmpty) {
      return commands;
    }
    return commands
        .where(
          (command) =>
              command.title.toLowerCase().contains(normalized) ||
              command.id.toLowerCase().contains(normalized) ||
              command.category.toLowerCase().contains(normalized),
        )
        .toList();
  }
}
