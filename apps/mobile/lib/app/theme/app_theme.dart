import 'package:flutter/material.dart';
import 'package:inkstamp/app/theme/app_typography.dart';

abstract final class AppTheme {
  static ThemeData get light {
    const ColorScheme colorScheme = ColorScheme.light(
      primary: Color(0xFF020302),
      onPrimary: Color(0xFFFFFFFF),
      primaryContainer: Color(0xFF1D1D1B),
      onPrimaryContainer: Color(0xFF868582),
      secondary: Color(0xFF6E5A4B),
      secondaryContainer: Color(0xFFF9DDCA),
      onSecondaryContainer: Color(0xFF756051),
      tertiaryContainer: Color(0xFF1F1D19),
      onTertiaryContainer: Color(0xFF89847E),
      surface: Color(0xFFF9F9F6),
      surfaceContainerLow: Color(0xFFF4F4F1),
      surfaceContainer: Color(0xFFEEEEEB),
      surfaceContainerHigh: Color(0xFFE8E8E5),
      surfaceContainerHighest: Color(0xFFE2E3E0),
      onSurface: Color(0xFF1A1C1B),
      onSurfaceVariant: Color(0xFF464741),
      outline: Color(0xFF777771),
      outlineVariant: Color(0xFFC7C7BF),
      inverseSurface: Color(0xFF2F312F),
      onInverseSurface: Color(0xFFF1F1EE),
      inversePrimary: Color(0xFFC8C6C3),
      error: Color(0xFFB3261E),
      onError: Color(0xFFFFFFFF),
      errorContainer: Color(0xFFF9DEDC),
      onErrorContainer: Color(0xFF410E0B),
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: colorScheme.surface,
      fontFamily: AppTypography.fontFamily,
      textTheme: const TextTheme(
        displayLarge: AppTypography.display,
        headlineLarge: AppTypography.title,
        headlineMedium: AppTypography.heading,
        bodyLarge: AppTypography.body,
        bodyMedium: AppTypography.body,
        labelLarge: AppTypography.label,
      ),
      appBarTheme: AppBarTheme(
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: colorScheme.onSurface,
        titleTextStyle: AppTypography.heading.copyWith(
          color: colorScheme.onSurface,
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        height: 80,
        backgroundColor: colorScheme.surface,
        indicatorColor: Colors.transparent,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        labelTextStyle: WidgetStatePropertyAll(
          AppTypography.label.copyWith(color: colorScheme.onSurfaceVariant),
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          minimumSize: const Size.square(48),
          maximumSize: const Size.square(48),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        elevation: 0,
        focusElevation: 0,
        hoverElevation: 1,
        highlightElevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      dialogTheme: DialogThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colorScheme.surfaceContainerLow,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: colorScheme.outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: colorScheme.primary, width: 2),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: colorScheme.inverseSurface,
        contentTextStyle: TextStyle(color: colorScheme.onInverseSurface),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }
}
