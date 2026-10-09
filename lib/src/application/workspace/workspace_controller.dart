import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:watcher/watcher.dart';

import '../../core/di/service_providers.dart';
import '../../core/events/event_bus.dart';
import '../../domain/workspace/workspace_models.dart';
import '../settings/settings_controller.dart';

final workspaceControllerProvider =
    NotifierProvider<WorkspaceController, WorkspaceStateModel>(
      WorkspaceController.new,
    );

class WorkspaceController extends Notifier<WorkspaceStateModel> {
  StreamSubscription<WatchEvent>? _watchSubscription;
  Timer? _refreshDebounce;

  @override
  WorkspaceStateModel build() {
    ref.onDispose(() {
      _watchSubscription?.cancel();
      _refreshDebounce?.cancel();
    });
    return const WorkspaceStateModel();
  }

  Future<void> pickAndOpenWorkspace() async {
    final path = await ref.read(fileSystemServiceProvider).pickWorkspacePath();
    if (path == null) {
      return;
    }
    await openWorkspace(path);
  }

  Future<void> openWorkspace(String path) async {
    state = state.copyWith(isLoadingTree: true, clearError: true);
    try {
      final settings = ref.read(settingsControllerProvider);
      final workspace = Workspace(
        path: path,
        name: p.basename(path),
        isTrusted: settings.isTrusted(path),
        openedAt: DateTime.now(),
      );
      final root = await ref.read(fileSystemServiceProvider).buildTree(path);
      state = state.copyWith(
        workspace: workspace,
        root: root,
        expandedPaths: {root.path},
        isLoadingTree: false,
      );
      await ref
          .read(settingsControllerProvider.notifier)
          .rememberWorkspace(path);
      ref.read(eventBusProvider).emit(WorkspaceOpenedEvent(path));
      _startWatcher(path);
    } on Object catch (error) {
      state = state.copyWith(isLoadingTree: false, error: error.toString());
    }
  }

  Future<void> restoreLastWorkspace() async {
    final recent = ref.read(settingsControllerProvider).recentWorkspaces;
    if (recent.isEmpty) {
      return;
    }
    await openWorkspace(recent.first);
  }

  Future<void> refreshTree() async {
    final workspace = state.workspace;
    if (workspace == null) {
      return;
    }
    state = state.copyWith(isLoadingTree: true);
    try {
      final root = await ref
          .read(fileSystemServiceProvider)
          .buildTree(workspace.path);
      state = state.copyWith(
        root: root,
        isLoadingTree: false,
        clearError: true,
      );
    } on Object catch (error) {
      state = state.copyWith(isLoadingTree: false, error: error.toString());
    }
  }

  void setActivePanel(WorkspacePanel panel) {
    state = state.copyWith(activePanel: panel);
  }

  void toggleFolder(String path) {
    final expanded = {...state.expandedPaths};
    if (expanded.contains(path)) {
      expanded.remove(path);
    } else {
      expanded.add(path);
    }
    state = state.copyWith(expandedPaths: expanded);
  }

  Future<void> trustCurrentWorkspace() async {
    final workspace = state.workspace;
    if (workspace == null) {
      return;
    }
    await ref
        .read(settingsControllerProvider.notifier)
        .trustWorkspace(workspace.path);
    state = state.copyWith(workspace: workspace.copyWith(isTrusted: true));
  }

  Future<void> createFile(String relativePath) async {
    final workspace = state.workspace;
    if (workspace == null) {
      return;
    }
    final path = ref
        .read(pathGuardProvider)
        .safeJoin(workspace.path, relativePath);
    await ref.read(fileSystemServiceProvider).createFile(path, workspace.path);
    await refreshTree();
  }

  Future<void> createFolder(String relativePath) async {
    final workspace = state.workspace;
    if (workspace == null) {
      return;
    }
    final path = ref
        .read(pathGuardProvider)
        .safeJoin(workspace.path, relativePath);
    await ref
        .read(fileSystemServiceProvider)
        .createFolder(path, workspace.path);
    await refreshTree();
  }

  Future<void> delete(String path) async {
    final workspace = state.workspace;
    if (workspace == null) {
      return;
    }
    await ref.read(fileSystemServiceProvider).delete(path, workspace.path);
    await refreshTree();
  }

  Future<void> renamePath(String path, String newName) async {
    final workspace = state.workspace;
    if (workspace == null || newName.trim().isEmpty) {
      return;
    }
    await ref
        .read(fileSystemServiceProvider)
        .rename(path, workspace.path, newName.trim());
    await refreshTree();
  }

  void _startWatcher(String path) {
    _watchSubscription?.cancel();
    _watchSubscription = ref.read(fileSystemServiceProvider).watch(path).listen(
      (_) {
        _refreshDebounce?.cancel();
        _refreshDebounce = Timer(
          const Duration(milliseconds: 350),
          refreshTree,
        );
      },
    );
  }
}
