import 'package:flutter/widgets.dart';

class CommandContext {
  const CommandContext({this.context});

  final BuildContext? context;
}

typedef CommandHandler = Future<void> Function(CommandContext context);

class AppCommand {
  const AppCommand({
    required this.id,
    required this.title,
    required this.category,
    required this.handler,
    this.keybinding,
    this.description,
    this.isSensitive = false,
  });

  final String id;
  final String title;
  final String category;
  final CommandHandler handler;
  final String? keybinding;
  final String? description;
  final bool isSensitive;
}
