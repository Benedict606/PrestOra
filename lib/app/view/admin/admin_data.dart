import 'package:flutter/foundation.dart';

// ═══════════════════════════════════════════════════════════════
//  Modèles + données fictives de l'espace Administrateur.
//  AdminStore joue le rôle de "faux dépôt" : il sera remplacé par
//  vos Cubits / repositories (Firebase) plus tard.
// ═══════════════════════════════════════════════════════════════

const kGrades = <String>[
  'Assistant',
  'Chef de Travaux',
  'Professeur Associé',
  'Professeur',
  'Professeur Ordinaire',
];

const kTitres = <String>['Pr', 'Dr', 'M.', 'Mme'];

String fmtDate(DateTime d) =>
    '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

String fmtTaux(double v) => '${v.toStringAsFixed(v % 1 == 0 ? 0 : 2)} \$/h';

// ───────────────────────── Types de compte ─────────────────────────
enum TypeCompte {
  chefPromotion('Chef de promotion'),
  encadreur('Encadreur pédagogique'),
  enseignant('Enseignant visiteur'),
  secretaire('Secrétaire de faculté'),
  doyen('Doyen'),
  vra('Vice-recteur académique'),
  recteur('Recteur'),
  ag('Administrateur général'),
  comptabilite('Comptabilité'),
  administrateur('Administrateur système');

  const TypeCompte(this.label);
  final String label;

  /// Rôles globaux : aucune faculté associée.
  bool get isGlobal => const [
    TypeCompte.vra,
    TypeCompte.recteur,
    TypeCompte.ag,
    TypeCompte.comptabilite,
    TypeCompte.administrateur,
  ].contains(this);

  bool get needsFaculte => !isGlobal;
  bool get needsPromotion => this == TypeCompte.chefPromotion;
  bool get isEnseignant => this == TypeCompte.enseignant;
}

// ───────────────────────── Modèles ─────────────────────────
class Compte {
  Compte({
    required this.id,
    required this.nom,
    required this.email,
    required this.type,
    this.titre = '',
    this.telephone = '',
    this.faculte,
    this.promotion,
    this.grade,
    this.institution,
    this.modePaiement,
    this.coordonneesPaiement,
    this.actif = true,
  });

  final String id;
  String nom;
  String email;
  String titre;
  String telephone;
  TypeCompte type;
  String? faculte;
  String? promotion;
  String? grade;
  String? institution;
  String? modePaiement; // « Banque » ou « Mobile Money »
  String? coordonneesPaiement;
  bool actif;

  String get nomComplet => titre.isEmpty ? nom : '$titre $nom';

  String get initiales {
    final parts = nom.trim().split(RegExp(r'\s+'));
    final a = parts.first.isNotEmpty ? parts.first[0] : '';
    final b = parts.length > 1 && parts.last.isNotEmpty ? parts.last[0] : '';
    return (a + b).toUpperCase();
  }
}

class Promotion {
  Promotion({required this.nom, this.chef, this.nbCours = 0});
  String nom;
  String? chef;
  int nbCours;
}

class Departement {
  Departement({required this.nom, List<Promotion>? promotions})
    : promotions = promotions ?? [];
  String nom;
  final List<Promotion> promotions;
}

class Faculte {
  Faculte({
    required this.nom,
    required this.departements,
    this.doyen,
    this.secretaire,
  });
  String nom;
  String? doyen;
  String? secretaire;
  final List<Departement> departements;

  Iterable<Promotion> get promotions =>
      departements.expand((d) => d.promotions);
}

class Cours {
  Cours({
    required this.code,
    required this.intitule,
    required this.faculte,
    required this.promotion,
    required this.credits,
    required this.volume,
    this.affecte = false,
  });
  String code;
  String intitule;
  String faculte;
  String promotion;
  int credits;
  int volume;
  bool affecte;
}

class Bareme {
  Bareme({required this.grade, required this.taux});
  final String grade;
  double taux;
}

// ───────────────────────── Faux dépôt ─────────────────────────
class AdminStore extends ChangeNotifier {
  /// Compte connecté (ne peut pas se désactiver lui-même).
  final String currentUserId = 'c15';

  double? retenueFiscale; // % : « À définir » tant que null

  final List<String> historiqueBaremes = [
    '05/10/2026 · Professeur Ordinaire : 11 → 12 \$/h',
    '05/10/2026 · Professeur : 10 → 11 \$/h',
    '12/09/2026 · Création du barème initial (5 grades)',
  ];

  final List<Compte> comptes = [
    Compte(
      id: 'c01',
      titre: 'Pr',
      nom: 'Aimé Cirimwami',
      email: 'a.cirimwami@exemple.org',
      type: TypeCompte.enseignant,
      faculte: 'Sciences et Technologies',
      grade: 'Professeur Ordinaire',
      institution: 'Université de Kinshasa',
      modePaiement: 'Banque',
      coordonneesPaiement: 'Banque Centrale · 0012-3456-7890',
      telephone: '+243 990 000 001',
    ),
    Compte(
      id: 'c02',
      titre: 'Dr',
      nom: 'Grâce Bahati',
      email: 'g.bahati@exemple.org',
      type: TypeCompte.enseignant,
      faculte: 'Sciences et Technologies',
      grade: 'Chef de Travaux',
      institution: 'ULPGL Goma',
      modePaiement: 'Mobile Money',
      coordonneesPaiement: '0990 000 002',
      telephone: '+243 990 000 002',
    ),
    Compte(
      id: 'c03',
      titre: 'Pr',
      nom: 'Joseph Mushagalusa',
      email: 'j.mushagalusa@exemple.org',
      type: TypeCompte.enseignant,
      faculte: 'Droit',
      grade: 'Professeur',
      institution: 'Université Officielle de Bukavu',
      modePaiement: 'Banque',
      coordonneesPaiement: 'Rawbank · 0045-7788-1200',
      telephone: '+243 990 000 003',
    ),
    Compte(
      id: 'c04',
      titre: 'Dr',
      nom: 'Esther Namwira',
      email: 'e.namwira@exemple.org',
      type: TypeCompte.enseignant,
      faculte: 'Droit',
      grade: 'Professeur Associé',
      institution: 'Université de Lubumbashi',
      modePaiement: 'Mobile Money',
      coordonneesPaiement: '0990 000 004',
      telephone: '+243 990 000 004',
    ),
    Compte(
      id: 'c05',
      titre: 'M.',
      nom: 'David Safari',
      email: 'd.safari@exemple.org',
      type: TypeCompte.enseignant,
      faculte: 'Économie et Gestion',
      grade: 'Assistant',
      institution: 'ISP Bukavu',
      modePaiement: 'Banque',
      coordonneesPaiement: 'Equity · 3300-1122-45',
      actif: false,
    ),
    Compte(
      id: 'c06',
      nom: 'Patrick Bisimwa',
      email: 'p.bisimwa@exemple.org',
      type: TypeCompte.chefPromotion,
      faculte: 'Sciences et Technologies',
      promotion: 'L2 Informatique',
    ),
    Compte(
      id: 'c07',
      nom: 'Christelle Mapendo',
      email: 'c.mapendo@exemple.org',
      type: TypeCompte.chefPromotion,
      faculte: 'Droit',
      promotion: 'L1 Droit',
    ),
    Compte(
      id: 'c08',
      titre: 'Dr',
      nom: 'Olivier Kabano',
      email: 'o.kabano@exemple.org',
      type: TypeCompte.encadreur,
      faculte: 'Sciences et Technologies',
    ),
    Compte(
      id: 'c09',
      titre: 'Mme',
      nom: 'Rachel Zawadi',
      email: 'r.zawadi@exemple.org',
      type: TypeCompte.secretaire,
      faculte: 'Sciences et Technologies',
    ),
    Compte(
      id: 'c10',
      titre: 'Pr',
      nom: 'Fidèle Bashige',
      email: 'f.bashige@exemple.org',
      type: TypeCompte.doyen,
      faculte: 'Sciences et Technologies',
    ),
    Compte(
      id: 'c11',
      titre: 'Pr',
      nom: 'Claire Mukamba',
      email: 'c.mukamba@exemple.org',
      type: TypeCompte.vra,
    ),
    Compte(
      id: 'c12',
      titre: 'Pr',
      nom: 'Samuel Kasereka',
      email: 's.kasereka@exemple.org',
      type: TypeCompte.recteur,
    ),
    Compte(
      id: 'c13',
      titre: 'M.',
      nom: 'Jonathan Mwamba',
      email: 'j.mwamba@exemple.org',
      type: TypeCompte.ag,
    ),
    Compte(
      id: 'c14',
      titre: 'Mme',
      nom: 'Nadine Kahindo',
      email: 'n.kahindo@exemple.org',
      type: TypeCompte.comptabilite,
    ),
    Compte(
      id: 'c15',
      nom: 'Léa Murhula',
      email: 'l.murhula@exemple.org',
      type: TypeCompte.administrateur,
    ),
  ];

  final List<Faculte> facultes = [
    Faculte(
      nom: 'Sciences et Technologies',
      doyen: 'Pr Fidèle Bashige',
      secretaire: 'Mme Rachel Zawadi',
      departements: [
        Departement(
          nom: 'Informatique',
          promotions: [
            Promotion(
              nom: 'L1 Informatique',
              chef: 'Aline Kitumaini',
              nbCours: 2,
            ),
            Promotion(
              nom: 'L2 Informatique',
              chef: 'Patrick Bisimwa',
              nbCours: 1,
            ),
            Promotion(nom: 'L3 Informatique', nbCours: 1),
          ],
        ),
        Departement(
          nom: 'Mathématiques',
          promotions: [
            Promotion(
              nom: 'L1 Mathématiques',
              chef: 'Jean Bulonza',
              nbCours: 1,
            ),
          ],
        ),
      ],
    ),
    Faculte(
      nom: 'Droit',
      doyen: 'Pr Béatrice Cikuru',
      secretaire: 'M. Gustave Namega',
      departements: [
        Departement(
          nom: 'Droit privé',
          promotions: [
            Promotion(nom: 'L1 Droit', chef: 'Christelle Mapendo', nbCours: 1),
            Promotion(nom: 'L2 Droit', nbCours: 1),
          ],
        ),
        Departement(
          nom: 'Droit public',
          promotions: [
            Promotion(nom: 'L3 Droit public', chef: 'Éric Cishugi', nbCours: 1),
          ],
        ),
      ],
    ),
    Faculte(
      nom: 'Économie et Gestion',
      doyen: 'Pr Hélène Lwango',
      secretaire: 'Mme Sylvie Mwanvua',
      departements: [
        Departement(
          nom: 'Gestion',
          promotions: [
            Promotion(nom: 'L1 Gestion', chef: 'Sarah Nabintu', nbCours: 1),
            Promotion(nom: 'L2 Gestion', nbCours: 1),
          ],
        ),
        Departement(
          nom: 'Économie',
          promotions: [
            Promotion(nom: 'L1 Économie', chef: 'Moïse Lwango', nbCours: 1),
          ],
        ),
      ],
    ),
    Faculte(
      nom: 'Médecine',
      doyen: 'Pr Désiré Bahizire',
      secretaire: 'Mme Pauline Chimanuka',
      departements: [
        Departement(
          nom: 'Santé publique',
          promotions: [
            Promotion(
              nom: 'L1 Santé publique',
              chef: 'Bénie Aksanti',
              nbCours: 1,
            ),
          ],
        ),
        Departement(
          nom: 'Médecine générale',
          promotions: [Promotion(nom: 'L2 Médecine', nbCours: 1)],
        ),
      ],
    ),
  ];

  final List<Cours> cours = [
    Cours(
      code: 'INF101',
      intitule: "Introduction à l'algorithmique",
      faculte: 'Sciences et Technologies',
      promotion: 'L1 Informatique',
      credits: 4,
      volume: 30,
      affecte: true,
    ),
    Cours(
      code: 'INF102',
      intitule: 'Architecture des ordinateurs',
      faculte: 'Sciences et Technologies',
      promotion: 'L1 Informatique',
      credits: 3,
      volume: 30,
    ),
    Cours(
      code: 'INF204',
      intitule: 'Bases de données relationnelles',
      faculte: 'Sciences et Technologies',
      promotion: 'L2 Informatique',
      credits: 5,
      volume: 45,
      affecte: true,
    ),
    Cours(
      code: 'INF305',
      intitule: 'Génie logiciel',
      faculte: 'Sciences et Technologies',
      promotion: 'L3 Informatique',
      credits: 4,
      volume: 30,
    ),
    Cours(
      code: 'MAT101',
      intitule: 'Analyse mathématique I',
      faculte: 'Sciences et Technologies',
      promotion: 'L1 Mathématiques',
      credits: 6,
      volume: 60,
      affecte: true,
    ),
    Cours(
      code: 'DRT110',
      intitule: 'Introduction au droit civil',
      faculte: 'Droit',
      promotion: 'L1 Droit',
      credits: 4,
      volume: 30,
      affecte: true,
    ),
    Cours(
      code: 'DRT215',
      intitule: 'Procédure pénale',
      faculte: 'Droit',
      promotion: 'L2 Droit',
      credits: 3,
      volume: 30,
    ),
    Cours(
      code: 'DRT320',
      intitule: 'Droit international public',
      faculte: 'Droit',
      promotion: 'L3 Droit public',
      credits: 4,
      volume: 45,
      affecte: true,
    ),
    Cours(
      code: 'ECO120',
      intitule: 'Microéconomie',
      faculte: 'Économie et Gestion',
      promotion: 'L1 Économie',
      credits: 5,
      volume: 45,
      affecte: true,
    ),
    Cours(
      code: 'GES130',
      intitule: 'Comptabilité générale',
      faculte: 'Économie et Gestion',
      promotion: 'L1 Gestion',
      credits: 5,
      volume: 45,
    ),
    Cours(
      code: 'GES240',
      intitule: 'Management des organisations',
      faculte: 'Économie et Gestion',
      promotion: 'L2 Gestion',
      credits: 4,
      volume: 30,
      affecte: true,
    ),
    Cours(
      code: 'SPB110',
      intitule: 'Épidémiologie générale',
      faculte: 'Médecine',
      promotion: 'L1 Santé publique',
      credits: 3,
      volume: 30,
    ),
    Cours(
      code: 'MED210',
      intitule: 'Anatomie descriptive',
      faculte: 'Médecine',
      promotion: 'L2 Médecine',
      credits: 6,
      volume: 60,
      affecte: true,
    ),
  ];

  final List<Bareme> baremes = [
    Bareme(grade: 'Assistant', taux: 6),
    Bareme(grade: 'Chef de Travaux', taux: 8),
    Bareme(grade: 'Professeur Associé', taux: 10),
    Bareme(grade: 'Professeur', taux: 11),
    Bareme(grade: 'Professeur Ordinaire', taux: 12),
  ];

  // ── Compteurs du hub ──
  int get comptesActifs => comptes.where((c) => c.actif).length;
  int get comptesInactifs => comptes.length - comptesActifs;

  // ── Aides ──
  List<String> promotionsOf(String? faculteNom) {
    final f = facultes.where((f) => f.nom == faculteNom);
    if (f.isEmpty) return [];
    return f.first.promotions.map((p) => p.nom).toList();
  }

  int coursOf(String faculteNom) =>
      cours.where((c) => c.faculte == faculteNom).length;

  // ── Actions (déclenchent la mise à jour de l'interface) ──
  void toggleCompte(Compte c) {
    c.actif = !c.actif;
    notifyListeners();
  }

  void addCompte(Compte c) {
    comptes.insert(0, c);
    notifyListeners();
  }

  void touch() => notifyListeners(); // après modification d'un objet existant

  void addFaculte(String nom) {
    facultes.add(Faculte(nom: nom, departements: []));
    notifyListeners();
  }

  void addDepartement(Faculte f, String nom) {
    f.departements.add(Departement(nom: nom));
    notifyListeners();
  }

  void addPromotion(Departement d, String nom) {
    d.promotions.add(Promotion(nom: nom));
    notifyListeners();
  }

  void addCours(Cours c) {
    cours.insert(0, c);
    notifyListeners();
  }

  void setTaux(Bareme b, double nouveau, DateTime effet) {
    historiqueBaremes.insert(
      0,
      '${fmtDate(effet)} · ${b.grade} : ${b.taux.toStringAsFixed(b.taux % 1 == 0 ? 0 : 2)} → ${nouveau.toStringAsFixed(nouveau % 1 == 0 ? 0 : 2)} \$/h',
    );
    b.taux = nouveau;
    notifyListeners();
  }

  void setRetenue(double v) {
    retenueFiscale = v;
    notifyListeners();
  }
}

/// Instance unique pour la démo.
final AdminStore adminStore = AdminStore();
