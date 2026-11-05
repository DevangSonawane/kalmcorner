import 'package:flutter/material.dart';

import 'tokens.dart';

ThemeData buildDawnTheme() => _buildTheme(ThemeColors.dawn(), Brightness.light);
ThemeData buildDuskTheme() => _buildTheme(ThemeColors.dusk(), Brightness.dark);
ThemeData buildMoonlitTheme() =>
    _buildTheme(ThemeColors.moonlit(), Brightness.dark);

ThemeData _buildTheme(ThemeColors c, Brightness brightness) {
  final colorScheme = ColorScheme(
    brightness: brightness,
    primary: c.accent,
    onPrimary: c.bg,
    secondary: c.accent2,
    onSecondary: c.bg,
    tertiary: c.success,
    onTertiary: c.bg,
    error: c.danger,
    onError: c.bg,
    surface: c.surface,
    onSurface: c.ink,
    surfaceContainerHighest: c.surfaceAlt,
    onSurfaceVariant: c.inkSoft,
    outline: c.line,
    outlineVariant: c.line.withValues(alpha: 0.5),
    shadow: c.ink.withValues(alpha: 0.12),
    scrim: c.ink.withValues(alpha: 0.28),
    inverseSurface: c.ink,
    onInverseSurface: c.bg,
    inversePrimary: c.accent,
  );

  return ThemeData(
    useMaterial3: true,
    colorScheme: colorScheme,
    scaffoldBackgroundColor: c.bg,
    canvasColor: c.bg,
    fontFamily: 'Nunito',
    textTheme: _textTheme(c, brightness),
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      surfaceTintColor: Colors.transparent,
      centerTitle: false,
      titleTextStyle: _textTheme(c, brightness).titleLarge,
      iconTheme: IconThemeData(color: c.ink, size: 24),
      actionsIconTheme: IconThemeData(color: c.ink, size: 24),
    ),
    cardTheme: CardThemeData(
      color: c.surface,
      elevation: 0,
      shadowColor: c.ink.withValues(alpha: 0.08),
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadii.card),
      ),
      margin: EdgeInsets.zero,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: c.accent,
        foregroundColor: c.bg,
        elevation: 0,
        shadowColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.pill),
        ),
        minimumSize: const Size(AppSpacing.minTouchTarget, 52),
        textStyle: _textTheme(
          c,
          brightness,
        ).labelLarge?.copyWith(fontWeight: FontWeight.w600, letterSpacing: 0.1),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: c.accent,
        foregroundColor: c.bg,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.pill),
        ),
        minimumSize: const Size(AppSpacing.minTouchTarget, 52),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: c.ink,
        side: BorderSide(color: c.line, width: 1.5),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.pill),
        ),
        minimumSize: const Size(AppSpacing.minTouchTarget, 52),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: c.accent,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.pill),
        ),
        minimumSize: const Size(AppSpacing.minTouchTarget, 44),
      ),
    ),
    iconButtonTheme: IconButtonThemeData(
      style: IconButton.styleFrom(
        foregroundColor: c.ink,
        backgroundColor: c.surface.withValues(alpha: 0.5),
        padding: const EdgeInsets.all(12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.gameGlass),
        ),
        minimumSize: const Size(44, 44),
      ),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: c.surfaceAlt,
      selectedColor: c.accent.withValues(alpha: 0.2),
      disabledColor: c.surfaceAlt.withValues(alpha: 0.5),
      labelStyle: _textTheme(c, brightness).labelLarge?.copyWith(color: c.ink),
      secondaryLabelStyle: _textTheme(
        c,
        brightness,
      ).labelLarge?.copyWith(color: c.bg),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadii.chip),
      ),
      side: BorderSide(color: c.line, width: 1),
      labelPadding: EdgeInsets.zero,
      elevation: 0,
      pressElevation: 0,
    ),
    sliderTheme: SliderThemeData(
      trackHeight: 4,
      thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 11),
      overlayShape: const RoundSliderOverlayShape(overlayRadius: 22),
      activeTrackColor: c.accent,
      inactiveTrackColor: c.line,
      thumbColor: c.accent,
      overlayColor: c.accent.withValues(alpha: 0.15),
      valueIndicatorColor: c.accent,
      valueIndicatorTextStyle: _textTheme(
        c,
        brightness,
      ).labelSmall?.copyWith(color: c.bg),
    ),
    dividerTheme: DividerThemeData(color: c.line, thickness: 1, space: 1),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: c.surface,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppRadii.sheet),
        ),
      ),
      modalBackgroundColor: c.surface,
      clipBehavior: Clip.antiAlias,
      constraints: const BoxConstraints(minWidth: double.infinity),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: c.surface,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadii.card),
      ),
      titleTextStyle: _textTheme(c, brightness).titleLarge,
      contentTextStyle: _textTheme(c, brightness).bodyMedium,
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: c.ink.withValues(alpha: 0.9),
      contentTextStyle: _textTheme(
        c,
        brightness,
      ).bodyMedium?.copyWith(color: c.bg),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadii.chip),
      ),
      elevation: 0,
    ),
    tabBarTheme: TabBarThemeData(
      labelColor: c.ink,
      unselectedLabelColor: c.inkSoft,
      indicatorColor: c.accent,
      indicatorSize: TabBarIndicatorSize.label,
      labelStyle: _textTheme(c, brightness).labelLarge,
      unselectedLabelStyle: _textTheme(c, brightness).labelLarge,
      dividerColor: Colors.transparent,
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: c.surface.withValues(alpha: 0.9),
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      indicatorColor: c.accent.withValues(alpha: 0.15),
      labelTextStyle: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return _textTheme(
            c,
            brightness,
          ).labelSmall?.copyWith(color: c.accent, fontWeight: FontWeight.w600);
        }
        return _textTheme(c, brightness).labelSmall?.copyWith(color: c.inkSoft);
      }),
      iconTheme: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return IconThemeData(color: c.accent, size: 24);
        }
        return IconThemeData(color: c.inkSoft, size: 24);
      }),
    ),
    progressIndicatorTheme: ProgressIndicatorThemeData(
      color: c.accent,
      linearTrackColor: c.line,
      circularTrackColor: c.line,
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) return c.accent;
        return c.inkSoft;
      }),
      trackColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return c.accent.withValues(alpha: 0.5);
        }
        return c.line;
      }),
      trackOutlineColor: WidgetStateProperty.resolveWith((states) => c.line),
    ),
    checkboxTheme: CheckboxThemeData(
      fillColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) return c.accent;
        return Colors.transparent;
      }),
      checkColor: WidgetStateProperty.all(c.bg),
      side: BorderSide(color: c.line, width: 2),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
    ),
    radioTheme: RadioThemeData(
      fillColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) return c.accent;
        return c.inkSoft;
      }),
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: c.accent,
      foregroundColor: c.bg,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadii.pill),
      ),
    ),
    popupMenuTheme: PopupMenuThemeData(
      color: c.surface,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadii.card),
      ),
      elevation: 0,
      textStyle: _textTheme(c, brightness).bodyMedium,
    ),
    tooltipTheme: TooltipThemeData(
      decoration: BoxDecoration(
        color: c.ink.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(AppRadii.chip),
      ),
      textStyle: _textTheme(c, brightness).labelSmall?.copyWith(color: c.bg),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    ),
    materialTapTargetSize: MaterialTapTargetSize.padded,
    visualDensity: VisualDensity.adaptivePlatformDensity,
  );
}

TextTheme _textTheme(ThemeColors c, Brightness brightness) {
  final baseColor = c.ink;
  final softColor = c.inkSoft;
  return TextTheme(
    displayLarge: TextStyle(
      fontFamily: 'Nunito',
      fontSize: 34,
      height: 40 / 34,
      fontWeight: FontWeight.w800,
      letterSpacing: -0.5,
      color: baseColor,
    ),
    displayMedium: TextStyle(
      fontFamily: 'Nunito',
      fontSize: 28,
      height: 36 / 28,
      fontWeight: FontWeight.w700,
      letterSpacing: -0.3,
      color: baseColor,
    ),
    displaySmall: TextStyle(
      fontFamily: 'Nunito',
      fontSize: 24,
      height: 32 / 24,
      fontWeight: FontWeight.w700,
      letterSpacing: -0.2,
      color: baseColor,
    ),
    headlineLarge: TextStyle(
      fontFamily: 'Nunito',
      fontSize: 22,
      height: 28 / 22,
      fontWeight: FontWeight.w700,
      letterSpacing: -0.2,
      color: baseColor,
    ),
    headlineMedium: TextStyle(
      fontFamily: 'Nunito',
      fontSize: 20,
      height: 26 / 20,
      fontWeight: FontWeight.w600,
      letterSpacing: 0,
      color: baseColor,
    ),
    headlineSmall: TextStyle(
      fontFamily: 'Nunito',
      fontSize: 18,
      height: 24 / 18,
      fontWeight: FontWeight.w600,
      letterSpacing: 0,
      color: baseColor,
    ),
    titleLarge: TextStyle(
      fontFamily: 'Nunito',
      fontSize: 24,
      height: 30 / 24,
      fontWeight: FontWeight.w700,
      letterSpacing: -0.2,
      color: baseColor,
    ),
    titleMedium: TextStyle(
      fontFamily: 'Nunito',
      fontSize: 18,
      height: 24 / 18,
      fontWeight: FontWeight.w600,
      letterSpacing: 0,
      color: baseColor,
    ),
    titleSmall: TextStyle(
      fontFamily: 'Nunito',
      fontSize: 16,
      height: 22 / 16,
      fontWeight: FontWeight.w600,
      letterSpacing: 0.1,
      color: baseColor,
    ),
    bodyLarge: TextStyle(
      fontFamily: 'Nunito',
      fontSize: 16,
      height: 24 / 16,
      fontWeight: FontWeight.w400,
      letterSpacing: 0,
      color: baseColor,
    ),
    bodyMedium: TextStyle(
      fontFamily: 'Nunito',
      fontSize: 14,
      height: 20 / 14,
      fontWeight: FontWeight.w400,
      letterSpacing: 0.1,
      color: baseColor,
    ),
    bodySmall: TextStyle(
      fontFamily: 'Nunito',
      fontSize: 12,
      height: 16 / 12,
      fontWeight: FontWeight.w500,
      letterSpacing: 0.2,
      color: softColor,
    ),
    labelLarge: TextStyle(
      fontFamily: 'Nunito',
      fontSize: 14,
      height: 20 / 14,
      fontWeight: FontWeight.w600,
      letterSpacing: 0.1,
      color: baseColor,
    ),
    labelMedium: TextStyle(
      fontFamily: 'Nunito',
      fontSize: 12,
      height: 16 / 12,
      fontWeight: FontWeight.w600,
      letterSpacing: 0.2,
      color: baseColor,
    ),
    labelSmall: TextStyle(
      fontFamily: 'Nunito',
      fontSize: 11,
      height: 14 / 11,
      fontWeight: FontWeight.w600,
      letterSpacing: 0.3,
      color: baseColor,
    ),
  );
}
