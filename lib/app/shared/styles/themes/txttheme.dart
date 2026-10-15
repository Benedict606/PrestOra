import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../colors.dart';

class TxtTheme {
  TxtTheme._();

  static TextTheme lighttxtTheme = _build(
    text: AppColors.tdLightText,
    muted: AppColors.tdLightTextMuted,
  );

  static TextTheme darktxtTheme = _build(
    text: AppColors.tdDarkText,
    muted: AppColors.tdDarkTextMuted,
  );

  static TextStyle _s(
    double size,
    FontWeight w,
    Color c, {
    double height = 1.4,
    double ls = 0,
  }) => GoogleFonts.plusJakartaSans(
    fontSize: size,
    fontWeight: w,
    color: c,
    height: height,
    letterSpacing: ls,
  );

  static TextTheme _build({required Color text, required Color muted}) {
    return TextTheme(
      // Titres de page (H1 « Create App Icons »)
      displayLarge: _s(36, FontWeight.w800, text, height: 1.1, ls: -0.5),
      // Titres de section (« Supported Platforms », « Everything you need… »)
      displayMedium: _s(30, FontWeight.w700, text, height: 1.2, ls: -0.3),
      // Titres des grandes cartes (« Upload Image »)
      displaySmall: _s(24, FontWeight.w700, text, height: 1.25),

      // Titres de carte (« Source Image », « Google Android », questions FAQ)
      headlineLarge: _s(20, FontWeight.w700, text, height: 1.3),
      // « Platform Selection », « Android launcher icon settings »
      headlineMedium: _s(18, FontWeight.w600, text, height: 1.35),
      headlineSmall: _s(16, FontWeight.w600, text, height: 1.4),

      // Titre d'AppBar (logo « AppIconGenerator »)
      titleLarge: _s(20, FontWeight.w700, text, height: 1.3),
      titleMedium: _s(16, FontWeight.w600, text),
      // « Background color », « Foreground scale »
      titleSmall: _s(14, FontWeight.w600, text),

      // Sous-titre d'en-tête (« Upload one image and generate… »)
      bodyLarge: _s(18, FontWeight.w400, muted, height: 1.55),
      // Texte courant, descriptions de cartes
      bodyMedium: _s(16, FontWeight.w400, text, height: 1.5),
      // Aides (« Support PNG, JPG… »), textes des cartes plateformes
      bodySmall: _s(14, FontWeight.w400, muted, height: 1.6),

      // Texte de bouton
      labelLarge: _s(16, FontWeight.w600, text, height: 1.25),
      // Pastille « Selected 2 platforms », libellés
      labelMedium: _s(14, FontWeight.w500, text, height: 1.3),
      // « QUICK PRESETS », « OR GENERATE WITH AI » (à passer en majuscules)
      labelSmall: _s(12, FontWeight.w600, muted, height: 1.3, ls: 1.5),
    );
  }

  // Styles monospace vus sur le site (eyebrow violet, code en ligne, numéros 01/02)
  static TextStyle eyebrow(Color color) => GoogleFonts.jetBrainsMono(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    letterSpacing: 2,
    color: color,
  );

  static TextStyle code(Color color) =>
      GoogleFonts.jetBrainsMono(fontSize: 14, color: color);
}
