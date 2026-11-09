import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:prestora/app/view/payslip/authority/paie_data.dart' show DossierWf;
import 'package:prestora/app/view/prestation/student/etudiant_data.dart';
import 'package:prestora/data/firebase/fb.dart';
import 'package:prestora/data/repositories/suivi_repository.dart';
import 'package:prestora/data/repositories/suivi_store_base.dart';
import 'package:prestora/data/services/session.dart';

// Modèle de séance / de suivi partagé avec les rôles Étudiant et Encadreur.

// ═══════════════════════════════════════════════════════════════
//  Modèles + données fictives de l'espace Enseignant visiteur
//  EnseignantStore = faux dépôt, à remplacer par vos Cubits / Firebase.
// ═══════════════════════════════════════════════════════════════

/// Taux de retenue fiscale en vigueur (%), défini par l'administrateur dans
/// l'écran Barèmes (collection parametres/retenue_fiscale). 0 tant que non défini.
double get kRetenueDemo => Session.instance.retenue ?? 0;

String fmtUsd(double v) => '${v.toStringAsFixed(2).replaceAll('.', ',')} \$';

String fmtDateCourte(DateTime d) =>
    '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

// ───────────────────────── Circuit de paie ─────────────────────────
const kActeurs = <String>[
  'Secrétaire de faculté',
  'Doyen',
  'Vice-recteur académique',
  'Recteur',
  'Administrateur général',
  'Comptabilité',
];

const kActions = <String>[
  'Initialise et soumet le dossier',
  'Valide et signe',
  'Valide et signe',
  'Valide et signe',
  'Valide et signe',
  'Règle et clôture le dossier',
];

const kNiveaux = <String>[
  'Initialisé',
  'Chez le Doyen',
  'Chez le VRA',
  'Chez le Recteur',
  "Chez l'AG",
  'À la comptabilité',
];

const kActeursCourts = <String>[
  'secrétaire',
  'Doyen',
  'VRA',
  'Recteur',
  'AG',
  'comptable',
];

enum EtatEtape { fait, enCours, aVenir, rejete }

enum StatutDossier { initialise, enAttente, paye, rejete }

String _empreinte(String ref, int palier) {
  var h = 17;
  for (final c in '$ref|$palier'.codeUnits) {
    h = (h * 31 + c) & 0xFFFFFFFF;
  }
  return h.toRadixString(16).padLeft(8, '0');
}

// ───────────────────────── Modèles ─────────────────────────
class CoursEns {
  CoursEns({required this.suivi, required this.promotion});
  final CoursSuivi suivi;
  final String promotion;
}

class DossierPaie {
  DossierPaie({
    required this.reference,
    required this.code,
    required this.intitule,
    required this.promotion,
    required this.credits,
    required this.volume,
    required this.seances,
    required this.taux,
    required this.palierCourant,
    required this.dateInit,
    required this.modePaiement,
    this.palierRejet,
    this.motifRejet,
    this.referencePaiement,
    this.dates,
    this.retenuePct,
  });

  /// Dates réelles de traitement par palier (si connues).
  final Map<int, DateTime>? dates;

  /// Retenue appliquée à la création du dossier (figée) ; sinon taux courant.
  final double? retenuePct;

  final String reference;
  final String code;
  final String intitule;
  final String promotion;
  final int credits;
  final int volume;
  final List<Seance> seances;
  final double taux; // $/h selon le grade
  final int palierCourant; // 1..6 ; 7 = payé
  final int? palierRejet; // palier qui a rejeté (si rejeté)
  final DateTime dateInit;
  final String modePaiement;
  final String? motifRejet;
  final String? referencePaiement;

  double get heures => seances.fold(0.0, (s, e) => s + e.heures);
  double get brut => heures * taux;
  double get retenues => brut * (retenuePct ?? kRetenueDemo) / 100;
  double get net => brut - retenues;

  StatutDossier get statut {
    if (palierRejet != null) return StatutDossier.rejete;
    if (palierCourant >= 7) return StatutDossier.paye;
    if (palierCourant == 1) return StatutDossier.initialise;
    return StatutDossier.enAttente;
  }

  /// Libellé du niveau actuel (ex. « Chez le Doyen », « Rejeté par le VRA »).
  String get niveau {
    if (palierRejet != null)
      return 'Rejeté par le ${kActeursCourts[palierRejet! - 1]}';
    if (palierCourant >= 7) return 'Payé';
    return kNiveaux[palierCourant - 1];
  }

  EtatEtape etat(int palier) {
    final rej = palierRejet;
    if (rej != null) {
      if (palier < rej) return EtatEtape.fait;
      if (palier == rej) return EtatEtape.rejete;
      return EtatEtape.aVenir;
    }
    if (palier < palierCourant) return EtatEtape.fait;
    if (palier == palierCourant) return EtatEtape.enCours;
    return EtatEtape.aVenir;
  }

  /// Date de traitement d'une étape (fictive : 2 jours entre chaque palier).
  DateTime? dateEtape(int palier) {
    final e = etat(palier);
    final reelle = dates?[palier];
    if (reelle != null) return reelle;
    if (dates != null) return null; // dossier réel : pas de date inventée
    if (e == EtatEtape.fait || e == EtatEtape.rejete) {
      return dateInit.add(Duration(days: (palier - 1) * 2));
    }
    return null;
  }

  /// Empreinte de signature (fictive) des paliers validés par une autorité.
  String? signature(int palier) =>
      (palier >= 2 && etat(palier) == EtatEtape.fait)
      ? _empreinte(reference, palier)
      : null;

  DateTime? get datePaiement =>
      statut == StatutDossier.paye ? dateEtape(6) : null;
}

// ───────────────────────── Aides de fabrication ─────────────────────────

List<Seance> _gen(
  String p,
  List<String> chaps, {
  int h1 = 8,
  int h2 = 11,
  int m = 9,
  int d0 = 2,
  bool validee = true,
}) => List.generate(
  chaps.length,
  (i) => Seance(
    id: '$p$i',
    date: DateTime(2026, m, d0 + i * 5),
    debut: TimeOfDay(hour: h1, minute: 0),
    fin: TimeOfDay(hour: h2, minute: 0),
    chapitre: chaps[i],
    validee: validee,
  ),
);

// ───────────────────────── Faux dépôt ─────────────────────────
class EnseignantStore extends SuiviStoreBase {
  String get nom => Session.instance.me?.nomComplet ?? '';
  String get grade => Session.instance.me?.grade ?? '';
  String get faculte => Session.instance.faculteNom ?? '';
  String get institution => Session.instance.me?.institution ?? '';
  String get paiement => _paiement;
  double get taux => _taux;

  String _paiement = '—';
  double _taux = 0;
  StreamSubscription<dynamic>? _subPaie;
  StreamSubscription<dynamic>? _subTaux;

  String get initiale {
    final n = Session.instance.me?.nom ?? '';
    return n.isEmpty ? '?' : n.substring(0, 1).toUpperCase();
  }

  final Map<String, CoursEns> _ens = {};
  List<CoursEns> cours = [];

  @override
  Query<Map<String, dynamic>>? requete(String anneeId, String uid) =>
      sessionsQuery(anneeId).where('enseignant_id', isEqualTo: uid);

  @override
  void onSessionChange(String? anneeId) {
    _subPaie?.cancel();
    _subTaux?.cancel();
    _subDossiers?.cancel();
    _subPaie = null;
    _subTaux = null;
    _subDossiers = null;
    final me = Session.instance.me;
    if (me == null) return;
    if (anneeId != null) {
      _subDossiers = Fb.db
          .collection(Col.dossiers)
          .where('annee_id', isEqualTo: anneeId)
          .where('enseignant_id', isEqualTo: me.id)
          .snapshots()
          .listen((s) {
            final wfs = [
              for (final d in s.docs) DossierWf.fromDoc(d.id, d.data()),
            ];
            wf = {for (final w in wfs) w.reference: w};
            dossiers = [
              for (final w in wfs) w.snapshot,
            ]..sort((a, b) => b.dateInit.compareTo(a.dateInit));
            notifyListeners();
          }, onError: (Object e) => debugPrint('dossiers: $e'));
    } else {
      dossiers = [];
    }
    // Coordonnées de paiement (sous-collection lisible par l'intéressé)
    _subPaie = Fb.db
        .collection(Col.utilisateurs)
        .doc(me.id)
        .collection(Col.paiement)
        .doc('infos')
        .snapshots()
        .listen((d) {
          final m = d.data();
          _paiement = m == null ? '—' : '${m['mode'] ?? ''} · ${m['coordonnees'] ?? ''}';
          notifyListeners();
        }, onError: (Object e) => debugPrint('paiement: $e'));
    // Taux horaire du grade
    final g = me.grade;
    if (g != null && g.isNotEmpty) {
      _subTaux = Fb.db.collection(Col.baremes).doc(g).snapshots().listen((d) {
        _taux = (d.data()?['taux'] as num?)?.toDouble() ?? 0;
        notifyListeners();
      }, onError: (Object e) => debugPrint('taux: $e'));
    }
  }

  @override
  void rebuild() {
    final l = hub.cours;
    final ids = l.map((c) => c.id).toSet();
    _ens.removeWhere((id, _) => !ids.contains(id));
    cours = [
      for (final c in l)
        _ens.putIfAbsent(
          c.id,
          () => CoursEns(suivi: c, promotion: c.promotionNom),
        ),
    ];
  }

  List<DossierPaie> dossiers = [];
  Map<String, DossierWf> wf = {}; // dossiers complets, par référence
  StreamSubscription<dynamic>? _subDossiers;

  int get nbSeancesAValider => cours
      .where((c) => !c.suivi.cloture)
      .fold(0, (s, c) => s + c.suivi.nbEncodees);
  int get nbDossiersEnCours =>
      dossiers.where((d) => d.statut != StatutDossier.paye).length;
  int get nbDossiersPayes => dossiers.length - nbDossiersEnCours;
  double get montantPercu => dossiers
      .where((d) => d.statut == StatutDossier.paye)
      .fold(0.0, (s, d) => s + d.net);
  double get montantEnAttente => dossiers
      .where(
        (d) =>
            d.statut == StatutDossier.enAttente ||
            d.statut == StatutDossier.initialise,
      )
      .fold(0.0, (s, d) => s + d.net);

  Future<bool> valider(CoursSuivi c, Seance s) =>
      SuiviRepository.instance.validerSeance(c, s, true);

  Future<bool> devalider(CoursSuivi c, Seance s) =>
      SuiviRepository.instance.validerSeance(c, s, false);

  Future<bool> toutValider(CoursEns c) =>
      SuiviRepository.instance.toutValider(c.suivi);

  @override
  void stop() {
    _subPaie?.cancel();
    _subTaux?.cancel();
    _subDossiers?.cancel();
    super.stop();
  }
}

final EnseignantStore enseignantStore = EnseignantStore();
