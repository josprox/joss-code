import 'package:flutter/material.dart';

import '../../core/theme/theme_tokens.dart';
import '../../domain/settings/app_settings.dart';

class AppTheme {
  const AppTheme({
    required this.light,
    required this.dark,
    required this.highContrast,
  });

  final ThemeData light;
  final ThemeData dark;
  final ThemeData highContrast;

  factory AppTheme.fromSettings(AppSettings settings) {
    return AppTheme(
      light: _theme(
        brightness: Brightness.light,
        schemeSeed: const Color(0xff00796b),
        colors: const WorkbenchColors(
          activityBar: Color(0xffedf5f1),
          sideBar: Color(0xfff8faf7),
          editor: Color(0xfffcfdf8),
          panel: Color(0xfff1f6f2),
          statusBar: Color(0xff0b6b5d),
          tabActive: Color(0xffe2f2ea),
          tabInactive: Color(0xfff6f7f2),
          border: Color(0xffd7e3da),
          accent: Color(0xff00796b),
          warning: Color(0xffba4e00),
          success: Color(0xff2e7d32),
        ),
      ),
      dark: _theme(
        brightness: Brightness.dark,
        schemeSeed: const Color(0xff80cbc4),
        colors: const WorkbenchColors(
          activityBar: Color(0xff101917),
          sideBar: Color(0xff17211f),
          editor: Color(0xff0f1413),
          panel: Color(0xff131c1a),
          statusBar: Color(0xff003c38),
          tabActive: Color(0xff20332f),
          tabInactive: Color(0xff141c1a),
          border: Color(0xff29413c),
          accent: Color(0xff80cbc4),
          warning: Color(0xffffb86b),
          success: Color(0xff8fdc86),
        ),
      ),
      highContrast: _theme(
        brightness: Brightness.dark,
        schemeSeed: const Color(0xffffff00),
        colors: const WorkbenchColors(
          activityBar: Color(0xff000000),
          sideBar: Color(0xff000000),
          editor: Color(0xff000000),
          panel: Color(0xff000000),
          statusBar: Color(0xffffff00),
          tabActive: Color(0xff000000),
          tabInactive: Color(0xff101010),
          border: Color(0xffffffff),
          accent: Color(0xffffff00),
          warning: Color(0xffffcc00),
          success: Color(0xff00ff66),
        ),
      ),
    );
  }

  static ThemeData _theme({
    required Brightness brightness,
    required Color schemeSeed,
    required WorkbenchColors colors,
  }) {
    final scheme = ColorScheme.fromSeed(
      seedColor: schemeSeed,
      brightness: brightness,
    );
    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      visualDensity: VisualDensity.compact,
      scaffoldBackgroundColor: colors.editor,
      fontFamily: 'Segoe UI',
      extensions: [colors],
      splashFactory: InkSparkle.splashFactory,
      textTheme:
          (brightness == Brightness.dark
                  ? Typography.material2021().white
                  : Typography.material2021().black)
              .apply(fontFamily: 'Segoe UI'),
      tooltipTheme: TooltipThemeData(
        waitDuration: const Duration(milliseconds: 450),
        decoration: BoxDecoration(
          color: scheme.inverseSurface,
          borderRadius: BorderRadius.circular(8),
        ),
        textStyle: TextStyle(color: scheme.onInverseSurface, fontSize: 12),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          minimumSize: const Size.square(40),
          fixedSize: const Size.square(40),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: scheme.surfaceContainerHighest.withValues(alpha: 0.42),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 10,
        ),
      ),
    );
  }
}

extension WorkbenchTheme on BuildContext {
  WorkbenchColors get workbenchColors =>
      Theme.of(this).extension<WorkbenchColors>()!;
}
