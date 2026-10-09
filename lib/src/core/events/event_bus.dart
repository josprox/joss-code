import 'dart:async';

abstract class AppEvent {
  const AppEvent();
}

class WorkspaceOpenedEvent extends AppEvent {
  const WorkspaceOpenedEvent(this.path);

  final String path;
}

class FileSavedEvent extends AppEvent {
  const FileSavedEvent(this.path);

  final String path;
}

class CommandExecutedEvent extends AppEvent {
  const CommandExecutedEvent(this.commandId);

  final String commandId;
}

class SensitiveActionEvent extends AppEvent {
  const SensitiveActionEvent(this.description);

  final String description;
}

class AppEventBus {
  final StreamController<AppEvent> _controller =
      StreamController<AppEvent>.broadcast();

  Stream<T> on<T extends AppEvent>() =>
      _controller.stream.where((event) => event is T).cast<T>();

  void emit(AppEvent event) => _controller.add(event);

  Future<void> dispose() => _controller.close();
}
