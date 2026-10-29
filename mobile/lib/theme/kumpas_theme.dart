import 'package:flutter/material.dart';

/// Tokens visuais do Kumpas — "mapa antigo / trilho".
abstract final class KumpasPalette {
  // Verdes de floresta
  static const forest = Color(0xFF1F5C2E);
  static const forestDark = Color(0xFF143D1F);
  static const forestLight = Color(0xFFE4EFE3);

  // Papel e tinta
  static const paper = Color(0xFFFAF6EE);
  static const paperDark = Color(0xFFF1EADC);
  static const ink = Color(0xFF22301F);
  static const muted = Color(0xFF6B7A66);
  static const line = Color(0xFFE3DED2);

  // Acento (XP, badges, recompensas)
  static const amber = Color(0xFFD9822B);
  static const amberSoft = Color(0xFFFBEBD7);
  static const amberDeep = Color(0xFF8A4B12);

  // Estados
  static const sky = Color(0xFF1565C0);
  static const danger = Color(0xFFC62828);

  // Mapa
  static const mapCanvas = Color(0xFFE8E4D8);
}

abstract final class KumpasRadius {
  static const card = 20.0;
  static const button = 14.0;
  static const pill = 999.0;
}

abstract final class KumpasTheme {
  static ThemeData light() {
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: KumpasPalette.forest,
        primary: KumpasPalette.forest,
        secondary: KumpasPalette.amber,
        surface: KumpasPalette.paper,
      ),
      scaffoldBackgroundColor: KumpasPalette.paper,
      fontFamily: 'Inter',
    );

    final text = base.textTheme
        .apply(
          fontFamily: 'Inter',
          bodyColor: KumpasPalette.ink,
          displayColor: KumpasPalette.ink,
        )
        .copyWith(
          displayLarge: _display(base, 34),
          displayMedium: _display(base, 28),
          headlineMedium: _display(base, 24),
          headlineSmall: _display(base, 20),
          titleLarge: _display(base, 20),
          titleMedium: base.textTheme.titleMedium?.copyWith(
            fontFamily: 'Inter',
            fontWeight: FontWeight.w600,
            color: KumpasPalette.ink,
          ),
        );

    return base.copyWith(
      textTheme: text,
      appBarTheme: const AppBarTheme(
        backgroundColor: KumpasPalette.forest,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          fontFamily: 'Fraunces',
          fontWeight: FontWeight.w600,
          fontSize: 21,
          color: Colors.white,
        ),
      ),
      cardTheme: const CardThemeData(
        color: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(KumpasRadius.card)),
          side: BorderSide(color: KumpasPalette.line),
        ),
      ),
      chipTheme: const ChipThemeData(
        backgroundColor: Colors.white,
        selectedColor: KumpasPalette.forestLight,
        side: BorderSide(color: KumpasPalette.line),
        shape: StadiumBorder(),
        labelStyle: TextStyle(
          fontFamily: 'Inter',
          fontWeight: FontWeight.w600,
          color: KumpasPalette.ink,
        ),
        secondaryLabelStyle: TextStyle(
          fontFamily: 'Inter',
          fontWeight: FontWeight.w700,
          color: KumpasPalette.forestDark,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: KumpasPalette.forest,
          foregroundColor: Colors.white,
          textStyle: const TextStyle(
            fontFamily: 'Inter',
            fontWeight: FontWeight.w600,
            fontSize: 15,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(KumpasRadius.button)),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: KumpasPalette.forestDark,
          side: const BorderSide(color: KumpasPalette.line),
          textStyle: const TextStyle(
            fontFamily: 'Inter',
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(KumpasRadius.button)),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: KumpasPalette.forest,
          textStyle: const TextStyle(
            fontFamily: 'Inter',
            fontWeight: FontWeight.w700,
            fontSize: 14,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        labelStyle: const TextStyle(color: KumpasPalette.muted),
        hintStyle: const TextStyle(color: KumpasPalette.muted),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(KumpasRadius.button),
          borderSide: const BorderSide(color: KumpasPalette.line),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(KumpasRadius.button),
          borderSide: const BorderSide(color: KumpasPalette.line),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(KumpasRadius.button),
          borderSide: const BorderSide(color: KumpasPalette.forest, width: 1.6),
        ),
      ),
      dividerTheme: const DividerThemeData(color: KumpasPalette.line, thickness: 1),
      snackBarTheme: const SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: KumpasPalette.forestDark,
        contentTextStyle: TextStyle(fontFamily: 'Inter', color: Colors.white),
      ),
      dialogTheme: const DialogThemeData(
        backgroundColor: KumpasPalette.paper,
        surfaceTintColor: Colors.transparent,
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: KumpasPalette.forest,
        linearTrackColor: KumpasPalette.paperDark,
      ),
    );
  }

  static TextStyle _display(ThemeData base, double size) => TextStyle(
        fontFamily: 'Fraunces',
        fontWeight: FontWeight.w600,
        fontSize: size,
        color: KumpasPalette.ink,
        height: 1.12,
      );
}
