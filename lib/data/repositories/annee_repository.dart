import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:prestora/data/firebase/fb.dart';
import 'package:prestora/data/models/annee.dart';

/// Années académiques + offre de cours par année.
///
/// L'unicité de l'année ACTIVE est garantie par le document pointeur
/// `parametres/annee_active`, modifié dans la même transaction/batch que
/// l'année (les règles Firestore vérifient la cohérence avec getAfter()).
class AnneeRepository {
  AnneeRepository._();
  static final AnneeRepository instance = AnneeRepository._();

  CollectionReference<Map<String, dynamic>> get _annees => Fb.col(Col.annees);
  CollectionReference<Map<String, dynamic>> get _offres => Fb.col(Col.offres);
  DocumentReference<Map<String, dynamic>> get _pointeur =>
      Fb.col(Col.parametres).doc('annee_active');

  // ───────────── Lecture ─────────────
  Stream<List<AnneeAcademique>> watchAnnees() => _annees.snapshots().map((s) {
    final l = s.docs.map((d) => AnneeAcademique.fromDoc(d.id, d.data())).toList()
      ..sort((a, b) => b.debut.compareTo(a.debut));
    return l;
  });

  Stream<List<OffreCours>> watchOffres(String anneeId) => _offres
      .where('annee_id', isEqualTo: anneeId)
      .snapshots()
      .map((s) {
        final l = s.docs.map((d) => OffreCours.fromDoc(d.id, d.data())).toList()
          ..sort((a, b) {
            final c = a.faculteNom.compareTo(b.faculteNom);
            if (c != 0) return c;
            final p = a.promotionNom.compareTo(b.promotionNom);
            return p != 0 ? p : a.code.compareTo(b.code);
          });
        return l;
      });

  Future<List<CoursCatalogue>> catalogue() async {
    final s = await Fb.col(Col.cours).get();
    final l = s.docs
        .where((d) => d.data()['est_archive'] != true)
        .map((d) => CoursCatalogue.fromDoc(d.id, d.data()))
        .toList()
      ..sort((a, b) => a.code.compareTo(b.code));
    return l;
  }

  // ───────────── Cycle de vie d'une année ─────────────

  /// Crée une année PLANIFIEE. Si [reprendreDe] est fourni, l'offre de cours
  /// (et les affectations de promotion) de cette année sont recopiées.
  Future<int> creer({
    required String libelle,
    required DateTime debut,
    required DateTime fin,
    String? reprendreDe,
  }) async {
    final l = libelle.trim();
    if (!RegExp(r'^\d{4}-\d{4}$').hasMatch(l)) {
      throw Exception('Le libellé doit avoir la forme 2027-2028.');
    }
    if (!fin.isAfter(debut)) {
      throw Exception('La date de fin doit suivre la date de début.');
    }
    final ref = _annees.doc(l);
    if ((await ref.get()).exists) {
      throw Exception("L'année $l existe déjà.");
    }
    await ref.set({
      'libelle': l,
      'date_debut': Fb.ts(debut),
      'date_fin': Fb.ts(fin),
      'statut': StatutAnnee.planifiee.code,
      'cree_le': FieldValue.serverTimestamp(),
    });
    if (reprendreDe == null) return 0;
    return reprendre(depuis: reprendreDe, vers: l);
  }

  /// Recopie l'offre de cours et les affectations d'une année vers une autre.
  /// Idempotent : les identifiants sont déterministes, on peut relancer.
  Future<int> reprendre({required String depuis, required String vers}) async {
    final src = await _offres.where('annee_id', isEqualTo: depuis).get();
    var n = 0;
    var batch = Fb.db.batch();
    var ops = 0;
    Future<void> flush() async {
      if (ops == 0) return;
      await batch.commit();
      batch = Fb.db.batch();
      ops = 0;
    }

    for (final d in src.docs) {
      final m = Map<String, dynamic>.from(d.data());
      final coursId = (m['cours_id'] as String?) ?? d.id;
      m['annee_id'] = vers;
      m['cree_le'] = FieldValue.serverTimestamp();
      batch.set(_offres.doc('${vers}_$coursId'), m);
      n++;
      if (++ops >= 400) await flush();
    }

    final aff = await Fb.col(
      Col.affectations,
    ).where('annee_id', isEqualTo: depuis).get();
    for (final d in aff.docs) {
      final m = Map<String, dynamic>.from(d.data());
      final promo = (m['promotion_id'] as String?) ?? '';
      m['annee_id'] = vers;
      batch.set(Fb.col(Col.affectations).doc('${vers}_$promo'), m);
      if (++ops >= 400) await flush();
    }
    await flush();
    return n;
  }

  /// PLANIFIEE → ACTIVE. Refuse s'il existe déjà une année active.
  Future<void> activer(String id) => Fb.db.runTransaction((tx) async {
    final ptr = await tx.get(_pointeur);
    final courant = ptr.data()?['annee_id'] as String?;
    if (courant != null && courant != id) {
      throw Exception(
        "L'année $courant est encore active. Clôturez-la avant d'en activer une autre.",
      );
    }
    final ref = _annees.doc(id);
    final a = await tx.get(ref);
    if (!a.exists) throw Exception('Année introuvable.');
    if (a.data()?['statut'] != StatutAnnee.planifiee.code) {
      throw Exception('Seule une année planifiée peut être activée.');
    }
    tx.update(ref, {
      'statut': StatutAnnee.active.code,
      'date_activation': FieldValue.serverTimestamp(),
    });
    tx.set(_pointeur, {'annee_id': id});
  });

  /// ACTIVE → CLOTUREE. L'année devient en lecture seule, définitivement.
  Future<void> cloturer(String id) async {
    final batch = Fb.db.batch();
    batch.update(_annees.doc(id), {
      'statut': StatutAnnee.cloturee.code,
      'date_cloture': FieldValue.serverTimestamp(),
    });
    batch.set(_pointeur, {'annee_id': null});
    await batch.commit();
  }

  /// Supprime une année PLANIFIEE avec son offre.
  Future<void> supprimer(String id) async {
    final offres = await _offres.where('annee_id', isEqualTo: id).get();
    final aff = await Fb.col(
      Col.affectations,
    ).where('annee_id', isEqualTo: id).get();
    final refs = [
      ...offres.docs.map((d) => d.reference),
      ...aff.docs.map((d) => d.reference),
    ];
    for (var i = 0; i < refs.length; i += 400) {
      final b = Fb.db.batch();
      for (final r in refs.skip(i).take(400)) {
        b.delete(r);
      }
      await b.commit();
    }
    await _annees.doc(id).delete();
  }

  // ───────────── Offre de cours ─────────────
  Future<void> ajouterOffres(String anneeId, List<CoursCatalogue> l) async {
    for (var i = 0; i < l.length; i += 400) {
      final b = Fb.db.batch();
      for (final c in l.skip(i).take(400)) {
        b.set(_offres.doc('${anneeId}_${c.id}'), {
          'annee_id': anneeId,
          'cours_id': c.id,
          'code': c.code,
          'intitule': c.intitule,
          'credits': c.credits,
          'volume': c.volume,
          'faculte_id': c.faculteId,
          'faculte_nom': c.faculteNom,
          'promotion_id': c.promotionId,
          'promotion_nom': c.promotionNom,
          'cree_le': FieldValue.serverTimestamp(),
        });
      }
      await b.commit();
    }
  }

  Future<void> changerVolume(OffreCours o, int volume) =>
      _offres.doc(o.id).update({'volume': volume});

  Future<void> retirerOffre(OffreCours o) => _offres.doc(o.id).delete();
}
