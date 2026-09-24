import 'package:flutter/material.dart';

/// Paleta de la marca del proyecto (la misma usada en las otras piezas
/// del proyecto de título: teal como color principal, coral como acento
/// de riesgo/alerta).
class CafColors {
  static const accent = Color(0xFF1B6E68);
  static const accentStrong = Color(0xFF114C48);
  static const accentTint = Color(0xFFDCEAE7);
  static const coral = Color(0xFFC94F20);
  static const coralStrong = Color(0xFF96380F);
  static const coralTint = Color(0xFFFBE3D6);
  static const warn = Color(0xFF92620A);
  static const warnTint = Color(0xFFFBEDCF);
  static const paper = Color(0xFFEFF2F0);
}

ThemeData buildCafTheme() {
  final colorScheme = ColorScheme.fromSeed(
    seedColor: CafColors.accent,
    primary: CafColors.accent,
    brightness: Brightness.light,
  );

  return ThemeData(
    useMaterial3: true,
    colorScheme: colorScheme,
    scaffoldBackgroundColor: CafColors.paper,
    fontFamily: 'Roboto',
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.white,
      foregroundColor: Color(0xFF16211D),
      elevation: 0,
      scrolledUnderElevation: 1,
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.black.withOpacity(.08)),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: CafColors.accent,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: Colors.black.withOpacity(.15)),
      ),
    ),
  );
}
