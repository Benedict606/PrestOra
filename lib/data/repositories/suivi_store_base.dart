import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:prestora/data/firebase/fb.dart';
import 'package:prestora/data/repositories/suivi_hub.dart';
import 'package:prestora/data/services/session.dart';

/// Base des dépôts de suivi (chef de promotion, encadreur, enseignant).
/// Écoute la session : dès que l'année active ou l'utilisateur change, la
/// requête Firestore est relancée.
abstract class SuiviStoreBase extends ChangeNotifier {
  late final SuiviHub hub = SuiviHub(onChange: onHubChange);

  String? _cle;
  bool _started = false;

  /// Requête des sessions de l'année pour cet utilisateur.
  Query<Map<String, dynamic>>? requete(String anneeId, String uid);

  /// Appelé quand la session ou l'année change (charger des données annexes).
  @protected
  void onSessionChange(String? anneeId) {}

  /// Appelé après chaque mise à jour du hub (recalculer les vues dérivées).
  @protected
  void rebuild() {}

  Query<Map<String, dynamic>> sessionsQuery(String anneeId) => Fb.db
      .collection(Col.sessions)
      .where('annee_id', isEqualTo: anneeId);

  void onHubChange() {
    rebuild();
    notifyListeners();
  }

  void start() {
    if (_started) return;
    _started = true;
    Session.instance.addListener(_sync);
    _sync();
  }

  void stop() {
    if (!_started) return;
    _started = false;
    Session.instance.removeListener(_sync);
    _cle = null;
    hub.stop();
    onSessionChange(null);
  }

  void _sync() {
    final annee = Session.instance.active?.id;
    final uid = Session.instance.me?.id;
    final cle = '$annee|$uid';
    if (cle == _cle) return;
    _cle = cle;
    onSessionChange(annee);
    if (annee == null || uid == null) {
      hub.stop();
      return;
    }
    final q = requete(annee, uid);
    if (q == null) {
      hub.stop();
      return;
    }
    hub.watch(q);
  }
}
