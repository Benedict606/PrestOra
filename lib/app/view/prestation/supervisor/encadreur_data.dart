import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:prestora/app/view/prestation/student/etudiant_data.dart';
import 'package:prestora/core/notify.dart';
import 'package:prestora/data/firebase/fb.dart';
import 'package:prestora/data/repositories/suivi_repository.dart';
import 'package:prestora/data/repositories/suivi_store_base.dart';
import 'package:prestora/data/services/session.dart';

// ═══════════════════════════════════════════════════════════════
//  Espace Encadreur : promotions de sa faculté, cours de l'offre de
//  l'année active, affectation d'un enseignant, clôture du cours.
// ═══════════════════════════════════════════════════════════════

enum StatutEnc {
  nonAffecte('Non affecté'),
  enCours('En cours'),
  valideParEnseignant("Validé par l'enseignant"),
  cloture('Clôturé');

  const StatutEnc(this.label);
  final String label;
}

class CoursEnc {
  CoursEnc({
    required this.code,
    required this.intitule,
    required this.credits,
    required this.volume,
    this.suivi,
    this.offreId = '',
    this.coursId = '',
    this.promotionId = '',
    this.promotionNom = '',
    this.faculteId = '',
  });

  String code;
  String intitule;
  int credits;
  int volume;
  CoursSuivi? suivi; // session de suivi (enseignant + séances)
  String offreId;
  String coursId;
  String promotionId;
  String promotionNom;
  String faculteId;

  StatutEnc get statut {
    final s = suivi;
    if (s == null) return StatutEnc.nonAffecte;
    return switch (s.statut) {
      StatutCours.enCours => StatutEnc.enCours,
      StatutCours.valideParEnseignant => StatutEnc.valideParEnseignant,
      StatutCours.cloture => StatutEnc.cloture,
    };
  }
}

class PromotionEnc {
  PromotionEnc({
    this.id = '',
    required this.nom,
    required this.departement,
    required this.cours,
    this.chef,
    this.chefId,
  });

  final String id;
  String nom;
  String departement;
  String? chef; // chef de promotion (nom)
  String? chefId;
  final List<CoursEnc> cours;

  int get nonSuivis => cours.where((c) => c.suivi == null).length;
  int get aCloturer =>
      cours.where((c) => c.statut == StatutEnc.valideParEnseignant).length;
}

class EnseignantFictif {
  const EnseignantFictif(this.nom, this.email, this.grade, {this.uid = ''});
  final String nom;
  final String email;
  final String grade;
  final String uid;
}

class EncadreurStore extends SuiviStoreBase {
  String get nom => Session.instance.me?.nomComplet ?? '';
  String get faculte => Session.instance.faculteNom ?? '';
  String get anneeAcademique => Session.instance.active?.libelle ?? '—';

  String get initiale {
    final n = Session.instance.me?.nom ?? '';
    return n.isEmpty ? '?' : n.substring(0, 1).toUpperCase();
  }

  final List<EnseignantFictif> enseignants = [];
  final List<PromotionEnc> promotions = [];

  // Données brutes
  Map<String, Map<String, dynamic>> _rPromo = {};
  Map<String, Map<String, dynamic>> _rDept = {};
  Map<String, Map<String, dynamic>> _rOffres = {};
  List<Map<String, dynamic>> _rChefs = [];
  final Map<String, PromotionEnc> _pObj = {};
  final Map<String, CoursEnc> _cObj = {};
  final List<StreamSubscription<dynamic>> _subs = [];

  @override
  Query<Map<String, dynamic>>? requete(String anneeId, String uid) {
    final fac = Session.instance.me?.faculteId;
    if (fac == null) return null;
    return sessionsQuery(anneeId).where('faculte_id', isEqualTo: fac);
  }

  void _cancel() {
    for (final s in _subs) {
      s.cancel();
    }
    _subs.clear();
  }

  void _ecoute(
    Query<Map<String, dynamic>> q,
    void Function(QuerySnapshot<Map<String, dynamic>>) f,
  ) {
    _subs.add(
      q.snapshots().listen((s) {
        f(s);
        onHubChange();
      }, onError: (Object e) => Notif.erreur('Lecture : $e')),
    );
  }

  @override
  void onSessionChange(String? anneeId) {
    _cancel();
    final fac = Session.instance.me?.faculteId;
    if (anneeId == null || fac == null) {
      _rPromo = {};
      _rDept = {};
      _rOffres = {};
      _rChefs = [];
      enseignants.clear();
      promotions.clear();
      return;
    }
    final db = Fb.db;
    _ecoute(
      db.collection(Col.promotions).where('faculte_id', isEqualTo: fac),
      (s) => _rPromo = {for (final d in s.docs) d.id: d.data()},
    );
    _ecoute(
      db.collection(Col.departements).where('faculte_id', isEqualTo: fac),
      (s) => _rDept = {for (final d in s.docs) d.id: d.data()},
    );
    _ecoute(
      db
          .collection(Col.offres)
          .where('annee_id', isEqualTo: anneeId)
          .where('faculte_id', isEqualTo: fac),
      (s) => _rOffres = {for (final d in s.docs) d.id: d.data()},
    );
    _ecoute(
      db
          .collection(Col.utilisateurs)
          .where('type_utilisateur', isEqualTo: 'CHEF_PROMOTION'),
      (s) => _rChefs = [
        for (final d in s.docs)
          if (d.data()['est_actif'] == true) {...d.data(), '_id': d.id},
      ],
    );
    _ecoute(
      db
          .collection(Col.utilisateurs)
          .where('type_utilisateur', isEqualTo: 'ENSEIGNANT'),
      (s) {
        enseignants
          ..clear()
          ..addAll(
            s.docs.where((d) => d.data()['est_actif'] == true).map((d) {
              final m = d.data();
              final titre = (m['titre'] as String?) ?? '';
              final nom = (m['nom'] as String?) ?? '';
              return EnseignantFictif(
                titre.isEmpty ? nom : '$titre $nom',
                (m['email'] as String?) ?? '',
                (m['grade_statutaire'] as String?) ?? '',
                uid: d.id,
              );
            }),
          );
        enseignants.sort((a, b) => a.nom.compareTo(b.nom));
      },
    );
  }

  @override
  void rebuild() {
    _pObj.removeWhere((id, _) => !_rPromo.containsKey(id));
    final offreIds = _rOffres.keys.toSet();
    _cObj.removeWhere((id, _) => !offreIds.contains(id));

    for (final e in _rPromo.entries) {
      final p = _pObj.putIfAbsent(
        e.key,
        () => PromotionEnc(id: e.key, nom: '', departement: '', cours: []),
      );
      p.nom = (e.value['nom'] as String?) ?? '';
      p.departement =
          (_rDept[e.value['departement_id']]?['nom'] as String?) ?? '';
      final chef = _rChefs
          .where((c) => c['promotion_id'] == e.key)
          .firstOrNull;
      p.chef = chef?['nom'] as String?;
      p.chefId = chef?['_id'] as String?;
      p.cours.clear();
    }

    final offres = _rOffres.entries.toList()
      ..sort(
        (a, b) => ((a.value['code'] as String?) ?? '').compareTo(
          (b.value['code'] as String?) ?? '',
        ),
      );
    for (final o in offres) {
      final m = o.value;
      final p = _pObj[m['promotion_id']];
      if (p == null) continue;
      final c = _cObj.putIfAbsent(
        o.key,
        () => CoursEnc(code: '', intitule: '', credits: 0, volume: 0),
      );
      c
        ..code = (m['code'] as String?) ?? ''
        ..intitule = (m['intitule'] as String?) ?? ''
        ..credits = (m['credits'] as num?)?.toInt() ?? 0
        ..volume = (m['volume'] as num?)?.toInt() ?? 0
        ..offreId = o.key
        ..coursId = (m['cours_id'] as String?) ?? ''
        ..promotionId = p.id
        ..promotionNom = p.nom
        ..faculteId = (m['faculte_id'] as String?) ?? ''
        ..suivi = hub.parCours((m['cours_id'] as String?) ?? '');
      p.cours.add(c);
    }

    promotions
      ..clear()
      ..addAll(_pObj.values.toList()..sort((a, b) => a.nom.compareTo(b.nom)));
  }

  // ── Compteurs ──
  int get nbANonAffectes => promotions.fold(0, (s, p) => s + p.nonSuivis);
  int get nbACloturer => promotions.fold(0, (s, p) => s + p.aCloturer);

  // ── Actions ──
  Future<bool> affecter(CoursEnc c, EnseignantFictif e) {
    final annee = Session.instance.active;
    final me = Session.instance.me;
    if (annee == null || me == null) {
      Notif.info("Aucune année active : impossible d'affecter.");
      return Future.value(false);
    }
    final chef = promotions.where((p) => p.id == c.promotionId).firstOrNull;
    return SuiviRepository.instance.creerSession(
      anneeId: annee.id,
      coursId: c.coursId,
      code: c.code,
      intitule: c.intitule,
      credits: c.credits,
      volume: c.volume,
      faculteId: c.faculteId,
      promotionId: c.promotionId,
      promotionNom: c.promotionNom,
      encadreurId: me.id,
      enseignantId: e.uid,
      enseignantNom: e.nom,
      grade: e.grade,
      chefId: chef?.chefId,
      chefNom: chef?.chef,
    );
  }

  Future<bool> cloturer(CoursEnc c) {
    final s = c.suivi;
    if (s == null) return Future.value(false);
    return SuiviRepository.instance.cloturerSession(s);
  }

  Future<bool> deleteSeance(CoursEnc c, Seance s) {
    final suivi = c.suivi;
    if (suivi == null) return Future.value(false);
    return SuiviRepository.instance.supprimerSeance(suivi, s);
  }

  Future<bool> saveSeance(CoursEnc c, Seance s) {
    final suivi = c.suivi;
    if (suivi == null) return Future.value(false);
    return SuiviRepository.instance.modifierSeance(suivi, s);
  }

  @override
  void stop() {
    _cancel();
    super.stop();
  }
}

final EncadreurStore encadreurStore = EncadreurStore();
