import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/workspace/workspace_models.dart';
import '../workspace/workspace_controller.dart';

enum BottomPanelKind { terminal, intelligence, problems, output, debugConsole }

class WorkbenchStateModel {
  const WorkbenchStateModel({
    this.isCommandPaletteOpen = false,
    this.bottomPanel = BottomPanelKind.terminal,
    this.isBottomPanelVisible = true,
    this.isSidebarVisible = true,
    this.compactMode = false,
  });

  final bool isCommandPaletteOpen;
  final BottomPanelKind bottomPanel;
  final bool isBottomPanelVisible;
  final bool isSidebarVisible;
  final bool compactMode;

  WorkbenchStateModel copyWith({
    bool? isCommandPaletteOpen,
    BottomPanelKind? bottomPanel,
    bool? isBottomPanelVisible,
    bool? isSidebarVisible,
    bool? compactMode,
  }) {
    return WorkbenchStateModel(
      isCommandPaletteOpen: isCommandPaletteOpen ?? this.isCommandPaletteOpen,
      bottomPanel: bottomPanel ?? this.bottomPanel,
      isBottomPanelVisible: isBottomPanelVisible ?? this.isBottomPanelVisible,
      isSidebarVisible: isSidebarVisible ?? this.isSidebarVisible,
      compactMode: compactMode ?? this.compactMode,
    );
  }
}

final workbenchControllerProvider =
    NotifierProvider<WorkbenchController, WorkbenchStateModel>(
      WorkbenchController.new,
    );

class WorkbenchController extends Notifier<WorkbenchStateModel> {
  @override
  WorkbenchStateModel build() => const WorkbenchStateModel();

  Future<void> restoreLastWorkspace() =>
      ref.read(workspaceControllerProvider.notifier).restoreLastWorkspace();

  void openCommandPalette() {
    state = state.copyWith(isCommandPaletteOpen: true);
  }

  void closeCommandPalette() {
    state = state.copyWith(isCommandPaletteOpen: false);
  }

  void toggleSidebar() {
    state = state.copyWith(isSidebarVisible: !state.isSidebarVisible);
  }

  void showPanel(BottomPanelKind panel) {
    state = state.copyWith(bottomPanel: panel, isBottomPanelVisible: true);
  }

  void toggleBottomPanel() {
    state = state.copyWith(isBottomPanelVisible: !state.isBottomPanelVisible);
  }

  void setCompactMode(bool compact) {
    if (state.compactMode == compact) {
      return;
    }
    state = state.copyWith(compactMode: compact);
    if (compact) {
      ref
          .read(workspaceControllerProvider.notifier)
          .setActivePanel(WorkspacePanel.explorer);
    }
  }
}
