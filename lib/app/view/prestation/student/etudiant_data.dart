import 'package:flutter/material.dart';

// ═══════════════════════════════════════════════════════════════
//  Modèles + données fictives de l'espace Étudiant (chef de promotion)
//  EtudiantStore = faux dépôt, à remplacer par vos Cubits / Firebase.
// ═══════════════════════════════════════════════════════════════

String two(int n) => n.toString().padLeft(2, '0');

String fmtH(double v) =>
    v % 1 == 0 ? '${v.toInt()} h' : '${v.toStringAsFixed(1)} h';

String fmtHeure(TimeOfDay t) => '${two(t.hour)}h${two(t.minute)}';

String fmtJour(DateTime d) {
  const j = ['lun.', 'mar.', 'mer.', 'jeu.', 'ven.', 'sam.', 'dim.'];
  return '${j[d.weekday - 1]} ${two(d.day)}/${two(d.month)}/${d.year}';
}

int minutesOf(TimeOfDay t) => t.hour * 60 + t.minute;

// ───────────────────────── Types ─────────────────────────
enum TypeSeance {
  cm('CM'),
  td('TD'),
  tp('TP');

  const TypeSeance(this.label);
  final String label;
}

enum StatutCours { enCours, valideParEnseignant, cloture }

// ───────────────────────── Modèles ─────────────────────────
class Seance {
  Seance({
    required this.id,
    required this.date,
    required this.debut,
    required this.fin,
    required this.chapitre,
    this.type = TypeSeance.cm,
    this.validee = false,
    this.preuve,
  });

  final String id;
  DateTime date;
  TimeOfDay debut;
  TimeOfDay fin;
  String chapitre;
  TypeSeance type;
  bool validee; // valide_par_prof
  String? preuve; // nom du fichier de la photo du registre

  double get heures => (minutesOf(fin) - minutesOf(debut)) / 60;
  String get tranche => '${fmtHeure(debut)} – ${fmtHeure(fin)}';
}

class CoursSuivi {
  CoursSuivi({
    required this.code,
    required this.intitule,
    required this.enseignant,
    required this.grade,
    required this.credits,
    required this.volume,
    List<Seance>? seances,
    this.cloture = false,
  }) : seances = seances ?? [];

  final String code;
  final String intitule;
  final String enseignant;
  final String grade;
  final int credits;
  final int volume; // volume_horaire_max
  final List<Seance> seances;
  bool cloture; // est_cloturee (par l'encadreur)

  double get heuresPrestees => seances.fold(0.0, (s, e) => s + e.heures);
  double get heuresRestantes => volume - heuresPrestees;
  double get progression => (heuresPrestees / volume).clamp(0.0, 1.0);
  int get nbValidees => seances.where((s) => s.validee).length;
  int get nbEncodees =>
      seances.length - nbValidees; // en attente de l'enseignant

  StatutCours get statut {
    if (cloture) return StatutCours.cloture;
    if (seances.isNotEmpty &&
        seances.every((s) => s.validee) &&
        heuresPrestees >= volume) {
      return StatutCours.valideParEnseignant;
    }
    return StatutCours.enCours;
  }
}

// ───────────────────────── Aides de fabrication ─────────────────────────
Seance _s(
  int id,
  int m,
  int d,
  int h1,
  int h2,
  String chap, {
  TypeSeance type = TypeSeance.cm,
  bool v = false,
  String? preuve,
}) => Seance(
  id: 's$id',
  date: DateTime(2026, m, d),
  debut: TimeOfDay(hour: h1, minute: 0),
  fin: TimeOfDay(hour: h2, minute: 0),
  chapitre: chap,
  type: type,
  validee: v,
  preuve: preuve,
);

List<Seance> _blocs(
  String p,
  int h1,
  int h2,
  List<String> chaps, {
  bool validee = true,
}) => List.generate(
  chaps.length,
  (i) => Seance(
    id: '$p$i',
    date: DateTime(2026, 9, 1 + i * 4),
    debut: TimeOfDay(hour: h1, minute: 0),
    fin: TimeOfDay(hour: h2, minute: 0),
    chapitre: chaps[i],
    validee: validee,
  ),
);

// ───────────────────────── Faux dépôt ─────────────────────────
class EtudiantStore extends ChangeNotifier {
  final String nom = 'Patrick Bisimwa';
  final String promotion = 'L2 Informatique';
  final String faculte = 'Sciences et Technologies';

  final List<CoursSuivi> cours = [
    CoursSuivi(
      code: 'INF204',
      intitule: 'Bases de données relationnelles',
      enseignant: 'Dr Grâce Bahati',
      grade: 'Chef de Travaux',
      credits: 5,
      volume: 45,
      seances: [
        _s(1, 9, 9, 8, 10, 'Introduction aux SGBD', v: true),
        _s(2, 9, 11, 8, 11, 'Modèle entité-association', v: true),
        _s(3, 9, 16, 8, 10, 'Algèbre relationnelle', v: true),
        _s(
          4,
          9,
          18,
          10,
          13,
          'Modélisation : exercices dirigés',
          type: TypeSeance.td,
          v: true,
        ),
        _s(5, 9, 23, 8, 10, 'SQL : requêtes simples', v: true),
        _s(6, 9, 25, 8, 11, 'SQL : jointures et sous-requêtes'),
        _s(
          7,
          9,
          30,
          8,
          10,
          'Normalisation (1FN à 3FN)',
          preuve: 'registre_30-09.jpg',
        ),
        _s(
          8,
          10,
          7,
          8,
          11,
          'Travaux pratiques MySQL',
          type: TypeSeance.tp,
          preuve: 'registre_07-10.jpg',
        ),
      ],
    ),
    CoursSuivi(
      code: 'INF210',
      intitule: 'Programmation orientée objet',
      enseignant: 'Pr Aimé Cirimwami',
      grade: 'Professeur Ordinaire',
      credits: 5,
      volume: 45,
      seances: [
        _s(11, 9, 8, 13, 17, 'Classes et objets', v: true),
        _s(12, 9, 15, 13, 17, 'Encapsulation et héritage', v: true),
        _s(13, 9, 22, 13, 17, 'Polymorphisme', v: true),
        _s(14, 9, 29, 13, 17, 'Interfaces et classes abstraites', v: true),
        _s(15, 10, 6, 13, 17, 'Gestion des exceptions'),
        _s(16, 10, 13, 13, 17, 'Collections génériques'),
      ],
    ),
    CoursSuivi(
      code: 'INF215',
      intitule: 'Réseaux informatiques',
      enseignant: 'Dr Alain Bulambo',
      grade: 'Professeur Associé',
      credits: 4,
      volume: 30,
      seances: [
        _s(21, 10, 1, 8, 10, 'Modèle OSI et TCP/IP'),
        _s(22, 10, 8, 8, 10, 'Adressage IPv4 et sous-réseaux'),
        _s(23, 10, 12, 8, 10, 'Routage statique', preuve: 'registre_12-10.jpg'),
      ],
    ),
    CoursSuivi(
      code: 'INF230',
      intitule: 'Génie logiciel',
      enseignant: 'Dr Esther Namwira',
      grade: 'Professeur Associé',
      credits: 4,
      volume: 30,
    ),
    CoursSuivi(
      code: 'MAT215',
      intitule: 'Probabilités et statistiques',
      enseignant: 'Pr Joseph Mushagalusa',
      grade: 'Professeur',
      credits: 4,
      volume: 30,
      seances: _blocs('m', 8, 13, [
        'Dénombrement',
        'Probabilités conditionnelles',
        'Variables aléatoires discrètes',
        'Lois usuelles',
        'Estimation ponctuelle',
        'Tests d\'hypothèses',
      ]),
    ),
    CoursSuivi(
      code: 'INF220',
      intitule: "Systèmes d'exploitation",
      enseignant: 'Pr Aimé Cirimwami',
      grade: 'Professeur Ordinaire',
      credits: 4,
      volume: 30,
      cloture: true,
      seances: _blocs('o', 8, 13, [
        'Processus et threads',
        'Ordonnancement',
        'Synchronisation',
        'Gestion de la mémoire',
        'Systèmes de fichiers',
        'Entrées / sorties',
      ]),
    ),
  ];

  // ── Compteurs ──
  int get nbCoursActifs =>
      cours.where((c) => c.statut != StatutCours.cloture).length;
  int get nbAValider => cours.fold(0, (s, c) => s + c.nbEncodees);
  double get totalHeures => cours.fold(0.0, (s, c) => s + c.heuresPrestees);

  // ── Actions ──
  void addSeance(CoursSuivi c, Seance s) {
    c.seances.add(s);
    notifyListeners();
  }

  void touch() => notifyListeners();

  void deleteSeance(CoursSuivi c, Seance s) {
    c.seances.remove(s);
    notifyListeners();
  }

  /// Outil de démonstration : l'enseignant valide toutes les séances du cours.
  void simulerValidationEnseignant(CoursSuivi c) {
    for (final s in c.seances) {
      s.validee = true;
    }
    notifyListeners();
  }
}

final EtudiantStore etudiantStore = EtudiantStore();
