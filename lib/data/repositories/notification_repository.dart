import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:prestora/data/firebase/fb.dart';

class AppNotif {
  AppNotif({
    required this.id,
    required this.titre,
    required this.message,
    required this.type,
    required this.lu,
    required this.date,
  });

  final String id;
  final String titre;
  final String message;
  final String type; // SEANCE, COURS, DOSSIER, REJET, PAIEMENT
  final bool lu;
  final DateTime date;

  factory AppNotif.fromDoc(String id, Map<String, dynamic> m) => AppNotif(
    id: id,
    titre: (m['titre'] as String?) ?? '',
    message: (m['message'] as String?) ?? '',
    type: (m['type'] as String?) ?? '',
    lu: m['lu'] == true,
    date: Fb.date(m['date']) ?? DateTime.now(),
  );
}

/// Notifications de l'utilisateur connecté (collection `notifications`).
class NotificationStore extends ChangeNotifier {
  List<AppNotif> liste = [];
  StreamSubscription<dynamic>? _sub;
  String? _uid;

  int get nonLues => liste.where((n) => !n.lu).length;

  void start(String uid) {
    if (_uid == uid) return;
    stop();
    _uid = uid;
    _sub = Fb.db
        .collection(Col.notifications)
        .where('destinataire_id', isEqualTo: uid)
        .snapshots()
        .listen((s) {
          liste = [for (final d in s.docs) AppNotif.fromDoc(d.id, d.data())]
            ..sort((a, b) => b.date.compareTo(a.date));
          if (liste.length > 60) liste = liste.sublist(0, 60);
          notifyListeners();
        }, onError: (Object e) => debugPrint('notifications: $e'));
  }

  void stop() {
    _sub?.cancel();
    _sub = null;
    _uid = null;
    liste = [];
    notifyListeners();
  }

  Future<void> lire(AppNotif n) async {
    if (n.lu) return;
    try {
      await Fb.db.collection(Col.notifications).doc(n.id).update({'lu': true});
    } catch (e) {
      debugPrint('lire: $e');
    }
  }

  Future<void> toutLire() async {
    final non = liste.where((n) => !n.lu).toList();
    if (non.isEmpty) return;
    try {
      final b = Fb.db.batch();
      for (final n in non) {
        b.update(Fb.db.collection(Col.notifications).doc(n.id), {'lu': true});
      }
      await b.commit();
    } catch (e) {
      debugPrint('toutLire: $e');
    }
  }
}

final NotificationStore notificationStore = NotificationStore();

/// Envoi de notifications (écriture Firestore ; jamais bloquant pour l'action).
class Notifier {
  /// Identifiants des utilisateurs actifs d'un rôle (et d'une faculté).
  static Future<List<String>> parRole(String code, {String? faculteId}) async {
    try {
      Query<Map<String, dynamic>> q = Fb.db
          .collection(Col.utilisateurs)
          .where('type_utilisateur', isEqualTo: code)
          .where('est_actif', isEqualTo: true);
      if (faculteId != null) q = q.where('faculte_id', isEqualTo: faculteId);
      final s = await q.get();
      return s.docs.map((d) => d.id).toList();
    } catch (e) {
      debugPrint('parRole($code): $e');
      return [];
    }
  }

  static Future<void> envoyer(
    Iterable<String> destinataires, {
    required String type,
    required String titre,
    required String message,
    String? cible,
  }) async {
    final moi = Fb.auth.currentUser?.uid;
    final ids = destinataires.where((u) => u.isNotEmpty && u != moi).toSet();
    if (moi == null || ids.isEmpty) return;
    try {
      final b = Fb.db.batch();
      for (final u in ids) {
        b.set(Fb.db.collection(Col.notifications).doc(), {
          'destinataire_id': u,
          'expediteur_id': moi,
          'type': type,
          'titre': titre,
          'message': message,
          'cible': cible,
          'lu': false,
          'date': FieldValue.serverTimestamp(),
        });
      }
      await b.commit();
    } catch (e) {
      debugPrint('notification: $e');
    }
  }

  static Future<void> auRole(
    String code, {
    String? faculteId,
    required String type,
    required String titre,
    required String message,
    String? cible,
  }) async => envoyer(
    await parRole(code, faculteId: faculteId),
    type: type,
    titre: titre,
    message: message,
    cible: cible,
  );
}
