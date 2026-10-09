import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;

import '../../core/di/service_providers.dart';
import '../../core/events/event_bus.dart';
import '../../domain/editor/editor_models.dart';
import '../settings/settings_controller.dart';
import '../workspace/workspace_controller.dart';

final editorControllerProvider =
    NotifierProvider<EditorController, EditorStateModel>(EditorController.new);

class EditorController extends Notifier<EditorStateModel> {
  @override
  EditorStateModel build() => const EditorStateModel();

  Future<void> openFile(String path) async {
    final existing = state.openDocuments
        .where((doc) => doc.path == path)
        .firstOrNull;
    if (existing != null) {
      state = state.copyWith(activeDocumentId: existing.id);
      return;
    }
    final workspace = ref.read(workspaceControllerProvider).workspace;
    if (workspace == null) {
      return;
    }
    final result = await ref
        .read(fileSystemServiceProvider)
        .readTextFile(path, workspace.path);
    final document = EditorDocument(
      id: path,
      path: path,
      name: p.basename(path),
      content: result.content,
      language: EditorLanguage.fromPath(path),
      isLargeFile: result.isLargeFile,
      error: result.error,
      openedAt: DateTime.now(),
    );
    state = state.copyWith(
      openDocuments: [...state.openDocuments, document],
      activeDocumentId: document.id,
    );
  }

  void activate(String documentId) {
    state = state.copyWith(activeDocumentId: documentId);
  }

  void updateActiveContent(String content) {
    final active = state.activeDocument;
    if (active == null) {
      return;
    }
    final updated = active.copyWith(content: content, isDirty: true);
    state = state.copyWith(
      openDocuments: [
        for (final document in state.openDocuments)
          document.id == active.id ? updated : document,
      ],
    );
    if (ref.read(settingsControllerProvider).autoSave) {
      saveActive();
    }
  }

  Future<void> saveActive() async {
    final active = state.activeDocument;
    final workspace = ref.read(workspaceControllerProvider).workspace;
    if (active == null || workspace == null || !active.isDirty) {
      return;
    }
    await ref
        .read(fileSystemServiceProvider)
        .writeTextFile(active.path, workspace.path, active.content);
    final saved = active.copyWith(isDirty: false);
    state = state.copyWith(
      openDocuments: [
        for (final document in state.openDocuments)
          document.id == active.id ? saved : document,
      ],
    );
    ref.read(eventBusProvider).emit(FileSavedEvent(active.path));
  }

  void close(String documentId) {
    final next = state.openDocuments
        .where((document) => document.id != documentId)
        .toList();
    state = state.copyWith(
      openDocuments: next,
      activeDocumentId: state.activeDocumentId == documentId && next.isNotEmpty
          ? next.last.id
          : state.activeDocumentId,
      clearActiveDocumentId:
          state.activeDocumentId == documentId && next.isEmpty,
    );
  }

  void setFindVisible(bool visible) {
    state = state.copyWith(showFind: visible);
  }

  void setSearchQuery(String value) {
    state = state.copyWith(searchQuery: value);
  }

  void setReplaceQuery(String value) {
    state = state.copyWith(replaceQuery: value);
  }

  void replaceAllInActive() {
    final active = state.activeDocument;
    if (active == null || state.searchQuery.isEmpty) {
      return;
    }
    updateActiveContent(
      active.content.replaceAll(state.searchQuery, state.replaceQuery),
    );
  }

  void zoomIn() {
    state = state.copyWith(fontZoom: (state.fontZoom + 1).clamp(-6, 12));
  }

  void zoomOut() {
    state = state.copyWith(fontZoom: (state.fontZoom - 1).clamp(-6, 12));
  }

  void resetZoom() {
    state = state.copyWith(fontZoom: 0);
  }

  void splitVertical() {
    state = state.copyWith(splitAxis: 'vertical');
  }

  void splitHorizontal() {
    state = state.copyWith(splitAxis: 'horizontal');
  }

  void closeSplit() {
    state = state.copyWith(clearSplitAxis: true);
  }
}

extension FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull {
    final iterator = this.iterator;
    if (iterator.moveNext()) {
      return iterator.current;
    }
    return null;
  }
}
