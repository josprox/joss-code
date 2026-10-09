import 'package:flutter_test/flutter_test.dart';
import 'package:joss_code/src/core/commands/command.dart';
import 'package:joss_code/src/core/commands/command_registry.dart';
import 'package:joss_code/src/core/events/event_bus.dart';
import 'package:joss_code/src/core/logging/app_logger.dart';

void main() {
  test('registers, searches and executes commands', () async {
    final bus = AppEventBus();
    final registry = CommandRegistry(bus, AppLogger());
    var executed = false;

    registry.register(
      AppCommand(
        id: 'test.hello',
        title: 'Hello Test',
        category: 'Test',
        handler: (_) async => executed = true,
      ),
    );

    expect(registry.search('hello').single.id, 'test.hello');

    await registry.execute('test.hello');

    expect(executed, isTrue);
    await bus.dispose();
  });
}
