import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'application/commands/command_bootstrap.dart';
import 'application/settings/settings_controller.dart';
import 'application/workbench/workbench_controller.dart';
import 'presentation/theme/app_theme.dart';
import 'presentation/workbench/workbench_screen.dart';

class JossCodeApp extends ConsumerStatefulWidget {
  const JossCodeApp({super.key});

  @override
  ConsumerState<JossCodeApp> createState() => _JossCodeAppState();
}

class _JossCodeAppState extends ConsumerState<JossCodeApp> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() async {
      await ref.read(settingsControllerProvider.notifier).load();
      ref.read(commandBootstrapProvider);
      await ref
          .read(workbenchControllerProvider.notifier)
          .restoreLastWorkspace();
    });
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsControllerProvider);
    final theme = AppTheme.fromSettings(settings);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Joss Code',
      theme: theme.light,
      darkTheme: theme.dark,
      highContrastTheme: theme.highContrast,
      themeMode: settings.themeMode,
      home: const WorkbenchScreen(),
    );
  }
}
