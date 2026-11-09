import 'package:flutter/material.dart';

/// Clé globale du ScaffoldMessenger : permet d'afficher un message depuis
/// n'importe où (dépôts, services) sans BuildContext.
final GlobalKey<ScaffoldMessengerState> rootMessengerKey =
    GlobalKey<ScaffoldMessengerState>();

class Notif {
  static void info(String message) => _show(message, error: false);
  static void erreur(Object e) => _show(humaniser(e), error: true);

  static void _show(String message, {required bool error}) {
    final m = rootMessengerKey.currentState;
    if (m == null) return;
    m
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: error ? const Color(0xFFD2544A) : null,
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  /// Message lisible pour l'utilisateur à partir d'une exception quelconque.
  static String humaniser(Object e) {
    final s = e.toString();
    if (s.contains('permission-denied')) {
      return "Action refusée par les règles de sécurité (droits insuffisants "
          "ou année non active).";
    }
    if (s.contains('unavailable') || s.contains('network')) {
      return 'Réseau indisponible. Réessayez.';
    }
    return s.replaceFirst('Exception: ', '');
  }
}

/// Identifiant lisible sans accents ni espaces (clé de document).
String slug(String s) {
  const from = 'àâäáãåçéèêëíìîïñóòôöõúùûüýÿœæ';
  const to = 'aaaaaaceeeeiiiinooooouuuuyyoa';
  final b = StringBuffer();
  for (final ch in s.toLowerCase().runes) {
    final c = String.fromCharCode(ch);
    final i = from.indexOf(c);
    b.write(i >= 0 ? to[i] : c);
  }
  return b
      .toString()
      .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
      .replaceAll(RegExp(r'^_+|_+$'), '');
}
