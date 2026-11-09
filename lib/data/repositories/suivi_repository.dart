import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:prestora/app/view/prestation/student/etudiant_data.dart';
import 'package:prestora/core/notify.dart';
import 'package:prestora/data/firebase/fb.dart';
import 'package:prestora/data/repositories/notification_repository.dart';

/// Écritures du suivi : sessions (affectation d'un cours à un enseignant)
/// et séances. Les règles Firestore décident qui peut faire quoi.
class SuiviRepository {
  SuiviRepository._();
  static final SuiviRepository instance = SuiviRepository._();

  DocumentReference<Map<String, dynamic>> _session(String id) =>
      Fb.db.collection(Col.sessions).doc(id);

  CollectionReference<Map<String, dynamic>> _seances(String sessionId) =>
      _session(sessionId).collection(Col.seances);

  Future<bool> _w(Future<dynamic> Function() f) async {
    try {
      await f();
      return true;
    } catch (e) {
      Notif.erreur(e);
      return false;
    }
  }

  // ───────────── Sessions (encadreur) ─────────────
  /// Affecte un cours de l'offre à un enseignant. Une seule session par cours
  /// et par année (identifiant déterministe).
  Future<bool> creerSession({
    required String anneeId,
    required String coursId,
    required String code,
    required String intitule,
    required int credits,
    required int volume,
    required String faculteId,
    required String promotionId,
    required String promotionNom,
    required String encadreurId,
    required String enseignantId,
    required String enseignantNom,
    required String grade,
    String? chefId,
    String? chefNom,
  }) async {
    final ok = await _w(
    () => _session('${anneeId}_$coursId').set({
      'annee_id': anneeId,
      'cours_id': coursId,
      'code': code,
      'intitule': intitule,
      'credits': credits,
      'volume': volume,
      'faculte_id': faculteId,
      'promotion_id': promotionId,
      'promotion_nom': promotionNom,
      'encadreur_id': encadreurId,
      'enseignant_id': enseignantId,
      'enseignant_nom': enseignantNom,
      'grade': grade,
      'chef_promo_id': chefId,
      'chef_promo_nom': chefNom,
      'est_cloturee': false,
      'statut_session': 'EN_COURS',
      'cree_le': FieldValue.serverTimestamp(),
    }),
    );
    if (ok) {
      Notifier.envoyer(
        [enseignantId],
        type: 'COURS',
        titre: 'Nouveau cours affecté',
        message: '$code · $intitule ($promotionNom) vous a été affecté.',
        cible: '${anneeId}_$coursId',
      );
    }
    return ok;
  }

  Future<bool> cloturerSession(CoursSuivi c) async {
    final ok = await _w(
      () => _session(c.id).update({
        'est_cloturee': true,
        'statut_session': 'CLOTURE',
      }),
    );
    if (ok) {
      Notifier.auRole(
        'SECRETAIRE',
        faculteId: c.faculteId,
        type: 'COURS',
        titre: 'Cours à initialiser',
        message: '${c.code} · ${c.intitule} est clôturé : le dossier de paie peut être initialisé.',
        cible: c.id,
      );
      Notifier.envoyer(
        [c.enseignantId],
        type: 'COURS',
        titre: 'Cours clôturé',
        message: '${c.code} · ${c.intitule} a été clôturé par l\'encadreur.',
        cible: c.id,
      );
    }
    return ok;
  }

  // ───────────── Séances ─────────────
  Map<String, dynamic> _champs(Seance s) => {
    'date': Timestamp.fromDate(DateTime(s.date.year, s.date.month, s.date.day)),
    'debut': minutesOf(s.debut),
    'fin': minutesOf(s.fin),
    'nbre_heures': s.heures,
    'type_seance': s.type.label,
    'chapitre': s.chapitre,
    'preuve_nom': s.preuve,
    'preuve_id': s.preuveId,
  };

  Future<bool> ajouterSeance(CoursSuivi c, Seance s) async {
    final ok = await _w(() {
      final uid = Fb.auth.currentUser?.uid;
      return _seances(c.id).add({
        ..._champs(s),
        'valide_par_prof': false,
        'encode_par_id': uid,
        'cree_le': FieldValue.serverTimestamp(),
      });
    });
    if (ok) {
      Notifier.envoyer(
        [c.enseignantId],
        type: 'SEANCE',
        titre: 'Séance à valider',
        message: '${c.code} : une séance de ${s.heures.toStringAsFixed(1)} h attend votre validation.',
        cible: c.id,
      );
    }
    return ok;
  }

  Future<bool> modifierSeance(CoursSuivi c, Seance s) =>
      _w(() => _seances(c.id).doc(s.id).update(_champs(s)));

  Future<bool> supprimerSeance(CoursSuivi c, Seance s) =>
      _w(() => _seances(c.id).doc(s.id).delete());

  /// L'enseignant valide (ou retire sa validation d') une séance.
  Future<bool> validerSeance(CoursSuivi c, Seance s, bool valide) => _w(
    () => _seances(c.id).doc(s.id).update({'valide_par_prof': valide}),
  );

  Future<bool> toutValider(CoursSuivi c) => _w(() async {
    final b = Fb.db.batch();
    for (final s in c.seances.where((s) => !s.validee)) {
      b.update(_seances(c.id).doc(s.id), {'valide_par_prof': true});
    }
    await b.commit();
  });
}
