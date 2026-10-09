import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/di/service_providers.dart';
import '../../domain/git/git_models.dart';
import '../workspace/workspace_controller.dart';

final gitControllerProvider =
    NotifierProvider<GitController, GitRepositoryState>(GitController.new);

class GitController extends Notifier<GitRepositoryState> {
  @override
  GitRepositoryState build() => const GitRepositoryState();

  Future<void> refresh() async {
    final workspace = ref.read(workspaceControllerProvider).workspace;
    if (workspace == null) {
      state = const GitRepositoryState();
      return;
    }
    state = state.copyWith(isBusy: true, clearError: true);
    try {
      state = (await ref.read(gitServiceProvider).readState(workspace.path))
          .copyWith(isBusy: false);
    } on Object catch (error) {
      state = state.copyWith(isBusy: false, error: error.toString());
    }
  }

  Future<void> stage(String path) => _run(
    (workspacePath) => ref.read(gitServiceProvider).stage(workspacePath, path),
  );

  Future<void> unstage(String path) => _run(
    (workspacePath) =>
        ref.read(gitServiceProvider).unstage(workspacePath, path),
  );

  Future<void> commit(String message) => _run(
    (workspacePath) =>
        ref.read(gitServiceProvider).commit(workspacePath, message),
  );

  Future<void> pull() =>
      _run((workspacePath) => ref.read(gitServiceProvider).pull(workspacePath));

  Future<void> push() =>
      _run((workspacePath) => ref.read(gitServiceProvider).push(workspacePath));

  Future<void> _run(
    Future<String> Function(String workspacePath) action,
  ) async {
    final workspace = ref.read(workspaceControllerProvider).workspace;
    if (workspace == null) {
      return;
    }
    state = state.copyWith(isBusy: true, clearError: true);
    try {
      final output = await action(workspace.path);
      await refresh();
      state = state.copyWith(lastOutput: output, isBusy: false);
    } on Object catch (error) {
      state = state.copyWith(error: error.toString(), isBusy: false);
    }
  }
}
