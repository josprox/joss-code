import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../application/workbench/workbench_controller.dart';
import '../../../core/commands/command.dart';
import '../../../core/di/service_providers.dart';
import '../../theme/app_theme.dart';

class CommandPalette extends ConsumerStatefulWidget {
  const CommandPalette({super.key});

  @override
  ConsumerState<CommandPalette> createState() => _CommandPaletteState();
}

class _CommandPaletteState extends ConsumerState<CommandPalette> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  var _query = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _focusNode.requestFocus(),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final registry = ref.watch(commandRegistryProvider);
    final commands = registry.search(_query).take(12).toList();
    return Positioned.fill(
      child: Shortcuts(
        shortcuts: const {
          SingleActivator(LogicalKeyboardKey.escape): _DismissIntent(),
        },
        child: Actions(
          actions: {
            _DismissIntent: CallbackAction<_DismissIntent>(
              onInvoke: (_) {
                ref
                    .read(workbenchControllerProvider.notifier)
                    .closeCommandPalette();
                return null;
              },
            ),
          },
          child: GestureDetector(
            onTap: () => ref
                .read(workbenchControllerProvider.notifier)
                .closeCommandPalette(),
            child: Container(
              color: Colors.black.withValues(alpha: 0.28),
              alignment: Alignment.topCenter,
              padding: const EdgeInsets.only(top: 72),
              child: GestureDetector(
                onTap: () {},
                child: Material(
                  elevation: 18,
                  borderRadius: BorderRadius.circular(6),
                  color: context.workbenchColors.panel,
                  child: SizedBox(
                    width: 640,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextField(
                          controller: _controller,
                          focusNode: _focusNode,
                          decoration: const InputDecoration(
                            prefixIcon: Icon(Icons.chevron_right),
                            hintText: 'Type a command',
                            border: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            enabledBorder: InputBorder.none,
                          ),
                          onChanged: (value) => setState(() => _query = value),
                          onSubmitted: (_) {
                            if (commands.isNotEmpty) {
                              _run(commands.first);
                            }
                          },
                        ),
                        const Divider(height: 1),
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxHeight: 380),
                          child: ListView.builder(
                            shrinkWrap: true,
                            itemCount: commands.length,
                            itemBuilder: (context, index) {
                              final command = commands[index];
                              return ListTile(
                                dense: true,
                                leading: const Icon(
                                  Icons.bolt_outlined,
                                  size: 18,
                                ),
                                title: Text(command.title),
                                subtitle: Text(command.category),
                                trailing: command.keybinding == null
                                    ? null
                                    : Text(command.keybinding!),
                                onTap: () => _run(command),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _run(AppCommand command) async {
    ref.read(workbenchControllerProvider.notifier).closeCommandPalette();
    await ref
        .read(commandRegistryProvider)
        .execute(command.id, CommandContext(context: context));
  }
}

class _DismissIntent extends Intent {
  const _DismissIntent();
}
