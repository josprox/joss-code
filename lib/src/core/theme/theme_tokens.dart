import 'package:flutter/material.dart';

class WorkbenchColors extends ThemeExtension<WorkbenchColors> {
  const WorkbenchColors({
    required this.activityBar,
    required this.sideBar,
    required this.editor,
    required this.panel,
    required this.statusBar,
    required this.tabActive,
    required this.tabInactive,
    required this.border,
    required this.accent,
    required this.warning,
    required this.success,
  });

  final Color activityBar;
  final Color sideBar;
  final Color editor;
  final Color panel;
  final Color statusBar;
  final Color tabActive;
  final Color tabInactive;
  final Color border;
  final Color accent;
  final Color warning;
  final Color success;

  @override
  WorkbenchColors copyWith({
    Color? activityBar,
    Color? sideBar,
    Color? editor,
    Color? panel,
    Color? statusBar,
    Color? tabActive,
    Color? tabInactive,
    Color? border,
    Color? accent,
    Color? warning,
    Color? success,
  }) {
    return WorkbenchColors(
      activityBar: activityBar ?? this.activityBar,
      sideBar: sideBar ?? this.sideBar,
      editor: editor ?? this.editor,
      panel: panel ?? this.panel,
      statusBar: statusBar ?? this.statusBar,
      tabActive: tabActive ?? this.tabActive,
      tabInactive: tabInactive ?? this.tabInactive,
      border: border ?? this.border,
      accent: accent ?? this.accent,
      warning: warning ?? this.warning,
      success: success ?? this.success,
    );
  }

  @override
  WorkbenchColors lerp(ThemeExtension<WorkbenchColors>? other, double t) {
    if (other is! WorkbenchColors) {
      return this;
    }
    return WorkbenchColors(
      activityBar: Color.lerp(activityBar, other.activityBar, t)!,
      sideBar: Color.lerp(sideBar, other.sideBar, t)!,
      editor: Color.lerp(editor, other.editor, t)!,
      panel: Color.lerp(panel, other.panel, t)!,
      statusBar: Color.lerp(statusBar, other.statusBar, t)!,
      tabActive: Color.lerp(tabActive, other.tabActive, t)!,
      tabInactive: Color.lerp(tabInactive, other.tabInactive, t)!,
      border: Color.lerp(border, other.border, t)!,
      accent: Color.lerp(accent, other.accent, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      success: Color.lerp(success, other.success, t)!,
    );
  }
}
