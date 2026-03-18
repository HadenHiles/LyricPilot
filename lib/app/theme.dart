import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  AppTheme._();

  // Warm amber seed — evokes stage lighting and a musician's warmth.
  static const Color _seedColor = Color(0xFFE8A838);

  static ThemeData get darkTheme {
    final colorScheme = ColorScheme.fromSeed(seedColor: _seedColor, brightness: Brightness.dark);
    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      textTheme: GoogleFonts.interTextTheme(ThemeData(brightness: Brightness.dark).textTheme),
      appBarTheme: AppBarTheme(backgroundColor: colorScheme.surface, foregroundColor: colorScheme.onSurface, elevation: 0, scrolledUnderElevation: 1),
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: colorScheme.outlineVariant, width: 0.5),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(backgroundColor: colorScheme.primary, foregroundColor: colorScheme.onPrimary, elevation: 2),
      chipTheme: ChipThemeData(
        backgroundColor: colorScheme.surfaceContainerHighest,
        labelStyle: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 12),
        side: BorderSide.none,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      ),
    );
  }

  static ThemeData get lightTheme {
    final colorScheme = ColorScheme.fromSeed(seedColor: _seedColor, brightness: Brightness.light);
    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      textTheme: GoogleFonts.interTextTheme(ThemeData(brightness: Brightness.light).textTheme),
      appBarTheme: AppBarTheme(backgroundColor: colorScheme.surface, foregroundColor: colorScheme.onSurface, elevation: 0, scrolledUnderElevation: 1),
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: colorScheme.outlineVariant, width: 0.5),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(backgroundColor: colorScheme.primary, foregroundColor: colorScheme.onPrimary, elevation: 2),
      chipTheme: ChipThemeData(
        backgroundColor: colorScheme.surfaceContainerHighest,
        labelStyle: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 12),
        side: BorderSide.none,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      ),
    );
  }
}
