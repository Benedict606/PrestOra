import 'package:flutter/material.dart';
import 'package:prestora/app/view/prestation/student/etudiant_data.dart';
import 'package:prestora/app/view/teacher/enseignant_data.dart';

// ═══════════════════════════════════════════════════════════════
//  Circuit de paie partagé : Secrétaire → Doyen → VRA → Recteur → AG
//  PaieStore = faux dépôt commun, à remplacer par vos Cubits / Firebase.
// ═══════════════════════════════════════════════════════════════

/// « Aujourd'hui » figé pour que la démo soit reproductible.
final DateTime kMaintenant = DateTime(2026, 10, 15);

String fmtDate(DateTime d) =>
    '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

String fmtMontant(double v) =>
    '${v.toStringAsFixed(2).replaceAll('.', ',')} \$';

// ───────────────────────── Les 4 autorités ─────────────────────────
enum RoleAutorite {
  doyen(2, 'Doyen', 'Pr Fidèle Bashige', 'Sciences et Technologies', 'au VRA'),
  vra(3, 'Vice-recteur académique', 'Pr Claire Mukamba', null, 'au Recteur'),
  recteur(
    4,
    'Recteur',
    'Pr Samuel Kasereka',
    null,
    "à l'Administrateur général",
  ),
  ag(
    5,
    'Administrateur général',
    'M. Jonathan Mwamba',
    null,
    'à la Comptabilité',
  );

  const RoleAutorite(
    this.palier,
    this.titre,
    this.nom,
    this.faculte,
    this.suivant,
  );

  final int palier; // palier du circuit (2 à 5)
  final String titre;
  final String nom;
  final String? faculte; // non null = limité à une faculté (Doyen)
  final String suivant; // destinataire après validation

  String get court =>
      kActeursCourts[palier - 1]; // « Doyen », « VRA », « Recteur », « AG »
  String get initiale => nom.split(' ').length > 1
      ? nom.split(' ')[1].substring(0, 1)
      : nom.substring(0, 1);
}

/// Nom de la personne qui occupe un palier (pour « rejeté par … »).
String nomDuPalier(int palier) {
  if (palier == 1) return 'Mme Rachel Zawadi';
  if (palier == 6) return 'Mme Nadine Kahindo';
  return RoleAutorite.values.firstWhere((r) => r.palier == palier).nom;
}

// ───────────────────────── Modèles ─────────────────────────
/// Cours clôturé par l'encadreur, en attente d'initialisation du dossier par le secrétaire.
class CoursTermine {
  CoursTermine({
    required this.code,
    required this.intitule,
    required this.promotion,
    required this.faculte,
    required this.enseignant,
    required this.grade,
    required this.taux,
    required this.credits,
    required this.volume,
    required this.seances,
    required this.mode,
    required this.coordonnees,
  });

  final String code;
  final String intitule;
  final String promotion;
  final String faculte;
  final String enseignant;
  final String grade;
  final double taux;
  final int credits;
  final int volume;
  final List<Seance> seances;
  final String
  mode; // « Banque » ou « Mobile Money » (pré-rempli depuis le profil)
  final String coordonnees;

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
    this.palierCourant = 1,
    this.palierRejet,
    this.motifRejet,
    this.referencePaiement,
    Map<int, DateTime>? dates,
    List<String>? pieces,
  }) : dates = dates ?? {},
       pieces =
           pieces ??
           [
             for (final s in seances)
               if (s.preuve != null) s.preuve!,
           ];

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
  final List<String> pieces;

  // Renseignés par la Comptabilité à la clôture
  String? modeReglement; // Virement bancaire / Bon de caisse / Mobile Money
  String? bordereau; // preuve de paiement (fichier)
  String? imputation; // imputation budgétaire (à valider)
  final List<String> historique = []; // anciens rejets (après correction)

  /// Vue « enseignant » du dossier : sert à la Timeline et aux pastilles déjà écrites.
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
    // dates: dates,
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

  String? get rejetePar => palierRejet == null
      ? null
      : '${kActeursCourts[palierRejet! - 1]} ${nomDuPalier(palierRejet!)}';
}

// ───────────────────────── Aides de fabrication ─────────────────────────
const _chap = [
  'Introduction',
  'Notions fondamentales',
  'Approfondissement',
  'Études de cas',
  'Travaux pratiques',
  'Révision',
  'Évaluation',
  'Synthèse',
  'Projet',
  'Mise en pratique',
  'Exercices dirigés',
  'Bilan',
];

List<Seance> _gen(String p, int volume, int h) {
  final n = volume ~/ h;
  return List.generate(
    n,
    (i) => Seance(
      id: '$p$i',
      date: DateTime(2026, 8, 20).add(Duration(days: i * 4)),
      debut: const TimeOfDay(hour: 8, minute: 0),
      fin: TimeOfDay(hour: 8 + h, minute: 0),
      chapitre: _chap[i % _chap.length],
      validee: true,
      preuve: 'registre_${p}_${i + 1}.jpg',
    ),
  );
}

/// Jours écoulés depuis l'initialisation, palier par palier (délais variables pour les statistiques).
const _decalage = [0, 2, 5, 7, 11, 13];

Map<int, DateTime> _dates(DateTime init, int upTo) => {
  for (var p = 1; p <= upTo; p++) p: init.add(Duration(days: _decalage[p - 1])),
};

DossierWf _d(
  String ref,
  String code,
  String intitule,
  String promo,
  String fac,
  String ens,
  String grade,
  int credits,
  int volume,
  double taux,
  int palier,
  DateTime init, {
  int h = 5,
  int? rejet,
  String? motif,
  String? refPaie,
  String mode = 'Mobile Money',
  String coord = '0990 000 002',
}) {
  final fait = rejet ?? (palier >= 7 ? 6 : palier - 1);
  final d = DossierWf(
    reference: ref,
    code: code,
    intitule: intitule,
    promotion: promo,
    faculte: fac,
    enseignant: ens,
    grade: grade,
    credits: credits,
    volume: volume,
    taux: taux,
    palierCourant: palier,
    dateInit: init,
    seances: _gen(code, volume, h),
    mode: mode,
    coordonnees: coord,
    palierRejet: rejet,
    motifRejet: motif,
    referencePaiement: refPaie,
    dates: _dates(init, fait),
  );
  if (palier >= 7) {
    d.modeReglement = mode == 'Banque' ? 'Virement bancaire' : 'Mobile Money';
    d.bordereau = 'bordereau_$ref.pdf';
  }
  return d;
}

CoursTermine _c(
  String code,
  String intitule,
  String promo,
  String ens,
  String grade,
  double taux,
  int credits,
  int volume,
  int h,
  String mode,
  String coord,
) => CoursTermine(
  code: code,
  intitule: intitule,
  promotion: promo,
  faculte: 'Sciences et Technologies',
  enseignant: ens,
  grade: grade,
  taux: taux,
  credits: credits,
  volume: volume,
  seances: _gen(code, volume, h),
  mode: mode,
  coordonnees: coord,
);

// ───────────────────────── Faux dépôt ─────────────────────────
class PaieStore extends ChangeNotifier {
  final String secretaireNom = 'Mme Rachel Zawadi';
  final String secretaireFaculte = 'Sciences et Technologies';
  int _seq = 171;

  final List<String> facultes = const [
    'Sciences et Technologies',
    'Droit',
    'Économie et Gestion',
    'Médecine',
  ];

  late final List<CoursTermine> coursTermines = [
    _c(
      'INF101',
      "Introduction à l'algorithmique",
      'L1 Informatique',
      'Dr Grâce Bahati',
      'Chef de Travaux',
      8,
      4,
      30,
      5,
      'Mobile Money',
      '0990 000 002',
    ),
    _c(
      'INF230',
      'Génie logiciel',
      'L2 Informatique',
      'Dr Esther Namwira',
      'Professeur Associé',
      10,
      4,
      30,
      5,
      'Mobile Money',
      '0990 000 004',
    ),
    _c(
      'INF104',
      'Anglais technique',
      'L1 Informatique',
      'M. Roger Mwenebatu',
      'Assistant',
      6,
      2,
      15,
      3,
      'Banque',
      'Equity · 3300-1122-45',
    ),
  ];

  late final List<DossierWf> dossiers = [
    _d(
      'UCB-2026-0156',
      'INF110',
      'Bureautique et internet',
      'L1 Informatique',
      'Sciences et Technologies',
      'Dr Grâce Bahati',
      'Chef de Travaux',
      3,
      15,
      8,
      2,
      DateTime(2026, 10, 8),
      h: 3,
    ),
    _d(
      'UCB-2026-0142',
      'INF120',
      'Structures de données',
      'L1 Informatique',
      'Sciences et Technologies',
      'Dr Grâce Bahati',
      'Chef de Travaux',
      4,
      30,
      8,
      5,
      DateTime(2026, 9, 28),
    ),
    _d(
      'UCB-2026-0119',
      'INF050',
      'Atelier de programmation',
      'L2 Informatique',
      'Sciences et Technologies',
      'Dr Grâce Bahati',
      'Chef de Travaux',
      3,
      15,
      8,
      3,
      DateTime(2026, 9, 14),
      h: 3,
      rejet: 3,
      motif:
          'Discordance entre les heures encodées (15 h) et la fiche de présence signée (12 h). Merci de corriger puis de réinitialiser le dossier.',
    ),
    _d(
      'UCB-2026-0087',
      'INF090',
      "Initiation à l'informatique",
      'L1 Informatique',
      'Sciences et Technologies',
      'Dr Grâce Bahati',
      'Chef de Travaux',
      3,
      20,
      8,
      7,
      DateTime(2026, 7, 10),
      h: 4,
      refPaie: 'MM-2026-0720-4471',
    ),
    _d(
      'UCB-2026-0160',
      'MAT215',
      'Probabilités et statistiques',
      'L2 Informatique',
      'Sciences et Technologies',
      'Pr Joseph Mushagalusa',
      'Professeur',
      4,
      30,
      11,
      2,
      DateTime(2026, 10, 9),
      mode: 'Banque',
      coord: 'Rawbank · 0045-7788-1200',
    ),
    _d(
      'UCB-2026-0163',
      'INF220',
      "Systèmes d'exploitation",
      'L2 Informatique',
      'Sciences et Technologies',
      'Pr Aimé Cirimwami',
      'Professeur Ordinaire',
      4,
      30,
      12,
      3,
      DateTime(2026, 10, 2),
      mode: 'Banque',
      coord: 'Banque Centrale · 0012-3456-7890',
    ),
    _d(
      'UCB-2026-0165',
      'INF215',
      'Réseaux informatiques',
      'L2 Informatique',
      'Sciences et Technologies',
      'Dr Alain Bulambo',
      'Professeur Associé',
      4,
      30,
      10,
      4,
      DateTime(2026, 9, 25),
      coord: '0990 000 007',
    ),
    _d(
      'UCB-2026-0170',
      'INF305',
      'Architecture logicielle',
      'L3 Informatique',
      'Sciences et Technologies',
      'Dr Grâce Bahati',
      'Chef de Travaux',
      4,
      30,
      8,
      1,
      DateTime(2026, 10, 12),
    ),
    _d(
      'UCB-2026-0131',
      'DRT110',
      'Introduction au droit civil',
      'L1 Droit',
      'Droit',
      'Dr Esther Namwira',
      'Professeur Associé',
      4,
      30,
      10,
      3,
      DateTime(2026, 10, 1),
      coord: '0990 000 004',
    ),
    _d(
      'UCB-2026-0138',
      'DRT320',
      'Droit international public',
      'L3 Droit public',
      'Droit',
      'Pr Joseph Mushagalusa',
      'Professeur',
      4,
      45,
      11,
      4,
      DateTime(2026, 9, 27),
      mode: 'Banque',
      coord: 'Rawbank · 0045-7788-1200',
    ),
    _d(
      'UCB-2026-0124',
      'DRT215',
      'Procédure pénale',
      'L2 Droit',
      'Droit',
      'Dr Esther Namwira',
      'Professeur Associé',
      3,
      30,
      10,
      5,
      DateTime(2026, 9, 20),
      coord: '0990 000 004',
    ),
    _d(
      'UCB-2026-0149',
      'ECO120',
      'Microéconomie',
      'L1 Économie',
      'Économie et Gestion',
      'Dr Dieudonné Rugarama',
      'Professeur Associé',
      5,
      45,
      10,
      3,
      DateTime(2026, 10, 3),
      coord: '0990 000 011',
    ),
    _d(
      'UCB-2026-0127',
      'GES240',
      'Management des organisations',
      'L2 Gestion',
      'Économie et Gestion',
      'Pr Alphonse Mulume',
      'Professeur',
      4,
      30,
      11,
      6,
      DateTime(2026, 9, 15),
      mode: 'Banque',
      coord: 'Equity · 3300-8899-12',
    ),
    _d(
      'UCB-2026-0152',
      'MED210',
      'Anatomie descriptive',
      'L2 Médecine',
      'Médecine',
      'Pr Placide Cizungu',
      'Professeur Ordinaire',
      6,
      60,
      12,
      4,
      DateTime(2026, 10, 5),
      mode: 'Banque',
      coord: 'Rawbank · 0045-1100-77',
    ),
    _d(
      'UCB-2026-0144',
      'SPB110',
      'Épidémiologie générale',
      'L1 Santé publique',
      'Médecine',
      'Dr Fabrice Lunanga',
      'Chef de Travaux',
      3,
      30,
      8,
      2,
      DateTime(2026, 10, 10),
      coord: '0990 000 015',
    ),
    // ── Dossiers chez la Comptabilité ──
    _d(
      'UCB-2026-0121',
      'INF140',
      "Algèbre pour l'informatique",
      'L1 Informatique',
      'Sciences et Technologies',
      'Pr Joseph Mushagalusa',
      'Professeur',
      4,
      30,
      11,
      6,
      DateTime(2026, 9, 20),
      mode: 'Banque',
      coord: 'Rawbank · 0045-7788-1200',
    ),
    _d(
      'UCB-2026-0133',
      'DRT130',
      'Droit constitutionnel',
      'L1 Droit',
      'Droit',
      'Dr Esther Namwira',
      'Professeur Associé',
      4,
      30,
      10,
      6,
      DateTime(2026, 10, 1),
      coord: '0990 000 004',
    ),
    _d(
      'UCB-2026-0136',
      'MED120',
      'Biochimie générale',
      'L1 Santé publique',
      'Médecine',
      'Pr Placide Cizungu',
      'Professeur Ordinaire',
      5,
      45,
      12,
      6,
      DateTime(2026, 9, 28),
      mode: 'Banque',
      coord: 'Rawbank · 0045-1100-77',
    ),
    // ── Dossiers déjà payés ──
    _d(
      'UCB-2026-0099',
      'DRT105',
      'Introduction à la sociologie',
      'L1 Droit',
      'Droit',
      'Dr Esther Namwira',
      'Professeur Associé',
      3,
      20,
      10,
      7,
      DateTime(2026, 9, 28),
      h: 4,
      refPaie: 'MM-2026-1011-118',
      coord: '0990 000 004',
    ),
    _d(
      'UCB-2026-0102',
      'ECO105',
      'Statistiques descriptives',
      'L1 Économie',
      'Économie et Gestion',
      'Pr Alphonse Mulume',
      'Professeur',
      4,
      30,
      11,
      7,
      DateTime(2026, 9, 30),
      refPaie: 'VIR-2026-1013-052',
      mode: 'Banque',
      coord: 'Equity · 3300-8899-12',
    ),
    // ── Rejeté par la Comptabilité ──
    _d(
      'UCB-2026-0108',
      'INF060',
      'Initiation au Web',
      'L1 Informatique',
      'Sciences et Technologies',
      'Dr Grâce Bahati',
      'Chef de Travaux',
      3,
      15,
      8,
      6,
      DateTime(2026, 9, 22),
      h: 3,
      rejet: 6,
      motif:
          "Numéro Mobile Money invalide : le transfert a été refusé par l'opérateur. Merci de vérifier le numéro avec l'enseignant.",
    ),
  ];

  // ═══ Requêtes Autorité ═══
  bool _dansPortee(RoleAutorite r, DossierWf d) =>
      r.faculte == null || d.faculte == r.faculte;

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

  // ═══ Requêtes Comptabilité (palier 6) ═══
  String get comptableNom => 'Mme Nadine Kahindo';

  List<DossierWf> get aPayer => dossiers
      .where((d) => d.palierRejet == null && d.palierCourant == 6)
      .toList();

  /// Dossiers déjà traités par la Comptabilité (payés ou rejetés).
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

  // ═══ Requêtes Secrétaire ═══
  List<CoursTermine> get coursAInitialiser =>
      coursTermines.where((c) => c.faculte == secretaireFaculte).toList();

  List<DossierWf> get dossiersSec =>
      dossiers.where((d) => d.faculte == secretaireFaculte).toList();
  List<DossierWf> get dossiersEnCircuit =>
      dossiersSec.where((d) => d.palierRejet == null).toList();
  List<DossierWf> get dossiersRejetes =>
      dossiersSec.where((d) => d.palierRejet != null).toList();
  int get nbPayes =>
      dossiersSec.where((d) => d.statut == StatutDossier.paye).length;

  // ═══ Actions ═══
  void initialiser(
    CoursTermine c, {
    required String mode,
    required String coordonnees,
    required DateTime date,
  }) {
    final ref = 'UCB-2026-0${_seq++}';
    dossiers.insert(
      0,
      DossierWf(
        reference: ref,
        code: c.code,
        intitule: c.intitule,
        promotion: c.promotion,
        faculte: c.faculte,
        enseignant: c.enseignant,
        grade: c.grade,
        credits: c.credits,
        volume: c.volume,
        seances: c.seances,
        taux: c.taux,
        mode: mode,
        coordonnees: coordonnees,
        dateInit: date,
      ),
    );
    coursTermines.remove(c);
    notifyListeners();
  }

  /// Secrétaire : INITIALISE → chez le Doyen.
  void soumettre(DossierWf d) {
    d.dates[1] = kMaintenant;
    d.palierCourant = 2;
    notifyListeners();
  }

  /// Autorité : valide et passe au palier suivant.
  void valider(DossierWf d) {
    d.dates[d.palierCourant] = kMaintenant;
    d.palierCourant += 1;
    notifyListeners();
  }

  /// Comptabilité : enregistre le règlement et clôture le dossier (PAYÉ, définitif).
  void payer(
    DossierWf d, {
    required String reference,
    required DateTime date,
    required String modeReglement,
    required String bordereau,
    String? imputation,
  }) {
    d.referencePaiement = reference;
    d.modeReglement = modeReglement;
    d.bordereau = bordereau;
    d.imputation = imputation;
    d.dates[6] = date;
    d.palierCourant = 7;
    notifyListeners();
  }

  /// Autorité : rejette avec motif (retour au secrétaire).
  void rejeter(DossierWf d, String motif) {
    d.dates[d.palierCourant] = kMaintenant;
    d.palierRejet = d.palierCourant;
    d.motifRejet = motif;
    notifyListeners();
  }

  /// Secrétaire : corrige puis remet le dossier au palier qui a rejeté (règle à valider).
  void reinitialiser(
    DossierWf d, {
    required String mode,
    required String coordonnees,
    String? commentaire,
  }) {
    final p = d.palierRejet!;
    d.historique.add(
      'Rejeté par le ${kActeursCourts[p - 1]} le ${fmtDate(d.dates[p] ?? kMaintenant)} : ${d.motifRejet ?? ''}'
      '${(commentaire == null || commentaire.isEmpty) ? '' : '\nCorrection : $commentaire'}',
    );
    d.mode = mode;
    d.coordonnees = coordonnees;
    d.palierCourant = p;
    d.palierRejet = null;
    d.motifRejet = null;
    d.dates.remove(p);
    notifyListeners();
  }

  void touch() => notifyListeners();
}

final PaieStore paieStore = PaieStore();
