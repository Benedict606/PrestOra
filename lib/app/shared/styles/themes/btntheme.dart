import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../colors.dart';

class BtnTheme {
  BtnTheme._();

  static const double height = 44;
  static const double radius = 10;
  static const EdgeInsets padding = EdgeInsets.symmetric(
    horizontal: 20,
    vertical: 12,
  );

  static TextStyle get _label =>
      GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.w600);

  static RoundedRectangleBorder _shape([BorderSide side = BorderSide.none]) =>
      RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(radius),
        side: side,
      );

  // ───────── ButtonThemeData (boutons hérités, comme votre exemple) ─────────
  static ButtonThemeData lightbtnTheme() =>
      _legacy(AppColors.tdViolet, AppColors.tdLightTextMuted);

  static ButtonThemeData darkbtnTheme() =>
      _legacy(AppColors.tdVioletSoft, AppColors.tdDarkTextMuted);

  static ButtonThemeData _legacy(Color main, Color muted) => ButtonThemeData(
    buttonColor: main,
    disabledColor: muted.withValues(alpha: 0.2),
    focusColor: main,
    highlightColor: main.withValues(alpha: 0.12),
    hoverColor: Colors.transparent,
    splashColor: main.withValues(alpha: 0.12),
    minWidth: 64,
    height: height,
    shape: _shape(BorderSide(color: main)),
    textTheme: ButtonTextTheme.normal,
  );

  // ───────── Bouton plein violet (« Mobile App » sélectionné, « Adaptive + legacy ») ─────────
  static FilledButtonThemeData filled({
    required Color bg,
    required Color fg,
    required Color disabledBg,
    required Color disabledFg,
  }) => FilledButtonThemeData(
    style: FilledButton.styleFrom(
      backgroundColor: bg,
      foregroundColor: fg,
      disabledBackgroundColor: disabledBg,
      disabledForegroundColor: disabledFg,
      overlayColor: fg.withValues(alpha: 0.12),
      minimumSize: const Size(64, height),
      padding: padding,
      textStyle: _label,
      shape: _shape(),
      elevation: 0,
    ),
  );

  static ElevatedButtonThemeData elevated({
    required Color bg,
    required Color fg,
    required Color disabledBg,
    required Color disabledFg,
  }) => ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: bg,
      foregroundColor: fg,
      disabledBackgroundColor: disabledBg,
      disabledForegroundColor: disabledFg,
      overlayColor: fg.withValues(alpha: 0.12),
      minimumSize: const Size(64, height),
      padding: padding,
      textStyle: _label,
      shape: _shape(),
      elevation: 0,
      shadowColor: Colors.transparent,
    ),
  );

  // ───────── Bouton secondaire à bordure (« Web App », « Generate Icon ») ─────────
  static OutlinedButtonThemeData outlined({
    required Color bg,
    required Color fg,
    required Color border,
    required Color disabledFg,
  }) => OutlinedButtonThemeData(
    style: OutlinedButton.styleFrom(
      backgroundColor: bg,
      foregroundColor: fg,
      disabledForegroundColor: disabledFg,
      side: BorderSide(color: border, width: 1),
      overlayColor: fg.withValues(alpha: 0.08),
      minimumSize: const Size(64, height),
      padding: padding,
      textStyle: _label,
      shape: _shape(),
    ),
  );

  // ───────── Bouton texte ─────────
  static TextButtonThemeData text({
    required Color fg,
    required Color disabledFg,
  }) => TextButtonThemeData(
    style: TextButton.styleFrom(
      foregroundColor: fg,
      disabledForegroundColor: disabledFg,
      overlayColor: fg.withValues(alpha: 0.1),
      minimumSize: const Size(64, height),
      padding: padding,
      textStyle: _label,
      shape: _shape(),
    ),
  );

  // ───────── Bouton icône carré à bordure (menu hamburger de l'en-tête) ─────────
  static IconButtonThemeData icon({required Color fg, required Color border}) =>
      IconButtonThemeData(
        style: IconButton.styleFrom(
          foregroundColor: fg,
          side: BorderSide(color: border, width: 1),
          minimumSize: const Size(height, height),
          fixedSize: const Size(height, height),
          shape: _shape(),
        ),
      );
}
