import 'package:flutter/material.dart';

abstract final class AppTheme {
  static const primary = Color(0xFFFFD54F);
  static const accent = Color(0xFFFFB300);
  static const amber = Color(0xFFD97706);
  static const hover = Color(0xFFFFF9C4);
  static const ink = Color(0xFF111B21);
  static const muted = Color(0xFF667781);
  static const canvas = Color(0xFFFFFFFF);
  static const chatCanvas = Color(0xFFEFE7DD);
  static const sentBubble = Color(0xFFFFF3B0);

  static ThemeData get light => _theme(Brightness.light);
  static ThemeData get dark => _theme(Brightness.dark);

  static ThemeData _theme(Brightness brightness) {
    final dark = brightness == Brightness.dark;
    final scheme = ColorScheme.fromSeed(
      seedColor: primary,
      brightness: brightness,
      surface: dark ? const Color(0xFF11182B) : Colors.white,
    );
    final outline = dark ? const Color(0xFF373340) : const Color(0xFFE5E2EC);

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: dark ? const Color(0xFF111B21) : canvas,
      fontFamily: 'sans-serif',
      textTheme: ThemeData(brightness: brightness).textTheme.apply(
            bodyColor: dark ? const Color(0xFFF3F0F8) : ink,
            displayColor: dark ? const Color(0xFFF3F0F8) : ink,
          ),
      appBarTheme: AppBarTheme(
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: dark ? const Color(0xFF202C33) : primary,
        foregroundColor: dark ? Colors.white : ink,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: dark ? const Color(0xFF211E2A) : Colors.white,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 18, vertical: 17),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: outline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: primary, width: 1.6),
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: dark ? const Color(0xFF121C33) : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
          side: BorderSide(color: outline),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        height: 72,
        elevation: 0,
        backgroundColor: dark ? const Color(0xFF17151F) : Colors.white,
        indicatorColor: dark ? const Color(0xFF5B4C18) : const Color(0xFFFEF08A),
        iconTheme: WidgetStateProperty.resolveWith((states) => IconThemeData(
            color: states.contains(WidgetState.selected)
                ? ink
                : (dark ? Colors.white70 : muted))),
        labelTextStyle: WidgetStateProperty.resolveWith((states) => TextStyle(
              fontSize: 12,
              fontWeight: states.contains(WidgetState.selected)
                  ? FontWeight.w700
                  : FontWeight.w500,
            )),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(54),
          textStyle: const TextStyle(fontWeight: FontWeight.w700),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }
}
