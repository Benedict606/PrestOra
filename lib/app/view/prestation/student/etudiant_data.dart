import 'package:flutter/material.dart';
import 'package:prestora/data/repositories/suivi_repository.dart';
import 'package:prestora/data/repositories/suivi_store_base.dart';
import 'package:prestora/data/services/session.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// ═══════════════════════════════════════════════════════════════
//  Modèles du suivi des prestations + dépôt du chef de promotion.
//  Les données viennent de Firestore (sessions_suivi / seances) pour
//  l'année académique ACTIVE.
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

enum TypeSeance {
  cm('CM'),
  td('TD'),
  tp('TP');

  const TypeSeance(this.label);
  final String label;

  static TypeSeance from(String? l) => TypeSeance.values.firstWhere(
    (t) => t.label == l,
    orElse: () => TypeSeance.cm,
  );
}

enum StatutCours { enCours, valideParEnseignant, cloture }

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
    this.preuveId,
    this.encodeParId,
  });

  final String id;
  DateTime date;
  TimeOfDay debut;
  TimeOfDay fin;
  String chapitre;
  TypeSeance type;
  bool validee; // valide_par_prof
  String? preuve; // nom du fichier de la photo du registre
  String? preuveId; // document de la collection `pieces`
  String? encodeParId;

  double get heures => (minutesOf(fin) - minutesOf(debut)) / 60;
  String get tranche => '${fmtHeure(debut)} – ${fmtHeure(fin)}';

  /// Met à jour cet objet depuis un document Firestore.
  void applyMap(Map<String, dynamic> m) {
    final d = m['date'];
    if (d is Timestamp) date = d.toDate();
    final a = (m['debut'] as num?)?.toInt() ?? 0;
    final b = (m['fin'] as num?)?.toInt() ?? 0;
    debut = TimeOfDay(hour: a ~/ 60, minute: a % 60);
    fin = TimeOfDay(hour: b ~/ 60, minute: b % 60);
    chapitre = (m['chapitre'] as String?) ?? '';
    type = TypeSeance.from(m['type_seance'] as String?);
    validee = m['valide_par_prof'] == true;
    preuve = m['preuve_nom'] as String?;
    preuveId = m['preuve_id'] as String?;
    encodeParId = m['encode_par_id'] as String?;
  }
}

class CoursSuivi {
  CoursSuivi({
    this.id = '',
    required this.code,
    required this.intitule,
    required this.enseignant,
    required this.grade,
    required this.credits,
    required this.volume,
    List<Seance>? seances,
    this.cloture = false,
    this.enseignantId = '',
    this.chefId,
    this.chefNom,
    this.coursId = '',
    this.promotionId = '',
    this.promotionNom = '',
    this.anneeId = '',
    this.faculteId = '',
  }) : seances = seances ?? [];

  String id; // identifiant de la session Firestore
  String code;
  String intitule;
  String enseignant; // titre + nom
  String grade;
  int credits;
  int volume; // volume_horaire_max (de l'offre de l'année)
  final List<Seance> seances;
  bool cloture; // est_cloturee (par l'encadreur)
  String enseignantId;
  String? chefId;
  String? chefNom; // chef de promotion (nom complet)
  String coursId;
  String promotionId;
  String promotionNom;
  String anneeId;
  String faculteId;

  double get heuresPrestees => seances.fold(0.0, (s, e) => s + e.heures);
  double get heuresRestantes => volume - heuresPrestees;
  double get progression =>
      volume <= 0 ? 0 : (heuresPrestees / volume).clamp(0.0, 1.0);
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

  void applyMap(String sessionId, Map<String, dynamic> m) {
    id = sessionId;
    code = (m['code'] as String?) ?? '';
    intitule = (m['intitule'] as String?) ?? '';
    enseignant = (m['enseignant_nom'] as String?) ?? '';
    grade = (m['grade'] as String?) ?? '';
    credits = (m['credits'] as num?)?.toInt() ?? 0;
    volume = (m['volume'] as num?)?.toInt() ?? 0;
    cloture = m['est_cloturee'] == true;
    enseignantId = (m['enseignant_id'] as String?) ?? '';
    chefId = m['chef_promo_id'] as String?;
    chefNom = m['chef_promo_nom'] as String?;
    coursId = (m['cours_id'] as String?) ?? '';
    promotionId = (m['promotion_id'] as String?) ?? '';
    promotionNom = (m['promotion_nom'] as String?) ?? '';
    anneeId = (m['annee_id'] as String?) ?? '';
    faculteId = (m['faculte_id'] as String?) ?? '';
  }
}

// ───────────────────────── Dépôt du chef de promotion ─────────────────────────
class EtudiantStore extends SuiviStoreBase {
  String get nom => Session.instance.me?.nomComplet ?? '';
  String get promotion => Session.instance.promotionNom ?? '';
  String get faculte => Session.instance.faculteNom ?? '';
  String get initiale => nom.isEmpty ? '?' : nom.substring(0, 1).toUpperCase();

  List<CoursSuivi> get cours => hub.cours;

  @override
  Query<Map<String, dynamic>>? requete(String anneeId, String uid) =>
      sessionsQuery(anneeId).where('chef_promo_id', isEqualTo: uid);

  int get nbCoursActifs =>
      cours.where((c) => c.statut != StatutCours.cloture).length;
  int get nbAValider => cours.fold(0, (s, c) => s + c.nbEncodees);
  double get totalHeures => cours.fold(0.0, (s, c) => s + c.heuresPrestees);

  // ── Actions ──
  Future<bool> addSeance(CoursSuivi c, Seance s) =>
      SuiviRepository.instance.ajouterSeance(c, s);

  Future<bool> saveSeance(CoursSuivi c, Seance s) =>
      SuiviRepository.instance.modifierSeance(c, s);

  Future<bool> deleteSeance(CoursSuivi c, Seance s) =>
      SuiviRepository.instance.supprimerSeance(c, s);
}

final EtudiantStore etudiantStore = EtudiantStore();
