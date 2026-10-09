import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../application/intelligence/intelligence_controller.dart';
import '../../../application/lsp/lsp_controller.dart';
import '../../../application/terminal/terminal_controller.dart';
import '../../../application/workbench/workbench_controller.dart';
import '../../../core/di/service_providers.dart';
import '../../../core/logging/app_logger.dart';
import '../../../domain/intelligence/intelligence_models.dart';
import '../../terminal/widgets/terminal_view.dart';
import '../../theme/app_theme.dart';

class BottomPanel extends ConsumerWidget {
  const BottomPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final workbench = ref.watch(workbenchControllerProvider);
    final colors = context.workbenchColors;
    return Container(
      decoration: BoxDecoration(
        color: colors.panel,
        border: Border(top: BorderSide(color: colors.border)),
      ),
      child: Column(
        children: [
          SizedBox(
            height: 44,
            child: Row(
              children: [
                Expanded(
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    children: [
                      _PanelTab(
                        label: 'Terminal',
                        panel: BottomPanelKind.terminal,
                        icon: Icons.terminal,
                        active:
                            workbench.bottomPanel == BottomPanelKind.terminal,
                      ),
                      _PanelTab(
                        label: 'Intelligence',
                        panel: BottomPanelKind.intelligence,
                        icon: Icons.auto_awesome,
                        active:
                            workbench.bottomPanel ==
                            BottomPanelKind.intelligence,
                      ),
                      _PanelTab(
                        label: 'Problems',
                        panel: BottomPanelKind.problems,
                        icon: Icons.error_outline,
                        active:
                            workbench.bottomPanel == BottomPanelKind.problems,
                      ),
                      _PanelTab(
                        label: 'Output',
                        panel: BottomPanelKind.output,
                        icon: Icons.notes,
                        active: workbench.bottomPanel == BottomPanelKind.output,
                      ),
                      _PanelTab(
                        label: 'Debug',
                        panel: BottomPanelKind.debugConsole,
                        icon: Icons.bug_report_outlined,
                        active:
                            workbench.bottomPanel ==
                            BottomPanelKind.debugConsole,
                      ),
                    ],
                  ),
                ),
                if (workbench.bottomPanel == BottomPanelKind.terminal)
                  IconButton(
                    tooltip: 'New Terminal',
                    icon: const Icon(Icons.add),
                    onPressed: () => ref
                        .read(terminalControllerProvider.notifier)
                        .createSession(),
                  ),
                IconButton(
                  tooltip: 'Hide Panel',
                  icon: const Icon(Icons.keyboard_arrow_down),
                  onPressed: () => ref
                      .read(workbenchControllerProvider.notifier)
                      .toggleBottomPanel(),
                ),
              ],
            ),
          ),
          Expanded(
            child: switch (workbench.bottomPanel) {
              BottomPanelKind.terminal => const TerminalView(),
              BottomPanelKind.intelligence => const _IntelligenceView(),
              BottomPanelKind.problems => const _ProblemsView(),
              BottomPanelKind.output => const _OutputView(),
              BottomPanelKind.debugConsole => const _DebugConsoleView(),
            },
          ),
        ],
      ),
    );
  }
}

class _PanelTab extends ConsumerWidget {
  const _PanelTab({
    required this.label,
    required this.panel,
    required this.icon,
    required this.active,
  });

  final String label;
  final BottomPanelKind panel;
  final IconData icon;
  final bool active;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 5),
      child: TextButton.icon(
        onPressed: () =>
            ref.read(workbenchControllerProvider.notifier).showPanel(panel),
        style: TextButton.styleFrom(
          backgroundColor: active
              ? context.workbenchColors.tabActive
              : Colors.transparent,
          foregroundColor: active
              ? context.workbenchColors.accent
              : Theme.of(context).colorScheme.onSurfaceVariant,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        icon: Icon(icon, size: 16),
        label: Text(label),
      ),
    );
  }
}

class _IntelligenceView extends ConsumerWidget {
  const _IntelligenceView();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final report = ref.watch(intelligenceReportProvider);
    if (report == null) {
      return const Center(child: Text('Open a file to inspect it.'));
    }
    final colors = context.workbenchColors;
    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _MetricChip(label: report.language, icon: Icons.code),
            _MetricChip(
              label: '${report.lineCount} lines',
              icon: Icons.format_list_numbered,
            ),
            _MetricChip(
              label: '${report.nonEmptyLineCount} code lines',
              icon: Icons.subject,
            ),
            _MetricChip(
              label: 'Complexity ${report.complexityScore}',
              icon: Icons.insights,
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (report.insights.isNotEmpty) ...[
          Text('Insights', style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 6),
          for (final insight in report.insights)
            ListTile(
              dense: true,
              leading: Icon(
                _iconForSeverity(insight.severity),
                color: _colorForSeverity(context, insight.severity),
              ),
              title: Text(insight.title),
              subtitle: Text(insight.detail),
            ),
        ] else
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colors.tabActive,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: colors.border),
            ),
            child: const Text('No obvious local issues detected.'),
          ),
        const SizedBox(height: 12),
        _SymbolSection(title: 'Classes', values: report.symbols.classes),
        _SymbolSection(title: 'Functions', values: report.symbols.functions),
        _SymbolSection(title: 'Imports', values: report.symbols.imports),
      ],
    );
  }

  IconData _iconForSeverity(IntelligenceSeverity severity) {
    return switch (severity) {
      IntelligenceSeverity.warning => Icons.warning_amber,
      IntelligenceSeverity.suggestion => Icons.lightbulb_outline,
      IntelligenceSeverity.info => Icons.info_outline,
    };
  }

  Color _colorForSeverity(BuildContext context, IntelligenceSeverity severity) {
    return switch (severity) {
      IntelligenceSeverity.warning => context.workbenchColors.warning,
      IntelligenceSeverity.suggestion => context.workbenchColors.accent,
      IntelligenceSeverity.info => Theme.of(
        context,
      ).colorScheme.onSurfaceVariant,
    };
  }
}

class _MetricChip extends StatelessWidget {
  const _MetricChip({required this.label, required this.icon});

  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Chip(
      avatar: Icon(icon, size: 16),
      label: Text(label),
      visualDensity: VisualDensity.compact,
    );
  }
}

class _SymbolSection extends StatelessWidget {
  const _SymbolSection({required this.title, required this.values});

  final String title;
  final List<String> values;

  @override
  Widget build(BuildContext context) {
    if (values.isEmpty) {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final value in values) InputChip(label: Text(value)),
            ],
          ),
        ],
      ),
    );
  }
}

class _ProblemsView extends StatelessWidget {
  const _ProblemsView();

  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (context, ref, _) {
        final lsp = ref.watch(lspControllerProvider);
        if (lsp.diagnostics.isEmpty) {
          return const Center(child: Text('No diagnostics.'));
        }
        return ListView.builder(
          itemCount: lsp.diagnostics.length,
          itemBuilder: (context, index) {
            final diagnostic = lsp.diagnostics[index];
            return ListTile(
              dense: true,
              leading: const Icon(Icons.error_outline, size: 16),
              title: Text(diagnostic.message, overflow: TextOverflow.ellipsis),
              subtitle: Text(
                '${diagnostic.path}:${diagnostic.line + 1}:${diagnostic.character + 1}',
              ),
            );
          },
        );
      },
    );
  }
}

class _OutputView extends ConsumerWidget {
  const _OutputView();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final logs = ref.watch(loggerProvider).entries.reversed.toList();
    if (logs.isEmpty) {
      return const Center(child: Text('No output yet.'));
    }
    return ListView.builder(
      itemCount: logs.length,
      itemBuilder: (context, index) {
        final log = logs[index];
        return ListTile(
          dense: true,
          leading: Icon(_icon(log.level), size: 16),
          title: Text(log.message, overflow: TextOverflow.ellipsis),
          subtitle: Text(
            '${log.timestamp.toIso8601String()} ${log.error ?? ''}',
            overflow: TextOverflow.ellipsis,
          ),
        );
      },
    );
  }

  IconData _icon(LogLevel level) {
    return switch (level) {
      LogLevel.error => Icons.error_outline,
      LogLevel.warning => Icons.warning_amber,
      LogLevel.security => Icons.shield_outlined,
      _ => Icons.notes,
    };
  }
}

class _DebugConsoleView extends StatelessWidget {
  const _DebugConsoleView();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text(
        'Debug adapter integration is reserved for the next protocol layer.',
      ),
    );
  }
}
