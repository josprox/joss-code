import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;

import '../../../application/editor/editor_controller.dart';
import '../../../application/git/git_controller.dart';
import '../../../application/plugins/plugins_controller.dart';
import '../../../application/search/search_controller.dart';
import '../../../application/settings/settings_controller.dart';
import '../../../application/workspace/workspace_controller.dart';
import '../../../domain/settings/app_settings.dart';
import '../../../domain/workspace/workspace_models.dart';
import '../../theme/app_theme.dart';

class Sidebar extends ConsumerWidget {
  const Sidebar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final workspace = ref.watch(workspaceControllerProvider);
    final colors = context.workbenchColors;
    return Container(
      decoration: BoxDecoration(
        color: colors.sideBar,
        border: Border(right: BorderSide(color: colors.border)),
      ),
      child: switch (workspace.activePanel) {
        WorkspacePanel.explorer => const ExplorerPanel(),
        WorkspacePanel.search => const SearchPanel(),
        WorkspacePanel.sourceControl => const SourceControlPanel(),
        WorkspacePanel.extensions => const ExtensionsPanel(),
        WorkspacePanel.settings => const SettingsPanel(),
      },
    );
  }
}

class ExplorerPanel extends ConsumerWidget {
  const ExplorerPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(workspaceControllerProvider);
    return _PanelScaffold(
      title: 'Explorer',
      actions: [
        IconButton(
          tooltip: 'Open Workspace',
          icon: const Icon(Icons.folder_open),
          onPressed: () => ref
              .read(workspaceControllerProvider.notifier)
              .pickAndOpenWorkspace(),
        ),
        IconButton(
          tooltip: 'New File',
          icon: const Icon(Icons.note_add_outlined),
          onPressed: state.workspace == null
              ? null
              : () => _createFile(context, ref),
        ),
        IconButton(
          tooltip: 'New Folder',
          icon: const Icon(Icons.create_new_folder_outlined),
          onPressed: state.workspace == null
              ? null
              : () => _createFolder(context, ref),
        ),
        IconButton(
          tooltip: 'Refresh',
          icon: const Icon(Icons.refresh),
          onPressed: () =>
              ref.read(workspaceControllerProvider.notifier).refreshTree(),
        ),
      ],
      child: state.workspace == null
          ? _EmptyPanel(
              icon: Icons.folder_outlined,
              text: 'No workspace open',
              action: FilledButton.icon(
                onPressed: () => ref
                    .read(workspaceControllerProvider.notifier)
                    .pickAndOpenWorkspace(),
                icon: const Icon(Icons.folder_open),
                label: const Text('Open Folder'),
              ),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (!state.workspace!.isTrusted)
                  Container(
                    margin: const EdgeInsets.all(8),
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: context.workbenchColors.warning,
                      ),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.shield_outlined, size: 16),
                        const SizedBox(width: 8),
                        const Expanded(child: Text('Restricted mode')),
                        TextButton(
                          onPressed: () => ref
                              .read(workspaceControllerProvider.notifier)
                              .trustCurrentWorkspace(),
                          child: const Text('Trust'),
                        ),
                      ],
                    ),
                  ),
                Expanded(
                  child: state.isLoadingTree
                      ? const Center(child: CircularProgressIndicator())
                      : ListView(
                          padding: const EdgeInsets.only(bottom: 12),
                          children: [
                            if (state.root != null)
                              FileTreeNode(node: state.root!, depth: 0),
                          ],
                        ),
                ),
              ],
            ),
    );
  }

  Future<void> _createFile(BuildContext context, WidgetRef ref) async {
    final relativePath = await _promptText(
      context,
      title: 'New File',
      label: 'Relative path',
      hint: 'lib/src/example.dart',
    );
    if (relativePath != null && relativePath.trim().isNotEmpty) {
      await ref
          .read(workspaceControllerProvider.notifier)
          .createFile(relativePath.trim());
    }
  }

  Future<void> _createFolder(BuildContext context, WidgetRef ref) async {
    final relativePath = await _promptText(
      context,
      title: 'New Folder',
      label: 'Relative path',
      hint: 'lib/src/feature',
    );
    if (relativePath != null && relativePath.trim().isNotEmpty) {
      await ref
          .read(workspaceControllerProvider.notifier)
          .createFolder(relativePath.trim());
    }
  }
}

class FileTreeNode extends ConsumerWidget {
  const FileTreeNode({required this.node, required this.depth, super.key});

  final FileNode node;
  final int depth;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.workbenchColors;
    final workspaceState = ref.watch(workspaceControllerProvider);
    final isExpanded = workspaceState.expandedPaths.contains(node.path);
    final relative = workspaceState.workspace == null
        ? node.name
        : p.relative(node.path, from: workspaceState.workspace!.path);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: node.isDirectory
              ? () => ref
                    .read(workspaceControllerProvider.notifier)
                    .toggleFolder(node.path)
              : () => ref
                    .read(editorControllerProvider.notifier)
                    .openFile(node.path),
          child: Container(
            height: 32,
            margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 1),
            padding: EdgeInsets.only(left: 8 + depth * 14, right: 4),
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(8)),
            child: Row(
              children: [
                Icon(
                  node.isDirectory
                      ? (isExpanded
                            ? Icons.folder_open_outlined
                            : Icons.folder_outlined)
                      : _iconForFile(node.name),
                  size: 18,
                  color: node.isDirectory
                      ? colors.accent
                      : Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 6),
                if (node.isDirectory)
                  Icon(
                    isExpanded
                        ? Icons.keyboard_arrow_down
                        : Icons.keyboard_arrow_right,
                    size: 16,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                if (node.isDirectory) const SizedBox(width: 2),
                Expanded(
                  child: Text(
                    depth == 0 ? node.name : p.basename(relative),
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: node.isDirectory ? FontWeight.w600 : null,
                    ),
                  ),
                ),
                if (depth > 0)
                  SizedBox(
                    width: 32,
                    child: PopupMenuButton<String>(
                      tooltip: 'File actions',
                      padding: EdgeInsets.zero,
                      icon: const Icon(Icons.more_horiz, size: 16),
                      onSelected: (value) => _handleAction(context, ref, value),
                      itemBuilder: (context) => const [
                        PopupMenuItem(value: 'rename', child: Text('Rename')),
                        PopupMenuItem(value: 'delete', child: Text('Delete')),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
        if (node.isDirectory && isExpanded)
          for (final child in node.children)
            FileTreeNode(node: child, depth: depth + 1),
      ],
    );
  }

  IconData _iconForFile(String name) {
    final extension = p.extension(name).toLowerCase();
    return switch (extension) {
      '.dart' => Icons.flutter_dash,
      '.json' || '.yaml' || '.yml' => Icons.data_object,
      '.md' => Icons.article_outlined,
      '.png' || '.jpg' || '.jpeg' || '.webp' => Icons.image_outlined,
      _ => Icons.description_outlined,
    };
  }

  Future<void> _handleAction(
    BuildContext context,
    WidgetRef ref,
    String action,
  ) async {
    if (action == 'rename') {
      final name = await _promptText(
        context,
        title: 'Rename',
        label: 'New name',
        initialValue: node.name,
      );
      if (name != null && name.trim().isNotEmpty) {
        await ref
            .read(workspaceControllerProvider.notifier)
            .renamePath(node.path, name.trim());
      }
      return;
    }
    if (action == 'delete') {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text('Delete'),
            content: Text('Delete ${node.name}?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Delete'),
              ),
            ],
          );
        },
      );
      if (confirmed ?? false) {
        await ref.read(workspaceControllerProvider.notifier).delete(node.path);
      }
    }
  }
}

Future<String?> _promptText(
  BuildContext context, {
  required String title,
  required String label,
  String? hint,
  String? initialValue,
}) async {
  final controller = TextEditingController(text: initialValue);
  try {
    return showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(title),
          content: TextField(
            controller: controller,
            autofocus: true,
            decoration: InputDecoration(labelText: label, hintText: hint),
            onSubmitted: (value) => Navigator.of(context).pop(value),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(controller.text),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  } finally {
    controller.dispose();
  }
}

class SearchPanel extends ConsumerWidget {
  const SearchPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(searchControllerProvider);
    final workspace = ref.watch(workspaceControllerProvider).workspace;
    return _PanelScaffold(
      title: 'Search',
      actions: [
        IconButton(
          tooltip: state.isSearching ? 'Cancel' : 'Search',
          icon: Icon(state.isSearching ? Icons.stop : Icons.search),
          onPressed: state.isSearching
              ? ref.read(searchControllerProvider.notifier).cancel
              : ref.read(searchControllerProvider.notifier).searchNow,
        ),
      ],
      child: workspace == null
          ? const _EmptyPanel(
              icon: Icons.search,
              text: 'Open a workspace to search',
            )
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(8),
                  child: TextField(
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.search),
                      hintText: 'Search text',
                    ),
                    onChanged: ref
                        .read(searchControllerProvider.notifier)
                        .setQuery,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: CheckboxListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    value: state.useRegex,
                    onChanged: (value) => ref
                        .read(searchControllerProvider.notifier)
                        .setRegex(value ?? false),
                    title: const Text('Regex'),
                  ),
                ),
                if (state.isSearching)
                  const LinearProgressIndicator(minHeight: 2),
                Expanded(
                  child: ListView.builder(
                    itemCount: state.matches.length,
                    itemBuilder: (context, index) {
                      final match = state.matches[index];
                      return ListTile(
                        dense: true,
                        title: Text(
                          p.relative(match.filePath, from: workspace.path),
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Text(
                          '${match.lineNumber}:${match.column}  ${match.preview}',
                          overflow: TextOverflow.ellipsis,
                        ),
                        onTap: () => ref
                            .read(editorControllerProvider.notifier)
                            .openFile(match.filePath),
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }
}

class SourceControlPanel extends ConsumerStatefulWidget {
  const SourceControlPanel({super.key});

  @override
  ConsumerState<SourceControlPanel> createState() => _SourceControlPanelState();
}

class _SourceControlPanelState extends ConsumerState<SourceControlPanel> {
  final TextEditingController _commitController = TextEditingController();

  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(gitControllerProvider.notifier).refresh());
  }

  @override
  void dispose() {
    _commitController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final git = ref.watch(gitControllerProvider);
    final workspace = ref.watch(workspaceControllerProvider).workspace;
    return _PanelScaffold(
      title: 'Source Control',
      actions: [
        IconButton(
          tooltip: 'Pull',
          icon: const Icon(Icons.download_outlined),
          onPressed: git.isRepository
              ? () => ref.read(gitControllerProvider.notifier).pull()
              : null,
        ),
        IconButton(
          tooltip: 'Push',
          icon: const Icon(Icons.upload_outlined),
          onPressed: git.isRepository
              ? () => ref.read(gitControllerProvider.notifier).push()
              : null,
        ),
        IconButton(
          tooltip: 'Refresh Git',
          icon: const Icon(Icons.refresh),
          onPressed: () => ref.read(gitControllerProvider.notifier).refresh(),
        ),
      ],
      child: workspace == null
          ? const _EmptyPanel(
              icon: Icons.account_tree_outlined,
              text: 'Open a workspace to use Git',
            )
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(8),
                  child: TextField(
                    controller: _commitController,
                    minLines: 1,
                    maxLines: 3,
                    decoration: InputDecoration(
                      hintText: git.isRepository
                          ? 'Commit message'
                          : 'Not a Git repository',
                      suffixIcon: IconButton(
                        tooltip: 'Commit',
                        icon: const Icon(Icons.check),
                        onPressed: git.isRepository
                            ? () {
                                ref
                                    .read(gitControllerProvider.notifier)
                                    .commit(_commitController.text);
                                _commitController.clear();
                              }
                            : null,
                      ),
                    ),
                  ),
                ),
                if (git.isBusy) const LinearProgressIndicator(minHeight: 2),
                Expanded(
                  child: git.isRepository
                      ? ListView(
                          children: [
                            Padding(
                              padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
                              child: Text(
                                git.branch == null
                                    ? 'Changes'
                                    : 'Changes - ${git.branch}',
                                style: Theme.of(context).textTheme.labelMedium,
                              ),
                            ),
                            for (final file in git.changedFiles)
                              ListTile(
                                dense: true,
                                leading: Icon(
                                  file.isStaged
                                      ? Icons.add_task
                                      : Icons.edit_outlined,
                                  size: 18,
                                ),
                                title: Text(
                                  file.path,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                subtitle: Text(file.status.name),
                                trailing: IconButton(
                                  tooltip: file.isStaged ? 'Unstage' : 'Stage',
                                  icon: Icon(
                                    file.isStaged
                                        ? Icons.remove_circle_outline
                                        : Icons.add_circle_outline,
                                  ),
                                  onPressed: () => file.isStaged
                                      ? ref
                                            .read(
                                              gitControllerProvider.notifier,
                                            )
                                            .unstage(file.path)
                                      : ref
                                            .read(
                                              gitControllerProvider.notifier,
                                            )
                                            .stage(file.path),
                                ),
                              ),
                            if (git.changedFiles.isEmpty)
                              const ListTile(
                                dense: true,
                                leading: Icon(Icons.check_circle_outline),
                                title: Text('Working tree clean'),
                              ),
                            const Divider(),
                            Padding(
                              padding: const EdgeInsets.fromLTRB(12, 4, 12, 4),
                              child: Text(
                                'History',
                                style: Theme.of(context).textTheme.labelMedium,
                              ),
                            ),
                            for (final commit in git.history.take(8))
                              ListTile(
                                dense: true,
                                leading: const Icon(Icons.commit, size: 18),
                                title: Text(
                                  commit.message,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                subtitle: Text(
                                  '${_shortHash(commit.hash)} - ${commit.author}',
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                          ],
                        )
                      : const _EmptyPanel(
                          icon: Icons.account_tree_outlined,
                          text: 'No repository detected',
                        ),
                ),
              ],
            ),
    );
  }
}

String _shortHash(String hash) {
  if (hash.length <= 7) {
    return hash;
  }
  return hash.substring(0, 7);
}

class ExtensionsPanel extends ConsumerWidget {
  const ExtensionsPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(pluginsControllerProvider);
    return _PanelScaffold(
      title: 'Extensions',
      actions: [
        IconButton(
          tooltip: 'Install VSIX',
          icon: const Icon(Icons.upload_file),
          onPressed: () async {
            final result = await FilePicker.pickFiles(
              type: FileType.custom,
              allowedExtensions: ['vsix'],
            );
            final path = result?.files.single.path;
            if (path != null) {
              await ref
                  .read(pluginsControllerProvider.notifier)
                  .installVsix(path);
            }
          },
        ),
        IconButton(
          tooltip: 'Refresh Extensions',
          icon: const Icon(Icons.refresh),
          onPressed: () => ref.read(pluginsControllerProvider.notifier).scan(),
        ),
      ],
      child: state.isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              children: [
                for (final plugin in state.installed)
                  SwitchListTile(
                    dense: true,
                    value: plugin.isEnabled,
                    onChanged: (value) => ref
                        .read(pluginsControllerProvider.notifier)
                        .setEnabled(plugin.id, value),
                    title: Text(
                      plugin.displayName,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Text(
                      '${plugin.publisher} - ${plugin.version}',
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                if (state.installed.isEmpty)
                  const _EmptyPanel(
                    icon: Icons.extension_outlined,
                    text: 'No extensions installed',
                  ),
              ],
            ),
    );
  }
}

class SettingsPanel extends ConsumerWidget {
  const SettingsPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsControllerProvider);
    return _PanelScaffold(
      title: 'Settings',
      child: ListView(
        padding: const EdgeInsets.all(8),
        children: [
          DropdownButtonFormField<EditorThemeMode>(
            initialValue: settings.themeModeSetting,
            decoration: const InputDecoration(labelText: 'Theme'),
            items: [
              for (final mode in EditorThemeMode.values)
                DropdownMenuItem(value: mode, child: Text(mode.name)),
            ],
            onChanged: (value) {
              if (value != null) {
                ref.read(settingsControllerProvider.notifier).setTheme(value);
              }
            },
          ),
          const SizedBox(height: 12),
          Text('Font size ${settings.fontSize.toStringAsFixed(0)}'),
          Slider(
            value: settings.fontSize,
            min: 10,
            max: 28,
            divisions: 18,
            onChanged: (value) => ref
                .read(settingsControllerProvider.notifier)
                .setFontSize(value),
          ),
          SwitchListTile(
            dense: true,
            contentPadding: EdgeInsets.zero,
            value: settings.wordWrap,
            onChanged: (value) => ref
                .read(settingsControllerProvider.notifier)
                .setWordWrap(value),
            title: const Text('Word wrap'),
          ),
          SwitchListTile(
            dense: true,
            contentPadding: EdgeInsets.zero,
            value: settings.autoSave,
            onChanged: (value) => ref
                .read(settingsControllerProvider.notifier)
                .setAutoSave(value),
            title: const Text('Auto save'),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: settings.defaultTerminal ?? 'system',
            decoration: const InputDecoration(labelText: 'Default terminal'),
            items: const [
              DropdownMenuItem<String>(
                value: 'system',
                child: Text('System default'),
              ),
              DropdownMenuItem(value: 'powershell', child: Text('PowerShell')),
              DropdownMenuItem(value: 'cmd', child: Text('CMD')),
              DropdownMenuItem(value: 'bash', child: Text('Bash')),
              DropdownMenuItem(value: 'zsh', child: Text('Zsh')),
            ],
            onChanged: (value) => ref
                .read(settingsControllerProvider.notifier)
                .setDefaultTerminal(value == 'system' ? null : value),
          ),
          const Divider(),
          const Text('Recent workspaces'),
          for (final path in settings.recentWorkspaces)
            ListTile(
              dense: true,
              title: Text(path, overflow: TextOverflow.ellipsis),
              onTap: () => ref
                  .read(workspaceControllerProvider.notifier)
                  .openWorkspace(path),
            ),
        ],
      ),
    );
  }
}

class _PanelScaffold extends StatelessWidget {
  const _PanelScaffold({
    required this.title,
    required this.child,
    this.actions = const [],
  });

  final String title;
  final Widget child;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    final colors = context.workbenchColors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          height: 56,
          padding: const EdgeInsets.only(left: 16, right: 8),
          decoration: BoxDecoration(
            color: colors.sideBar,
            border: Border(bottom: BorderSide(color: colors.border)),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              ...actions,
            ],
          ),
        ),
        Expanded(child: child),
      ],
    );
  }
}

class _EmptyPanel extends StatelessWidget {
  const _EmptyPanel({required this.icon, required this.text, this.action});

  final IconData icon;
  final String text;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 36,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 12),
            Text(text, textAlign: TextAlign.center),
            if (action != null) ...[const SizedBox(height: 16), action!],
          ],
        ),
      ),
    );
  }
}
