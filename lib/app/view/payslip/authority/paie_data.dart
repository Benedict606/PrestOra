import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:prestora/app/view/prestation/student/etudiant_data.dart';
import 'package:prestora/app/view/teacher/enseignant_data.dart';
import 'package:prestora/core/notify.dart';
import 'package:prestora/data/firebase/fb.dart';
import 'package:prestora/data/repositories/paie_repository.dart';
import 'package:prestora/data/repositories/suivi_store_base.dart';
import 'package:prestora/data/services/session.dart';
import 'package:prestora/app/view/admin/admin_data.dart' show TypeCompte;

// ═══════════════════════════════════════════════════════════════
//  Circuit de paie : Secrétaire → Doyen → VRA → Recteur → AG → Comptabilité
//  PaieStore lit/écrit Firestore (dossiers_paie, validations).
// ═══════════════════════════════════════════════════════════════

/// « Maintenant » : l'heure réelle.
DateTime get kMaintenant => DateTime.now();

String fmtDate(DateTime d) =>
    '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

String fmtMontant(double v) =>
    '${v.toStringAsFixed(2).replaceAll('.', ',')} \$';

// ───────────────────────── Les 4 autorités ─────────────────────────
enum RoleAutorite {
  doyen(2, 'Doyen', 'au VRA'),
  vra(3, 'Vice-recteur académique', 'au Recteur'),
  recteur(4, 'Recteur', "à l'Administrateur général"),
  ag(5, 'Administrateur général', 'à la Comptabilité');

  const RoleAutorite(this.palier, this.titre, this.suivant);

  final int palier; // palier du circuit (2 à 5)
  final String titre;
  final String suivant; // destinataire après validation

  /// Nom de la personne connectée.
  String get nom => Session.instance.me?.nomComplet ?? titre;

  /// Faculté du Doyen (limite sa portée) ; null pour les rôles globaux.
  String? get faculte =>
      this == RoleAutorite.doyen ? (Session.instance.faculteNom ?? '') : null;

  String get court => kActeursCourts[palier - 1];

  String get initiale {
    final n = Session.instance.me?.nom ?? '';
    return n.isEmpty ? '?' : n.substring(0, 1).toUpperCase();
  }
}

/// Libellé générique d'un palier (repli quand le nom de l'acteur est inconnu).
String nomDuPalier(int palier) => kActeurs[palier - 1];

// ───────────────────────── Modèles ─────────────────────────
/// Cours clôturé par l'encadreur, en attente d'initialisation du dossier.
class CoursTermine {
  CoursTermine({required this.id});
  final String id; // identifiant de la session de suivi

  String code = '';
  String intitule = '';
  String promotion = '';
  String faculte = '';
  String faculteId = '';
  String enseignant = '';
  String enseignantId = '';
  String grade = '';
  String coursId = '';
  double taux = 0;
  int credits = 0;
  int volume = 0;
  List<Seance> seances = [];
  String mode = 'Banque';
  String coordonnees = '';
  String? chefNom;

  double get heures => seances.fold(0.0, (s, e) => s + e.heures);
  double get brut => heures * taux;
}

class DossierWf {
  DossierWf({
    required this.reference,
    required this.code,
    required this.intitule,
    required this.promotion,
    required this.faculte,
    required this.enseignant,
    required this.grade,
    required this.credits,
    required this.volume,
    required this.seances,
    required this.taux,
    required this.mode,
    required this.coordonnees,
    required this.dateInit,
    this.id = '',
    this.anneeId = '',
    this.faculteId = '',
    this.enseignantId = '',
    this.retenuePct,
    this.chefNom,
    this.palierCourant = 1,
    this.palierRejet,
    this.motifRejet,
    this.referencePaiement,
    Map<int, DateTime>? dates,
    List<String>? pieces,
  }) : dates = dates ?? {},
       pieces = pieces ?? [];

  final String id; // = identifiant de la session de suivi
  final String anneeId;
  final String faculteId;
  final String enseignantId;
  final double? retenuePct;
  final String? chefNom;
  final String reference;
  final String code;
  final String intitule;
  final String promotion;
  final String faculte;
  final String enseignant;
  final String grade;
  final int credits;
  final int volume;
  final List<Seance> seances;
  final double taux;
  String mode;
  String coordonnees;
  final DateTime dateInit;

  /// 1 = initialisé (chez le secrétaire) · 2..5 = autorités · 6 = comptabilité · 7 = payé
  int palierCourant;
  int? palierRejet;
  String? motifRejet;
  String? referencePaiement;
  final Map<int, DateTime> dates; // date de traitement de chaque palier
  final Map<int, String> acteurs = {}; // nom de la personne par palier
  final List<String> pieces;
  final List<String> piecesIds = []; // alignés sur [pieces]

  // Renseignés par la Comptabilité à la clôture
  String? modeReglement; // Virement bancaire / Bon de caisse / Mobile Money
  String? bordereau; // preuve de paiement (fichier)
  String? bordereauId; // document de la collection `pieces`
  String? imputation; // imputation budgétaire
  final List<String> historique = []; // anciens rejets (après correction)

  /// Met à jour les champs qui évoluent pendant le circuit.
  void applyMap(Map<String, dynamic> m) {
    mode = (m['mode'] as String?) ?? mode;
    coordonnees = (m['coordonnees'] as String?) ?? coordonnees;
    palierCourant = (m['palier_courant'] as num?)?.toInt() ?? 1;
    palierRejet = (m['palier_rejet'] as num?)?.toInt();
    motifRejet = m['motif_rejet'] as String?;
    referencePaiement = m['reference_paiement'] as String?;
    modeReglement = m['mode_reglement'] as String?;
    bordereau = m['bordereau'] as String?;
    bordereauId = m['bordereau_id'] as String?;
    piecesIds
      ..clear()
      ..addAll(((m['pieces_ids'] as List?) ?? const []).whereType<String>());
    imputation = m['imputation'] as String?;
    dates.clear();
    final dm = m['dates'];
    if (dm is Map) {
      dm.forEach((k, v) {
        final p = int.tryParse('$k');
        final dt = Fb.date(v);
        if (p != null && dt != null) dates[p] = dt;
      });
    }
    acteurs.clear();
    final am = m['acteurs'];
    if (am is Map) {
      am.forEach((k, v) {
        final p = int.tryParse('$k');
        if (p != null && v is String) acteurs[p] = v;
      });
    }
    pieces
      ..clear()
      ..addAll(((m['pieces'] as List?) ?? const []).whereType<String>());
    historique
      ..clear()
      ..addAll(((m['historique'] as List?) ?? const []).whereType<String>());
  }

  factory DossierWf.fromDoc(String id, Map<String, dynamic> m) {
    final seances = <Seance>[];
    final raw = (m['seances'] as List?) ?? const [];
    for (var i = 0; i < raw.length; i++) {
      final x = raw[i];
      if (x is! Map) continue;
      final a = (x['debut'] as num?)?.toInt() ?? 0;
      final b = (x['fin'] as num?)?.toInt() ?? 0;
      seances.add(
        Seance(
          id: '$id-$i',
          date: Fb.date(x['date']) ?? DateTime.now(),
          debut: TimeOfDay(hour: a ~/ 60, minute: a % 60),
          fin: TimeOfDay(hour: b ~/ 60, minute: b % 60),
          chapitre: (x['chapitre'] as String?) ?? '',
          type: TypeSeance.from(x['type'] as String?),
          validee: true,
          preuve: x['preuve'] as String?,
          preuveId: x['preuve_id'] as String?,
        ),
      );
    }
    final d = DossierWf(
      id: id,
      anneeId: (m['annee_id'] as String?) ?? '',
      faculteId: (m['faculte_id'] as String?) ?? '',
      enseignantId: (m['enseignant_id'] as String?) ?? '',
      retenuePct: (m['retenue_pct'] as num?)?.toDouble(),
      chefNom: m['chef_nom'] as String?,
      reference: (m['reference'] as String?) ?? id,
      code: (m['code'] as String?) ?? '',
      intitule: (m['intitule'] as String?) ?? '',
      promotion: (m['promotion_nom'] as String?) ?? '',
      faculte: (m['faculte_nom'] as String?) ?? '',
      enseignant: (m['enseignant_nom'] as String?) ?? '',
      grade: (m['grade'] as String?) ?? '',
      credits: (m['credits'] as num?)?.toInt() ?? 0,
      volume: (m['volume'] as num?)?.toInt() ?? 0,
      seances: seances,
      taux: (m['taux'] as num?)?.toDouble() ?? 0,
      mode: (m['mode'] as String?) ?? 'Banque',
      coordonnees: (m['coordonnees'] as String?) ?? '',
      dateInit: Fb.date(m['date_init']) ?? DateTime.now(),
    );
    d.applyMap(m);
    return d;
  }

  /// Vue « enseignant » du dossier : sert à la Timeline et aux pastilles.
  DossierPaie get snapshot => DossierPaie(
    reference: reference,
    code: code,
    intitule: intitule,
    promotion: promotion,
    credits: credits,
    volume: volume,
    seances: seances,
    taux: taux,
    palierCourant: palierCourant,
    palierRejet: palierRejet,
    dateInit: dateInit,
    modePaiement: '$mode · $coordonnees',
    motifRejet: motifRejet,
    referencePaiement: referencePaiement,
    dates: Map<int, DateTime>.of(dates),
    retenuePct: retenuePct,
  );

  double get heures => snapshot.heures;
  double get brut => snapshot.brut;
  double get retenues => snapshot.retenues;
  double get net => snapshot.net;
  StatutDossier get statut => snapshot.statut;
  String get niveau => snapshot.niveau;

  bool get enCirculation =>
      statut == StatutDossier.enAttente || statut == StatutDossier.initialise;

  /// Date d'arrivée du dossier au palier courant.
  DateTime get recuLe => dates[palierCourant - 1] ?? dateInit;
  int get ancienneteJours => kMaintenant.difference(recuLe).inDays;

  String? get rejetePar {
    final p = palierRejet;
    if (p == null) return null;
    final nom = acteurs[p];
    return nom == null
        ? kActeursCourts[p - 1]
        : '${kActeursCourts[p - 1]} $nom';
  }
}

// ───────────────────────── Dépôt Firestore ─────────────────────────
class PaieStore extends SuiviStoreBase {
  String get secretaireNom => Session.instance.me?.nomComplet ?? '';
  String get secretaireFaculte => Session.instance.faculteNom ?? '';
  String get comptableNom => Session.instance.me?.nomComplet ?? '';

  String get initiale {
    final n = Session.instance.me?.nom ?? '';
    return n.isEmpty ? '?' : n.substring(0, 1).toUpperCase();
  }

  List<String> facultes = [];
  List<DossierWf> dossiers = [];
  List<CoursTermine> coursTermines = [];

  final Map<String, DossierWf> _wf = {};
  final Map<String, CoursTermine> _ct = {};
  final Map<String, double> _taux = {};
  final Map<String, (String, String)> _paiement = {};
  final Set<String> _paiementDemande = {};
  final List<StreamSubscription<dynamic>> _subs = [];

  PaieRepository get _repo => PaieRepository.instance;

  // ── Écoute ──
  @override
  Query<Map<String, dynamic>>? requete(String anneeId, String uid) {
    final me = Session.instance.me;
    if (me?.type != TypeCompte.secretaire || me?.faculteId == null) {
      return null;
    }
    // Cours clôturés de la faculté : ceux qui n'ont pas encore de dossier
    return sessionsQuery(anneeId)
        .where('faculte_id', isEqualTo: me!.faculteId)
        .where('est_cloturee', isEqualTo: true);
  }

  void _cancel() {
    for (final s in _subs) {
      s.cancel();
    }
    _subs.clear();
  }

  @override
  void onSessionChange(String? anneeId) {
    _cancel();
    final me = Session.instance.me;
    if (anneeId == null || me == null) {
      _wf.clear();
      _ct.clear();
      dossiers = [];
      coursTermines = [];
      facultes = [];
      return;
    }
    final db = Fb.db;
    Query<Map<String, dynamic>> q = db
        .collection(Col.dossiers)
        .where('annee_id', isEqualTo: anneeId);
    if (me.type == TypeCompte.secretaire || me.type == TypeCompte.doyen) {
      if (me.faculteId == null) return;
      q = q.where('faculte_id', isEqualTo: me.faculteId);
    }
    _subs.add(
      q.snapshots().listen((s) {
        final ids = s.docs.map((d) => d.id).toSet();
        _wf.removeWhere((id, _) => !ids.contains(id));
        for (final d in s.docs) {
          final existant = _wf[d.id];
          if (existant == null) {
            _wf[d.id] = DossierWf.fromDoc(d.id, d.data());
          } else {
            existant.applyMap(d.data());
          }
        }
        onHubChange();
      }, onError: (Object e) => Notif.erreur('Lecture des dossiers : $e')),
    );
    _subs.add(
      db.collection(Col.facultes).snapshots().listen((s) {
        facultes = [
          for (final d in s.docs) (d.data()['nom_faculte'] as String?) ?? '',
        ]..sort();
        notifyListeners();
      }, onError: (Object e) => debugPrint('facultes: $e')),
    );
    if (me.type == TypeCompte.secretaire) {
      _subs.add(
        db.collection(Col.baremes).snapshots().listen((s) {
          _taux
            ..clear()
            ..addEntries(
              s.docs.map(
                (d) => MapEntry(
                  d.id,
                  (d.data()['taux'] as num?)?.toDouble() ?? 0,
                ),
              ),
            );
          onHubChange();
        }, onError: (Object e) => debugPrint('baremes: $e')),
      );
    }
  }

  @override
  void rebuild() {
    dossiers = _wf.values.toList()
      ..sort((a, b) => b.dateInit.compareTo(a.dateInit));

    final dispo = hub.cours
        .where((c) => c.cloture && !_wf.containsKey(c.id))
        .toList();
    final ids = dispo.map((c) => c.id).toSet();
    _ct.removeWhere((id, _) => !ids.contains(id));
    for (final c in dispo) {
      final t = _ct.putIfAbsent(c.id, () => CoursTermine(id: c.id));
      t
        ..code = c.code
        ..intitule = c.intitule
        ..promotion = c.promotionNom
        ..faculte = secretaireFaculte
        ..faculteId = c.faculteId
        ..enseignant = c.enseignant
        ..enseignantId = c.enseignantId
        ..grade = c.grade
        ..coursId = c.coursId
        ..credits = c.credits
        ..volume = c.volume
        ..seances = c.seances
        ..chefNom = c.chefNom
        ..taux = _taux[c.grade] ?? 0;
      final p = _paiement[c.enseignantId];
      if (p != null) {
        t
          ..mode = p.$1
          ..coordonnees = p.$2;
      } else {
        _chargerPaiement(c.enseignantId);
      }
    }
    coursTermines = _ct.values.toList()..sort((a, b) => a.code.compareTo(b.code));
  }

  Future<void> _chargerPaiement(String uid) async {
    if (uid.isEmpty || !_paiementDemande.add(uid)) return;
    try {
      final d = await Fb.db
          .collection(Col.utilisateurs)
          .doc(uid)
          .collection(Col.paiement)
          .doc('infos')
          .get();
      _paiement[uid] = (
        (d.data()?['mode'] as String?) ?? 'Banque',
        (d.data()?['coordonnees'] as String?) ?? '',
      );
      onHubChange();
    } catch (e) {
      debugPrint('paiement $uid: $e');
    }
  }

  // ── Portée des autorités ──
  bool _dansPortee(RoleAutorite r, DossierWf d) =>
      r != RoleAutorite.doyen || d.faculteId == Session.instance.me?.faculteId;

  /// Dossiers actuellement à valider par ce rôle.
  List<DossierWf> enAttente(RoleAutorite r) => dossiers
      .where(
        (d) =>
            d.palierRejet == null &&
            d.palierCourant == r.palier &&
            _dansPortee(r, d),
      )
      .toList();

  /// Dossiers déjà traités par ce rôle (validés ou rejetés).
  List<DossierWf> traites(RoleAutorite r) => dossiers
      .where((d) => _dansPortee(r, d) && d.dates.containsKey(r.palier))
      .toList();

  bool rejeteParMoi(RoleAutorite r, DossierWf d) => d.palierRejet == r.palier;

  int validesCeMois(RoleAutorite r) => traites(r)
      .where(
        (d) =>
            !rejeteParMoi(r, d) &&
            d.dates[r.palier]!.month == kMaintenant.month &&
            d.dates[r.palier]!.year == kMaintenant.year,
      )
      .length;

  int rejetesParMoi(RoleAutorite r) =>
      traites(r).where((d) => rejeteParMoi(r, d)).length;

  // ── Comptabilité ──
  List<DossierWf> get aPayer => dossiers
      .where((d) => d.palierRejet == null && d.palierCourant == 6)
      .toList();

  List<DossierWf> get traitesCompta =>
      dossiers.where((d) => d.dates.containsKey(6)).toList();

  bool rejeteParCompta(DossierWf d) => d.palierRejet == 6;

  int get payesCeMois => traitesCompta
      .where(
        (d) =>
            !rejeteParCompta(d) &&
            d.dates[6]!.month == kMaintenant.month &&
            d.dates[6]!.year == kMaintenant.year,
      )
      .length;

  int get rejetesCompta => traitesCompta.where(rejeteParCompta).length;

  double get totalAPayer => aPayer.fold(0.0, (s, d) => s + d.net);

  // ── Secrétaire ──
  List<CoursTermine> get coursAInitialiser => coursTermines;
  List<DossierWf> get dossiersSec => dossiers;
  List<DossierWf> get dossiersEnCircuit =>
      dossiersSec.where((d) => d.palierRejet == null).toList();
  List<DossierWf> get dossiersRejetes =>
      dossiersSec.where((d) => d.palierRejet != null).toList();
  int get nbPayes =>
      dossiersSec.where((d) => d.statut == StatutDossier.paye).length;

  // ── Actions ──
  Future<bool> initialiser(
    CoursTermine c, {
    required String mode,
    required String coordonnees,
    required DateTime date,
  }) => _repo.initialiser(
    c,
    mode: mode,
    coordonnees: coordonnees,
    date: date,
  );

  Future<bool> soumettre(DossierWf d) => _repo.soumettre(d);

  Future<bool> valider(DossierWf d) => _repo.valider(d);

  Future<bool> rejeter(DossierWf d, String motif) => _repo.rejeter(d, motif);

  Future<bool> payer(
    DossierWf d, {
    required String reference,
    required DateTime date,
    required String modeReglement,
    required String bordereau,
    String? bordereauId,
    String? imputation,
  }) => _repo.payer(
    d,
    reference: reference,
    date: date,
    modeReglement: modeReglement,
    bordereau: bordereau,
    bordereauId: bordereauId,
    imputation: imputation,
  );

  Future<bool> reinitialiser(
    DossierWf d, {
    required String mode,
    required String coordonnees,
    required List<String> pieces,
    List<String>? piecesIds,
    String? commentaire,
  }) => _repo.reinitialiser(
    d,
    mode: mode,
    coordonnees: coordonnees,
    pieces: pieces,
    piecesIds: piecesIds,
    commentaire: commentaire,
  );

  @override
  void stop() {
    _cancel();
    super.stop();
  }
}

final PaieStore paieStore = PaieStore();
