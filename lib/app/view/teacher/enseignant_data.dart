import 'package:flutter/material.dart';
import 'package:prestora/app/view/prestation/student/etudiant_data.dart';

// Modèle de séance / de suivi partagé avec les rôles Étudiant et Encadreur.

// ═══════════════════════════════════════════════════════════════
//  Modèles + données fictives de l'espace Enseignant visiteur
//  EnseignantStore = faux dépôt, à remplacer par vos Cubits / Firebase.
// ═══════════════════════════════════════════════════════════════

/// Taux de retenue FICTIF pour la démo : la vraie valeur est « À définir »
/// dans l'écran Barèmes de l'administrateur.
const double kRetenueDemo = 5;

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
  });

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
  double get retenues => brut * kRetenueDemo / 100;
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
Seance _sc(
  int id,
  int m,
  int d,
  int h1,
  int h2,
  String chap, {
  TypeSeance type = TypeSeance.cm,
  bool v = true,
  String? preuve,
}) => Seance(
  id: 'e$id',
  date: DateTime(2026, m, d),
  debut: TimeOfDay(hour: h1, minute: 0),
  fin: TimeOfDay(hour: h2, minute: 0),
  chapitre: chap,
  type: type,
  validee: v,
  preuve: preuve,
);

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
class EnseignantStore extends ChangeNotifier {
  final String nom = 'Dr Grâce Bahati';
  final String grade = 'Chef de Travaux';
  final String faculte = 'Sciences et Technologies';
  final String institution = 'ULPGL Goma';
  final double taux = 8;
  final String paiement = 'Mobile Money · 0990 000 002';

  String get initiale => nom.split(' ').length > 1
      ? nom.split(' ')[1].substring(0, 1)
      : nom.substring(0, 1);

  late final List<CoursEns> cours = [
    CoursEns(
      promotion: 'L1 Informatique',
      suivi: CoursSuivi(
        code: 'INF101',
        intitule: "Introduction à l'algorithmique",
        enseignant: nom,
        grade: grade,
        credits: 4,
        volume: 30,
        seances: _gen('a', [
          "Notion d'algorithme",
          'Variables et types',
          'Structures conditionnelles',
          'Boucles',
          'Tableaux',
        ]),
      ),
    ),
    CoursEns(
      promotion: 'L2 Informatique',
      suivi: CoursSuivi(
        code: 'INF204',
        intitule: 'Bases de données relationnelles',
        enseignant: nom,
        grade: grade,
        credits: 5,
        volume: 45,
        seances: [
          _sc(1, 9, 9, 8, 10, 'Introduction aux SGBD'),
          _sc(2, 9, 11, 8, 11, 'Modèle entité-association'),
          _sc(3, 9, 16, 8, 10, 'Algèbre relationnelle'),
          _sc(
            4,
            9,
            18,
            10,
            13,
            'Modélisation : exercices dirigés',
            type: TypeSeance.td,
          ),
          _sc(5, 9, 23, 8, 10, 'SQL : requêtes simples'),
          _sc(6, 9, 25, 8, 11, 'SQL : jointures et sous-requêtes', v: false),
          _sc(
            7,
            9,
            30,
            8,
            10,
            'Normalisation (1FN à 3FN)',
            v: false,
            preuve: 'registre_30-09.jpg',
          ),
          _sc(
            8,
            10,
            7,
            8,
            11,
            'Travaux pratiques MySQL',
            type: TypeSeance.tp,
            v: false,
            preuve: 'registre_07-10.jpg',
          ),
        ],
      ),
    ),
    CoursEns(
      promotion: 'L3 Informatique',
      suivi: CoursSuivi(
        code: 'INF305',
        intitule: 'Architecture logicielle',
        enseignant: nom,
        grade: grade,
        credits: 4,
        volume: 30,
        seances: _gen(
          'c',
          [
            'Principes SOLID',
            'Patrons de conception',
            'Architecture en couches',
            'Microservices',
            'API REST',
            'Déploiement',
          ],
          h1: 8,
          h2: 13,
        ),
      ),
    ),
    CoursEns(
      promotion: 'L1 Informatique',
      suivi: CoursSuivi(
        code: 'INF120',
        intitule: 'Structures de données',
        enseignant: nom,
        grade: grade,
        credits: 4,
        volume: 30,
        cloture: true,
        seances: _gen(
          'd',
          [
            'Listes chaînées',
            'Piles et files',
            'Arbres binaires',
            'Graphes',
            'Tables de hachage',
            'Tris',
          ],
          h1: 8,
          h2: 13,
          m: 9,
          d0: 1,
        ),
      ),
    ),
  ];

  late final List<DossierPaie> dossiers = [
    DossierPaie(
      reference: 'UCB-2026-0142',
      code: 'INF120',
      intitule: 'Structures de données',
      promotion: 'L1 Informatique',
      credits: 4,
      volume: 30,
      taux: taux,
      palierCourant: 5,
      dateInit: DateTime(2026, 9, 28),
      modePaiement: paiement,
      seances: _gen(
        'd',
        [
          'Listes chaînées',
          'Piles et files',
          'Arbres binaires',
          'Graphes',
          'Tables de hachage',
          'Tris',
        ],
        h1: 8,
        h2: 13,
        m: 9,
        d0: 1,
      ),
    ),
    DossierPaie(
      reference: 'UCB-2026-0156',
      code: 'INF110',
      intitule: 'Bureautique et internet',
      promotion: 'L1 Informatique',
      credits: 3,
      volume: 15,
      taux: taux,
      palierCourant: 2,
      dateInit: DateTime(2026, 10, 8),
      modePaiement: paiement,
      seances: _gen(
        'h',
        [
          'Traitement de texte',
          'Tableur',
          'Présentation',
          'Messagerie',
          'Recherche en ligne',
        ],
        m: 9,
        d0: 3,
      ),
    ),
    DossierPaie(
      reference: 'UCB-2026-0119',
      code: 'INF050',
      intitule: 'Atelier de programmation',
      promotion: 'L2 Informatique',
      credits: 3,
      volume: 15,
      taux: taux,
      palierCourant: 3,
      palierRejet: 3,
      dateInit: DateTime(2026, 9, 14),
      modePaiement: paiement,
      motifRejet:
          'Discordance entre les heures encodées (15 h) et la fiche de présence signée (12 h). Merci de corriger puis de réinitialiser le dossier.',
      seances: _gen(
        'r',
        [
          'Environnement de développement',
          'Débogage',
          'Tests unitaires',
          'Gestion de versions',
          'Projet final',
        ],
        m: 8,
        d0: 20,
      ),
    ),
    DossierPaie(
      reference: 'UCB-2026-0087',
      code: 'INF090',
      intitule: "Initiation à l'informatique",
      promotion: 'L1 Informatique',
      credits: 3,
      volume: 20,
      taux: taux,
      palierCourant: 7,
      dateInit: DateTime(2026, 7, 10),
      modePaiement: paiement,
      referencePaiement: 'MM-2026-0720-4471',
      seances: _gen(
        'p',
        [
          'Histoire et vocabulaire',
          'Le matériel',
          'Les logiciels',
          'Internet et sécurité',
          'Atelier pratique',
        ],
        h1: 8,
        h2: 12,
        m: 6,
        d0: 1,
      ),
    ),
  ];

  // ── Compteurs ──
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

  // ── Actions ──
  void valider(Seance s) {
    s.validee = true;
    notifyListeners();
  }

  void devalider(Seance s) {
    s.validee = false;
    notifyListeners();
  }

  void toutValider(CoursEns c) {
    for (final s in c.suivi.seances) {
      s.validee = true;
    }
    notifyListeners();
  }
}

final EnseignantStore enseignantStore = EnseignantStore();
