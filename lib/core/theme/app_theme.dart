import 'package:flutter/material.dart';

abstract final class AppTheme {
  static final ThemeData light = _build(Brightness.light);
  static final ThemeData dark = _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final dark = brightness == Brightness.dark;
    final ink = dark ? const Color(0xFFF4F4F4) : const Color(0xFF171717);
    final paper = dark ? const Color(0xFF131313) : Colors.white;
    final muted = dark ? const Color(0xFFB2B2B2) : const Color(0xFF656565);
    final line = dark ? const Color(0xFF383838) : const Color(0xFFDEDEDE);
    final soft = dark ? const Color(0xFF222222) : const Color(0xFFF5F5F5);
    final colors = ColorScheme(
      brightness: brightness,
      primary: ink,
      onPrimary: paper,
      secondary: ink,
      onSecondary: paper,
      tertiary: ink,
      onTertiary: paper,
      error: ink,
      onError: paper,
      surface: paper,
      onSurface: ink,
      onSurfaceVariant: muted,
      surfaceContainerLowest: paper,
      surfaceContainerLow: soft,
      surfaceContainer: soft,
      surfaceContainerHigh: soft,
      surfaceContainerHighest: soft,
      primaryContainer: soft,
      onPrimaryContainer: ink,
      secondaryContainer: soft,
      onSecondaryContainer: ink,
      tertiaryContainer: soft,
      onTertiaryContainer: ink,
      errorContainer: soft,
      onErrorContainer: ink,
      outline: muted,
      outlineVariant: line,
      inverseSurface: ink,
      onInverseSurface: paper,
      inversePrimary: paper,
      surfaceTint: Colors.transparent,
    );
    TextStyle type(
      double size,
      int weight, {
      Color? color,
      double height = 1.5,
    }) => TextStyle(
      fontFamily: 'StudySans',
      fontSize: size,
      fontWeight: FontWeight.values[(weight ~/ 100) - 1],
      fontVariations: [FontVariation('wght', weight.toDouble())],
      height: height,
      color: color ?? ink,
    );
    final text = TextTheme(
      displaySmall: const TextStyle(
        fontFamily: 'serif',
        fontSize: 36,
        fontWeight: FontWeight.w400,
        height: 1.2,
      ).copyWith(color: ink),
      headlineSmall: type(20, 600, height: 1.45),
      titleLarge: type(18, 600),
      titleMedium: type(16, 500),
      titleSmall: type(14, 500),
      bodyLarge: type(16, 400, height: 1.65),
      bodyMedium: type(14, 400),
      bodySmall: type(13, 400, color: muted),
      labelLarge: type(15, 500),
      labelMedium: type(13, 500),
      labelSmall: type(12, 400, color: muted),
    );
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(6),
    );
    const actionStyle = TextStyle(
      fontFamily: 'StudySans',
      fontSize: 15,
      fontWeight: FontWeight.w500,
      fontVariations: [FontVariation('wght', 500)],
      height: 1.5,
    );
    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colors,
      scaffoldBackgroundColor: paper,
      fontFamily: 'StudySans',
      textTheme: text,
      iconTheme: IconThemeData(color: ink),
      extensions: const [AppSpacing()],
      appBarTheme: AppBarTheme(
        backgroundColor: paper,
        foregroundColor: ink,
        iconTheme: IconThemeData(color: ink),
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: type(18, 500),
        shape: Border(bottom: BorderSide(color: line)),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(48, 52),
          shape: shape,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          textStyle: actionStyle,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(48, 52),
          shape: shape,
          side: BorderSide(color: line),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          textStyle: actionStyle,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          minimumSize: const Size(48, 48),
          textStyle: actionStyle,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: paper,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(6),
          side: BorderSide(color: line),
        ),
      ),
      dividerTheme: DividerThemeData(color: line, thickness: 1, space: 1),
      inputDecorationTheme: InputDecorationTheme(
        contentPadding: const EdgeInsets.all(16),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: BorderSide(color: line),
        ),
        hintStyle: type(14, 400, color: muted),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: ink,
        linearTrackColor: line,
        circularTrackColor: line,
        linearMinHeight: 3,
      ),
      expansionTileTheme: ExpansionTileThemeData(
        shape: Border(bottom: BorderSide(color: line)),
        collapsedShape: Border(bottom: BorderSide(color: line)),
        tilePadding: EdgeInsets.zero,
        childrenPadding: const EdgeInsets.only(bottom: 20),
        iconColor: ink,
        textColor: ink,
        collapsedIconColor: muted,
      ),
      dialogTheme: DialogThemeData(backgroundColor: paper, shape: shape),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: ink,
        contentTextStyle: type(14, 400, color: paper),
      ),
    );
  }
}

@immutable
class AppSpacing extends ThemeExtension<AppSpacing> {
  const AppSpacing({
    this.page = 24,
    this.section = 24,
    this.item = 16,
    this.small = 8,
  });
  final double page;
  final double section;
  final double item;
  final double small;
  static AppSpacing of(BuildContext context) =>
      Theme.of(context).extension<AppSpacing>() ?? const AppSpacing();
  @override
  AppSpacing copyWith({
    double? page,
    double? section,
    double? item,
    double? small,
  }) => AppSpacing(
    page: page ?? this.page,
    section: section ?? this.section,
    item: item ?? this.item,
    small: small ?? this.small,
  );
  @override
  AppSpacing lerp(AppSpacing? other, double t) => this;
}
