import 'package:flutter/material.dart';
import 'package:prestora/app/view/prestation/student/etudiant_data.dart';

// On réutilise le modèle de séance / de suivi défini côté Étudiant :
// c'est la même donnée métier vue par deux rôles.

// ═══════════════════════════════════════════════════════════════
//  Modèles + données fictives de l'espace Encadreur pédagogique
//  EncadreurStore = faux dépôt, à remplacer par vos Cubits / Firebase.
// ═══════════════════════════════════════════════════════════════

enum StatutEnc {
  nonAffecte('Non affecté'),
  enCours('En cours'),
  valideParEnseignant("Validé par l'enseignant"),
  cloture('Clôturé');

  const StatutEnc(this.label);
  final String label;
}

/// Un cours du catalogue ; `suivi` est null tant qu'aucun enseignant n'est affecté.
class CoursEnc {
  CoursEnc({
    required this.code,
    required this.intitule,
    required this.credits,
    required this.volume,
    this.suivi,
  });

  final String code;
  final String intitule;
  final int credits;
  final int volume;
  CoursSuivi? suivi; // session de suivi (enseignant + séances)

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
    required this.nom,
    required this.departement,
    required this.cours,
    this.chef,
  });

  final String nom;
  final String departement;
  final String? chef; // chef de promotion
  final List<CoursEnc> cours;

  int get nonSuivis => cours.where((c) => c.suivi == null).length;
  int get aCloturer =>
      cours.where((c) => c.statut == StatutEnc.valideParEnseignant).length;
}

class EnseignantFictif {
  const EnseignantFictif(this.nom, this.email, this.grade);
  final String nom;
  final String email;
  final String grade;
}

// ───────────────────────── Aides de fabrication ─────────────────────────
List<Seance> _gen(
  String p,
  List<String> chaps, {
  int h1 = 8,
  int h2 = 11,
  int validees = 0,
}) => List.generate(
  chaps.length,
  (i) => Seance(
    id: '$p$i',
    date: DateTime(2026, 9, 2 + i * 5),
    debut: TimeOfDay(hour: h1, minute: 0),
    fin: TimeOfDay(hour: h2, minute: 0),
    chapitre: chaps[i],
    validee: i < validees,
  ),
);

CoursSuivi _suivi(
  String code,
  String intitule,
  String ens,
  String grade,
  int credits,
  int volume,
  List<Seance> seances, {
  bool cloture = false,
}) => CoursSuivi(
  code: code,
  intitule: intitule,
  enseignant: ens,
  grade: grade,
  credits: credits,
  volume: volume,
  seances: seances,
  cloture: cloture,
);

// ───────────────────────── Faux dépôt ─────────────────────────
class EncadreurStore extends ChangeNotifier {
  final String nom = 'Dr Olivier Kabano';
  final String faculte = 'Sciences et Technologies';
  final String anneeAcademique = '2026-2027';

  String get initiale {
    final parts = nom.split(' ');
    return (parts.length > 1 ? parts[1] : parts[0]).substring(0, 1);
  }

  final List<EnseignantFictif> enseignants = const [
    EnseignantFictif(
      'Pr Aimé Cirimwami',
      'a.cirimwami@exemple.org',
      'Professeur Ordinaire',
    ),
    EnseignantFictif(
      'Pr Joseph Mushagalusa',
      'j.mushagalusa@exemple.org',
      'Professeur',
    ),
    EnseignantFictif(
      'Dr Alain Bulambo',
      'a.bulambo@exemple.org',
      'Professeur Associé',
    ),
    EnseignantFictif(
      'Dr Esther Namwira',
      'e.namwira@exemple.org',
      'Professeur Associé',
    ),
    EnseignantFictif(
      'Dr Grâce Bahati',
      'g.bahati@exemple.org',
      'Chef de Travaux',
    ),
    EnseignantFictif(
      'M. Roger Mwenebatu',
      'r.mwenebatu@exemple.org',
      'Assistant',
    ),
  ];

  late final List<PromotionEnc> promotions = [
    PromotionEnc(
      nom: 'L1 Informatique',
      departement: 'Informatique',
      chef: 'Aline Kitumaini',
      cours: [
        CoursEnc(
          code: 'INF101',
          intitule: "Introduction à l'algorithmique",
          credits: 4,
          volume: 30,
          suivi: _suivi(
            'INF101',
            "Introduction à l'algorithmique",
            'Dr Grâce Bahati',
            'Chef de Travaux',
            4,
            30,
            _gen('a', [
              'Notion d\'algorithme',
              'Variables et types',
              'Structures conditionnelles',
              'Boucles',
              'Tableaux',
            ], validees: 5),
          ),
        ),
        CoursEnc(
          code: 'INF102',
          intitule: 'Architecture des ordinateurs',
          credits: 3,
          volume: 30,
        ),
        CoursEnc(
          code: 'INF103',
          intitule: 'Mathématiques discrètes',
          credits: 4,
          volume: 45,
        ),
        CoursEnc(
          code: 'INF104',
          intitule: 'Anglais technique',
          credits: 2,
          volume: 15,
        ),
      ],
    ),
    PromotionEnc(
      nom: 'L2 Informatique',
      departement: 'Informatique',
      chef: 'Patrick Bisimwa',
      cours: [
        CoursEnc(
          code: 'INF204',
          intitule: 'Bases de données relationnelles',
          credits: 5,
          volume: 45,
          suivi: _suivi(
            'INF204',
            'Bases de données relationnelles',
            'Dr Grâce Bahati',
            'Chef de Travaux',
            5,
            45,
            _gen('b', [
              'Introduction aux SGBD',
              'Modèle entité-association',
              'Algèbre relationnelle',
              'SQL : requêtes simples',
              'SQL : jointures',
              'Normalisation',
            ], validees: 4),
          ),
        ),
        CoursEnc(
          code: 'INF210',
          intitule: 'Programmation orientée objet',
          credits: 5,
          volume: 45,
          suivi: _suivi(
            'INF210',
            'Programmation orientée objet',
            'Pr Aimé Cirimwami',
            'Professeur Ordinaire',
            5,
            45,
            _gen(
              'c',
              [
                'Classes et objets',
                'Encapsulation et héritage',
                'Polymorphisme',
                'Interfaces',
                'Exceptions',
              ],
              h1: 13,
              h2: 17,
              validees: 3,
            ),
          ),
        ),
        CoursEnc(
          code: 'INF215',
          intitule: 'Réseaux informatiques',
          credits: 4,
          volume: 30,
          suivi: _suivi(
            'INF215',
            'Réseaux informatiques',
            'Dr Alain Bulambo',
            'Professeur Associé',
            4,
            30,
            _gen(
              'd',
              ['Modèle OSI et TCP/IP', 'Adressage IPv4', 'Routage statique'],
              h1: 8,
              h2: 10,
            ),
          ),
        ),
        CoursEnc(
          code: 'INF230',
          intitule: 'Génie logiciel',
          credits: 4,
          volume: 30,
        ),
        CoursEnc(
          code: 'MAT215',
          intitule: 'Probabilités et statistiques',
          credits: 4,
          volume: 30,
          suivi: _suivi(
            'MAT215',
            'Probabilités et statistiques',
            'Pr Joseph Mushagalusa',
            'Professeur',
            4,
            30,
            _gen(
              'e',
              [
                'Dénombrement',
                'Probabilités conditionnelles',
                'Variables aléatoires',
                'Lois usuelles',
                'Estimation',
                "Tests d'hypothèses",
              ],
              h1: 8,
              h2: 13,
              validees: 6,
            ),
          ),
        ),
        CoursEnc(
          code: 'INF220',
          intitule: "Systèmes d'exploitation",
          credits: 4,
          volume: 30,
          suivi: _suivi(
            'INF220',
            "Systèmes d'exploitation",
            'Pr Aimé Cirimwami',
            'Professeur Ordinaire',
            4,
            30,
            _gen(
              'f',
              [
                'Processus et threads',
                'Ordonnancement',
                'Synchronisation',
                'Mémoire',
                'Fichiers',
                'Entrées / sorties',
              ],
              h1: 8,
              h2: 13,
              validees: 6,
            ),
            cloture: true,
          ),
        ),
      ],
    ),
    PromotionEnc(
      nom: 'L3 Informatique',
      departement: 'Informatique',
      cours: [
        CoursEnc(
          code: 'INF305',
          intitule: 'Architecture logicielle',
          credits: 4,
          volume: 30,
        ),
        CoursEnc(
          code: 'INF310',
          intitule: 'Intelligence artificielle',
          credits: 5,
          volume: 45,
        ),
        CoursEnc(
          code: 'INF320',
          intitule: 'Sécurité informatique',
          credits: 4,
          volume: 30,
          suivi: _suivi(
            'INF320',
            'Sécurité informatique',
            'Pr Aimé Cirimwami',
            'Professeur Ordinaire',
            4,
            30,
            [],
          ),
        ),
      ],
    ),
    PromotionEnc(
      nom: 'L1 Mathématiques',
      departement: 'Mathématiques',
      chef: 'Jean Bulonza',
      cours: [
        CoursEnc(
          code: 'MAT101',
          intitule: 'Analyse mathématique I',
          credits: 6,
          volume: 60,
          suivi: _suivi(
            'MAT101',
            'Analyse mathématique I',
            'Pr Joseph Mushagalusa',
            'Professeur',
            6,
            60,
            _gen('g', [
              'Suites numériques',
              'Limites',
              'Continuité',
              'Dérivation',
            ], validees: 2),
          ),
        ),
        CoursEnc(
          code: 'MAT102',
          intitule: 'Algèbre linéaire',
          credits: 5,
          volume: 45,
        ),
      ],
    ),
  ];

  // ── Compteurs ──
  int get nbANonAffectes => promotions.fold(0, (s, p) => s + p.nonSuivis);
  int get nbACloturer => promotions.fold(0, (s, p) => s + p.aCloturer);

  // ── Actions ──
  void touch() => notifyListeners();

  void affecter(CoursEnc c, EnseignantFictif e) {
    c.suivi = CoursSuivi(
      code: c.code,
      intitule: c.intitule,
      enseignant: e.nom,
      grade: e.grade,
      credits: c.credits,
      volume: c.volume,
    );
    notifyListeners();
  }

  void cloturer(CoursEnc c) {
    c.suivi?.cloture = true;
    notifyListeners();
  }

  void deleteSeance(CoursEnc c, Seance s) {
    c.suivi?.seances.remove(s);
    notifyListeners();
  }

  /// Outil de démonstration : l'enseignant valide toutes les séances.
  void simulerValidation(CoursEnc c) {
    for (final s in c.suivi?.seances ?? <Seance>[]) {
      s.validee = true;
    }
    notifyListeners();
  }
}

final EncadreurStore encadreurStore = EncadreurStore();
