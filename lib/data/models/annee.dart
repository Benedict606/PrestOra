import 'package:prestora/data/firebase/fb.dart';

enum StatutAnnee {
  planifiee('PLANIFIEE', 'Planifiée'),
  active('ACTIVE', 'Active'),
  cloturee('CLOTUREE', 'Clôturée');

  const StatutAnnee(this.code, this.label);
  final String code;
  final String label;

  static StatutAnnee from(String? c) => StatutAnnee.values.firstWhere(
    (s) => s.code == c,
    orElse: () => StatutAnnee.planifiee,
  );
}

/// Une année académique. L'identifiant du document est son libellé
/// (« 2026-2027 »), unique et lisible.
class AnneeAcademique {
  AnneeAcademique({
    required this.id,
    required this.libelle,
    required this.debut,
    required this.fin,
    required this.statut,
    this.dateCloture,
  });

  final String id;
  final String libelle;
  final DateTime debut;
  final DateTime fin;
  final StatutAnnee statut;
  final DateTime? dateCloture;

  bool get estActive => statut == StatutAnnee.active;
  bool get estCloturee => statut == StatutAnnee.cloturee;
  bool get modifiable => statut != StatutAnnee.cloturee;

  /// Avancement de l'année entre ses dates (0..1).
  double get avancement {
    final total = fin.difference(debut).inSeconds;
    if (total <= 0) return 0;
    final fait = DateTime.now().difference(debut).inSeconds;
    return (fait / total).clamp(0.0, 1.0);
  }

  factory AnneeAcademique.fromDoc(String id, Map<String, dynamic> m) =>
      AnneeAcademique(
        id: id,
        libelle: (m['libelle'] as String?) ?? id,
        debut: Fb.date(m['date_debut']) ?? DateTime.now(),
        fin: Fb.date(m['date_fin']) ?? DateTime.now(),
        statut: StatutAnnee.from(m['statut'] as String?),
        dateCloture: Fb.date(m['date_cloture']),
      );

  /// Propose le libellé suivant : « 2026-2027 » → « 2027-2028 ».
  static String suivant(String? libelle) {
    final m = RegExp(r'^(\d{4})-(\d{4})$').firstMatch(libelle ?? '');
    if (m == null) {
      final y = DateTime.now().year;
      return '$y-${y + 1}';
    }
    final a = int.parse(m.group(1)!) + 1;
    return '$a-${a + 1}';
  }
}

/// Un cours programmé pour une année donnée (offre de cours).
class OffreCours {
  OffreCours({
    required this.id,
    required this.anneeId,
    required this.coursId,
    required this.code,
    required this.intitule,
    required this.credits,
    required this.volume,
    required this.faculteId,
    required this.faculteNom,
    required this.promotionId,
    required this.promotionNom,
  });

  final String id;
  final String anneeId;
  final String coursId;
  final String code;
  final String intitule;
  final int credits;
  final int volume;
  final String faculteId;
  final String faculteNom;
  final String promotionId;
  final String promotionNom;

  factory OffreCours.fromDoc(String id, Map<String, dynamic> m) => OffreCours(
    id: id,
    anneeId: (m['annee_id'] as String?) ?? '',
    coursId: (m['cours_id'] as String?) ?? '',
    code: (m['code'] as String?) ?? '',
    intitule: (m['intitule'] as String?) ?? '',
    credits: (m['credits'] as num?)?.toInt() ?? 0,
    volume: (m['volume'] as num?)?.toInt() ?? 0,
    faculteId: (m['faculte_id'] as String?) ?? '',
    faculteNom: (m['faculte_nom'] as String?) ?? '',
    promotionId: (m['promotion_id'] as String?) ?? '',
    promotionNom: (m['promotion_nom'] as String?) ?? '',
  );
}

/// Ligne du catalogue permanent des cours (collection `cours`).
class CoursCatalogue {
  CoursCatalogue({
    required this.id,
    required this.code,
    required this.intitule,
    required this.credits,
    required this.volume,
    required this.faculteId,
    required this.faculteNom,
    required this.promotionId,
    required this.promotionNom,
  });

  final String id;
  final String code;
  final String intitule;
  final int credits;
  final int volume;
  final String faculteId;
  final String faculteNom;
  final String promotionId;
  final String promotionNom;

  factory CoursCatalogue.fromDoc(String id, Map<String, dynamic> m) =>
      CoursCatalogue(
        id: id,
        code: (m['code_cours'] as String?) ?? id,
        intitule: (m['intitule_exact'] as String?) ?? '',
        credits: (m['credits'] as num?)?.toInt() ?? 0,
        volume: (m['volume_horaire_max'] as num?)?.toInt() ?? 0,
        faculteId: (m['faculte_id'] as String?) ?? '',
        faculteNom: (m['faculte_nom'] as String?) ?? '',
        promotionId: (m['promotion_id'] as String?) ?? '',
        promotionNom: (m['promotion_nom'] as String?) ?? '',
      );
}
