import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:xterm/xterm.dart' as xterm;

import '../../../application/terminal/terminal_controller.dart';
import '../../theme/app_theme.dart';

class TerminalView extends ConsumerStatefulWidget {
  const TerminalView({super.key});

  @override
  ConsumerState<TerminalView> createState() => _TerminalViewState();
}

class _TerminalViewState extends ConsumerState<TerminalView> {
  final Map<String, xterm.Terminal> _terminals = {};
  final Map<String, int> _writtenLengths = {};
  final Map<String, xterm.TerminalController> _controllers = {};

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      if (ref.read(terminalControllerProvider).sessions.isEmpty) {
        ref.read(terminalControllerProvider.notifier).createSession();
      }
    });
  }

  @override
  void dispose() {
    _terminals.clear();
    _writtenLengths.clear();
    _controllers.clear();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(terminalControllerProvider);
    final active = state.activeSession;
    final liveIds = state.sessions.map((session) => session.id).toSet();
    _terminals.removeWhere((id, _) => !liveIds.contains(id));
    _writtenLengths.removeWhere((id, _) => !liveIds.contains(id));
    _controllers.removeWhere((id, _) => !liveIds.contains(id));

    if (active == null) {
      return Center(
        child: FilledButton.icon(
          onPressed: () =>
              ref.read(terminalControllerProvider.notifier).createSession(),
          icon: const Icon(Icons.terminal),
          label: const Text('Create Terminal'),
        ),
      );
    }

    final terminal = _terminalFor(active.id);
    final controller = _controllers.putIfAbsent(
      active.id,
      () => xterm.TerminalController(),
    );
    _syncOutput(active.id, active.output, terminal);

    return Column(
      children: [
        SizedBox(
          height: 38,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            scrollDirection: Axis.horizontal,
            itemCount: state.sessions.length,
            separatorBuilder: (_, _) => const SizedBox(width: 6),
            itemBuilder: (context, index) {
              final session = state.sessions[index];
              final selected = session.id == active.id;
              return InputChip(
                selected: selected,
                avatar: Icon(
                  session.isRunning ? Icons.circle : Icons.circle_outlined,
                  size: 10,
                  color: selected ? context.workbenchColors.accent : null,
                ),
                label: Text(session.title),
                onPressed: () => ref
                    .read(terminalControllerProvider.notifier)
                    .activate(session.id),
                onDeleted: () => ref
                    .read(terminalControllerProvider.notifier)
                    .close(session.id),
                deleteIcon: const Icon(Icons.close, size: 16),
                visualDensity: VisualDensity.compact,
              );
            },
          ),
        ),
        Expanded(
          child: Container(
            margin: const EdgeInsets.fromLTRB(8, 0, 8, 8),
            decoration: BoxDecoration(
              color: const Color(0xff07100e),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: context.workbenchColors.border),
            ),
            clipBehavior: Clip.antiAlias,
            child: xterm.TerminalView(
              terminal,
              controller: controller,
              autofocus: true,
              padding: const EdgeInsets.all(10),
              theme: const xterm.TerminalTheme(
                cursor: Color(0xff80cbc4),
                selection: Color(0x663aa99f),
                foreground: Color(0xffd6e7e2),
                background: Color(0xff07100e),
                black: Color(0xff07100e),
                red: Color(0xffff8a80),
                green: Color(0xff8fdc86),
                yellow: Color(0xffffd180),
                blue: Color(0xff82b1ff),
                magenta: Color(0xffea80fc),
                cyan: Color(0xff80cbc4),
                white: Color(0xffe8f5f2),
                brightBlack: Color(0xff35504a),
                brightRed: Color(0xffff8a80),
                brightGreen: Color(0xffb9f6ca),
                brightYellow: Color(0xffffecb3),
                brightBlue: Color(0xff82b1ff),
                brightMagenta: Color(0xffffabf3),
                brightCyan: Color(0xffa7ffeb),
                brightWhite: Color(0xffffffff),
                searchHitBackground: Color(0x66ffecb3),
                searchHitBackgroundCurrent: Color(0x99ffd180),
                searchHitForeground: Color(0xff07100e),
              ),
              textStyle: const xterm.TerminalStyle(
                fontFamily: 'Cascadia Mono',
                fontSize: 13,
              ),
            ),
          ),
        ),
      ],
    );
  }

  xterm.Terminal _terminalFor(String id) {
    return _terminals.putIfAbsent(id, () {
      final terminal = xterm.Terminal(maxLines: 10000);
      terminal.onOutput = (data) {
        ref.read(terminalControllerProvider.notifier).sendRawInput(id, data);
      };
      return terminal;
    });
  }

  void _syncOutput(String id, String output, xterm.Terminal terminal) {
    final previousLength = _writtenLengths[id] ?? 0;
    if (output.length < previousLength) {
      terminal.write('\x1b[2J\x1b[H');
      terminal.write(output);
    } else if (output.length > previousLength) {
      terminal.write(output.substring(previousLength));
    }
    _writtenLengths[id] = output.length;
  }
}
