import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:prestora/app/view/admin/admin_data.dart';
import 'package:prestora/core/notify.dart';
import 'package:prestora/data/firebase/fb.dart';
import 'package:prestora/data/repositories/annee_repository.dart';
import 'package:prestora/data/services/auth_service.dart';
import 'package:prestora/data/services/session.dart';

/// Données de démonstration (mode debug) : facultés, promotions, cours,
/// barèmes et comptes de test. Idempotent : on peut relancer sans doublons.
/// À lancer depuis le compte ADMIN (bouton dans l'accueil Admin, en debug).
class DemoSeed {
  static const _structure = <String, Map<String, List<String>>>{
    'Sciences et Technologies': {
      'Informatique': ['L1 Informatique', 'L2 Informatique', 'L3 Informatique'],
      'Mathématiques': ['L1 Mathématiques'],
    },
    'Droit': {
      'Droit privé': ['L1 Droit', 'L2 Droit'],
      'Droit public': ['L3 Droit public'],
    },
    'Économie et Gestion': {
      'Gestion': ['L1 Gestion', 'L2 Gestion'],
      'Économie': ['L1 Économie'],
    },
    'Médecine': {
      'Santé publique': ['L1 Santé publique'],
      'Médecine générale': ['L2 Médecine'],
    },
  };

  // code, intitulé, faculté, promotion, crédits, volume
  static const _cours = <List<Object>>[
    ['INF101', "Introduction à l'algorithmique", 'Sciences et Technologies', 'L1 Informatique', 4, 30],
    ['INF102', 'Architecture des ordinateurs', 'Sciences et Technologies', 'L1 Informatique', 3, 30],
    ['INF103', 'Mathématiques discrètes', 'Sciences et Technologies', 'L1 Informatique', 4, 45],
    ['INF104', 'Anglais technique', 'Sciences et Technologies', 'L1 Informatique', 2, 15],
    ['INF204', 'Bases de données relationnelles', 'Sciences et Technologies', 'L2 Informatique', 5, 45],
    ['INF210', 'Programmation orientée objet', 'Sciences et Technologies', 'L2 Informatique', 5, 45],
    ['INF215', 'Réseaux informatiques', 'Sciences et Technologies', 'L2 Informatique', 4, 30],
    ['INF220', "Systèmes d'exploitation", 'Sciences et Technologies', 'L2 Informatique', 4, 30],
    ['INF230', 'Génie logiciel', 'Sciences et Technologies', 'L2 Informatique', 4, 30],
    ['MAT215', 'Probabilités et statistiques', 'Sciences et Technologies', 'L2 Informatique', 4, 30],
    ['INF305', 'Génie logiciel avancé', 'Sciences et Technologies', 'L3 Informatique', 4, 30],
    ['MAT101', 'Analyse mathématique I', 'Sciences et Technologies', 'L1 Mathématiques', 6, 60],
    ['DRT110', 'Introduction au droit civil', 'Droit', 'L1 Droit', 4, 30],
    ['DRT215', 'Procédure pénale', 'Droit', 'L2 Droit', 3, 30],
    ['DRT320', 'Droit international public', 'Droit', 'L3 Droit public', 4, 45],
    ['ECO120', 'Microéconomie', 'Économie et Gestion', 'L1 Économie', 5, 45],
    ['GES130', 'Comptabilité générale', 'Économie et Gestion', 'L1 Gestion', 5, 45],
    ['GES240', 'Management des organisations', 'Économie et Gestion', 'L2 Gestion', 4, 30],
    ['SPB110', 'Épidémiologie générale', 'Médecine', 'L1 Santé publique', 3, 30],
    ['MED210', 'Anatomie descriptive', 'Médecine', 'L2 Médecine', 6, 60],
  ];

  static const _taux = <String, double>{
    'Assistant': 6,
    'Chef de Travaux': 8,
    'Professeur Associé': 10,
    'Professeur': 11,
    'Professeur Ordinaire': 12,
  };

  // titre, nom, email, mot de passe, type, faculté, promotion, grade, institution, mode, coordonnées
  static const _comptes = <List<String?>>[
    ['Dr', 'Olivier Kabano', 'olivier.kabano@ucbukavu.ac.cd', 'Encadreur@2026', 'ENCADREUR', 'Sciences et Technologies', null, null, null, null, null],
    ['Dr', 'Grâce Bahati', 'g.bahati@exemple.org', 'Enseignant@2026', 'ENSEIGNANT', 'Sciences et Technologies', null, 'Chef de Travaux', 'ULPGL Goma', 'Mobile Money', '0990 000 002'],
    ['Pr', 'Aimé Cirimwami', 'a.cirimwami@exemple.org', 'Enseignant@2026', 'ENSEIGNANT', 'Sciences et Technologies', null, 'Professeur Ordinaire', 'Université de Kinshasa', 'Banque', 'Banque Centrale · 0012-3456-7890'],
    ['Pr', 'Joseph Mushagalusa', 'j.mushagalusa@exemple.org', 'Enseignant@2026', 'ENSEIGNANT', 'Sciences et Technologies', null, 'Professeur', 'Université Officielle de Bukavu', 'Banque', 'Rawbank · 0045-7788-1200'],
    ['Dr', 'Esther Namwira', 'e.namwira@exemple.org', 'Enseignant@2026', 'ENSEIGNANT', 'Sciences et Technologies', null, 'Professeur Associé', 'Université de Lubumbashi', 'Mobile Money', '0990 000 004'],
    ['Dr', 'Alain Bulambo', 'a.bulambo@exemple.org', 'Enseignant@2026', 'ENSEIGNANT', 'Sciences et Technologies', null, 'Professeur Associé', 'ISP Bukavu', 'Banque', 'Equity · 3300-1122-45'],
    ['', 'Patrick Bisimwa', 'p.bisimwa@exemple.org', 'Etudiant@2026', 'CHEF_PROMOTION', 'Sciences et Technologies', 'L2 Informatique', null, null, null, null],
    ['Mme', 'Rachel Zawadi', 'r.zawadi@exemple.org', 'Secretaire@2026', 'SECRETAIRE', 'Sciences et Technologies', null, null, null, null, null],
    ['Pr', 'Fidèle Bashige', 'fidele.bashige@ucbukavu.ac.cd', 'Doyen@2026', 'DOYEN', 'Sciences et Technologies', null, null, null, null, null],
    ['Pr', 'Claire Mukamba', 'claire.mukamba@ucbukavu.ac.cd', 'VRA@2026', 'VRA', null, null, null, null, null, null],
    ['Pr', 'Samuel Kasereka', 'samuel.kasereka@ucbukavu.ac.cd', 'Recteur@2026', 'RECTEUR', null, null, null, null, null, null],
    ['M.', 'Jonathan Mwamba', 'jonathan.mwamba@ucbukavu.ac.cd', 'AG@2026', 'AG', null, null, null, null, null, null],
    ['Mme', 'Nadine Kahindo', 'n.kahindo@exemple.org', 'Compta@2026', 'COMPTABILITE', null, null, null, null, null, null],
  ];

  static Future<String> run({void Function(String)? progress}) async {
    final db = Fb.db;
    void p(String m) => progress?.call(m);

    // 1) Référentiel
    p('Facultés, départements, promotions…');
    var batch = db.batch();
    for (final f in _structure.entries) {
      final fid = slug(f.key);
      batch.set(db.collection(Col.facultes).doc(fid), {
        'nom_faculte': f.key,
      }, SetOptions(merge: true));
      for (final d in f.value.entries) {
        final did = '${fid}__${slug(d.key)}';
        batch.set(db.collection(Col.departements).doc(did), {
          'faculte_id': fid,
          'nom': d.key,
        }, SetOptions(merge: true));
        for (final pr in d.value) {
          batch.set(db.collection(Col.promotions).doc('${fid}__${slug(pr)}'), {
            'faculte_id': fid,
            'departement_id': did,
            'nom': pr,
          }, SetOptions(merge: true));
        }
      }
    }
    await batch.commit();

    p('Cours du catalogue…');
    batch = db.batch();
    for (final c in _cours) {
      final fid = slug(c[2] as String);
      final pid = '${fid}__${slug(c[3] as String)}';
      batch.set(db.collection(Col.cours).doc(slug(c[0] as String)), {
        'code_cours': c[0],
        'intitule_exact': c[1],
        'faculte_id': fid,
        'faculte_nom': c[2],
        'promotion_id': pid,
        'promotion_nom': c[3],
        'credits': c[4],
        'volume_horaire_max': c[5],
        'est_archive': false,
      }, SetOptions(merge: true));
    }
    await batch.commit();

    p('Barèmes et retenue…');
    batch = db.batch();
    _taux.forEach((g, t) {
      batch.set(db.collection(Col.baremes).doc(g), {
        'grade_statutaire': g,
        'taux': t,
        'date_effet': Timestamp.now(),
      }, SetOptions(merge: true));
    });
    batch.set(db.collection(Col.parametres).doc('retenue_fiscale'), {
      'pourcentage': 5,
      'date_effet': Timestamp.now(),
    }, SetOptions(merge: true));
    await batch.commit();

    // 1 bis) Année 2026-2027 active avec tous les cours (si aucune année n'existe)
    if (Session.instance.annees.isEmpty) {
      p('Année 2026-2027…');
      final repo = AnneeRepository.instance;
      await repo.creer(
        libelle: '2026-2027',
        debut: DateTime(2026, 9, 1),
        fin: DateTime(2027, 7, 31),
      );
      await repo.ajouterOffres('2026-2027', await repo.catalogue());
      await repo.activer('2026-2027');
    }

    // 2) Comptes de démonstration
    var ok = 0;
    final echecs = <String>[];
    for (final c in _comptes) {
      p('Compte ${c[1]}…');
      try {
        final uid = await AuthService.createAccount(c[2]!, c[3]!);
        final type = TypeCompte.fromCode(c[4])!;
        final fid = c[5] == null ? null : slug(c[5]!);
        await db.collection(Col.utilisateurs).doc(uid).set({
          'nom': c[1],
          'titre': c[0],
          'email': c[2],
          'telephone': '',
          'type_utilisateur': c[4],
          'est_actif': true,
          'faculte_id': type.needsFaculte ? fid : null,
          'promotion_id': c[6] == null ? null : '${fid}__${slug(c[6]!)}',
          'grade_statutaire': c[7],
          'institution_origine': c[8],
          'peut_gerer_annees': false,
          'cree_le': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
        if (c[9] != null) {
          await db
              .collection(Col.utilisateurs)
              .doc(uid)
              .collection(Col.paiement)
              .doc('infos')
              .set({'mode': c[9], 'coordonnees': c[10]});
        }
        ok++;
      } catch (e) {
        echecs.add('${c[2]} : ${Notif.humaniser(e)}');
      }
    }
    return echecs.isEmpty
        ? 'Données de démonstration créées ($ok comptes).'
        : '$ok comptes créés. Échecs :\n${echecs.join('\n')}';
  }
}
