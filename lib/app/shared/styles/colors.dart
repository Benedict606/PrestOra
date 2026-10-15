import 'package:flutter/material.dart';

/// Palette extraite des captures d'AppIconGenerator (mode clair + mode sombre).
class AppColors {
  AppColors._();

  // ───────────── COMMUN ─────────────
  static const Color tdWhite = Color(
    0xFFFFFFFF,
  ); // texte sur violet, pastille couleur

  // ───────────── VIOLET (couleur de marque) ─────────────
  static const Color tdViolet = Color(
    0xFF7B3AED,
  ); // clair : boutons, eyebrow, icônes, curseur
  static const Color tdVioletSoft = Color(
    0xFFA58AF9,
  ); // sombre : boutons, icônes, puces, curseur
  static const Color tdVioletDeep = Color(
    0xFF12003C,
  ); // sombre : texte sur bouton violet clair
  static const Color tdVioletTint = Color(
    0xFFF0EAFC,
  ); // clair : fond icône d'upload, pastille « Selected »
  static const Color tdVioletTintAlt = Color(
    0xFFEAE7F9,
  ); // clair : cercle d'icône des 3 étapes
  static const Color tdVioletTintDark = Color(
    0xFF241E33,
  ); // sombre : fond icône, pastille « Selected »

  // ───────────── MODE CLAIR : surfaces ─────────────
  static const Color tdLightPage = Color(
    0xFFFAFAFC,
  ); // fond de page, boutons secondaires
  static const Color tdLightCard = Color(
    0xFFFFFFFF,
  ); // cartes, zone de dépôt, sélecteurs
  static const Color tdLightBorder = Color(
    0xFFE4E3E8,
  ); // bordures des cartes et boutons

  // ───────────── MODE CLAIR : textes ─────────────
  static const Color tdLightText = Color(0xFF0F0F15); // titres, texte principal
  static const Color tdLightTextMuted = Color(
    0xFF58575F,
  ); // sous-titres, descriptions, libellés

  // ───────────── MODE SOMBRE : surfaces ─────────────
  static const Color tdDarkPage = Color(0xFF09090F); // fond de page
  static const Color tdDarkCard = Color(
    0xFF15121E,
  ); // cartes, zone de dépôt, panneaux
  static const Color tdDarkSurfaceAlt = Color(
    0xFF1E1B2D,
  ); // boutons secondaires, « Generate Icon »
  static const Color tdDarkCode = Color(
    0xFF1B1824,
  ); // fond du code en ligne (Contents.json)
  static const Color tdDarkBorder = Color(0xFF272532); // bordures des cartes

  // ───────────── MODE SOMBRE : textes ─────────────
  static const Color tdDarkText = Color(0xFFFFFFFF); // titres, texte principal
  static const Color tdDarkTextMuted = Color(
    0xFFA9A7B5,
  ); // sous-titres, descriptions, libellés

  // ───────────── HORS CAPTURES (obligatoire pour Flutter) ─────────────
  // Aucun rouge n'apparaît sur les images ; ColorScheme exige pourtant une couleur d'erreur.
  // J'ai repris le tdRed de votre exemple (utile pour les rejets de dossiers).
  static const Color tdError = Color(0xFFD2544A);
}
