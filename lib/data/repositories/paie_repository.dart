import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:prestora/app/view/payslip/authority/paie_data.dart';
import 'package:prestora/app/view/prestation/student/etudiant_data.dart';
import 'package:prestora/app/view/teacher/enseignant_data.dart';
import 'package:prestora/core/notify.dart';
import 'package:prestora/data/firebase/fb.dart';
import 'package:prestora/data/repositories/notification_repository.dart';
import 'package:prestora/data/services/session.dart';

/// Écritures du circuit de paie. Chaque action est inscrite dans le journal
/// `validations` (ajout seulement) dans la même opération atomique.
class PaieRepository {
  PaieRepository._();
  static final PaieRepository instance = PaieRepository._();

  static const _roles = [
    'SECRETAIRE',
    'DOYEN',
    'VRA',
    'RECTEUR',
    'AG',
    'COMPTABILITE',
  ];

  DocumentReference<Map<String, dynamic>> _dossier(String id) =>
      Fb.db.collection(Col.dossiers).doc(id);

  Future<bool> _w(Future<dynamic> Function() f) async {
    try {
      await f();
      return true;
    } catch (e) {
      Notif.erreur(e);
      return false;
    }
  }

  double _arrondi(double v) => (v * 100).round() / 100;

  Map<String, dynamic> _journal(
    DossierWf d,
    int palier,
    String action, {
    String? motif,
  }) {
    final me = Session.instance.me!;
    return {
      'dossier_id': d.id,
      'annee_id': d.anneeId,
      'reference': d.reference,
      'palier': palier,
      'role': _roles[palier - 1],
      'action': action,
      'autorite_id': me.id,
      'autorite_nom': me.nomComplet,
      'motif': motif,
      'horodatage': FieldValue.serverTimestamp(),
    };
  }

  Future<bool> _agir(
    DossierWf d,
    Map<String, dynamic> maj,
    String action, {
    String? motif,
    int? palier,
  }) => _w(() async {
    final p = palier ?? d.palierCourant;
    final b = Fb.db.batch();
    b.update(_dossier(d.id), maj);
    b.set(
      Fb.db.collection(Col.validations).doc(),
      _journal(d, p, action, motif: motif),
    );
    await b.commit();
  });

  Map<String, dynamic> _acteur(int palier) => {
    'dates.$palier': Timestamp.now(),
    'acteurs.$palier': Session.instance.me!.nomComplet,
  };

  // ───────────── Secrétaire ─────────────
  /// Crée le dossier d'un cours clôturé. Référence unique par compteur
  /// transactionnel : UCB-2026-0001, 0002…
  Future<bool> initialiser(
    CoursTermine c, {
    required String mode,
    required String coordonnees,
    required DateTime date,
  }) => _w(() async {
    final annee = Session.instance.active;
    final me = Session.instance.me;
    final pct = Session.instance.retenue;
    if (annee == null || me == null) {
      throw Exception('Aucune année active.');
    }
    if (pct == null) {
      throw Exception(
        "La retenue fiscale n'est pas définie. L'administrateur doit la "
        'renseigner (Barèmes de taux horaire) avant toute initialisation.',
      );
    }
    if (c.taux <= 0) {
      throw Exception(
        "Le taux horaire du grade « ${c.grade} » n'est pas défini (Barèmes).",
      );
    }
    final heures = c.seances.fold(0.0, (s, e) => s + e.heures);
    final brut = _arrondi(heures * c.taux);
    final retenues = _arrondi(brut * pct / 100);
    final net = _arrondi(brut - retenues);
    final compteur = Fb.db.collection('compteurs').doc(annee.id);

    await Fb.db.runTransaction((tx) async {
      final snap = await tx.get(compteur);
      final n = ((snap.data()?['n'] as num?)?.toInt() ?? 0) + 1;
      final reference =
          'UCB-${annee.debut.year}-${n.toString().padLeft(4, '0')}';
      tx.set(compteur, {'n': n});
      tx.set(_dossier(c.id), {
        'annee_id': annee.id,
        'reference': reference,
        'session_id': c.id,
        'cours_id': c.coursId,
        'code': c.code,
        'intitule': c.intitule,
        'promotion_nom': c.promotion,
        'credits': c.credits,
        'volume': c.volume,
        'faculte_id': c.faculteId,
        'faculte_nom': c.faculte,
        'enseignant_id': c.enseignantId,
        'enseignant_nom': c.enseignant,
        'grade': c.grade,
        'taux': c.taux,
        'retenue_pct': pct,
        'chef_nom': c.chefNom,
        'heures': heures,
        'brut': brut,
        'retenues': retenues,
        'net': net,
        'seances': [
          for (final s in c.seances)
            {
              'date': Timestamp.fromDate(
                DateTime(s.date.year, s.date.month, s.date.day),
              ),
              'debut': minutesOf(s.debut),
              'fin': minutesOf(s.fin),
              'chapitre': s.chapitre,
              'type': s.type.label,
              'preuve': s.preuve,
              'preuve_id': s.preuveId,
            },
        ],
        'pieces': [
          for (final s in c.seances)
            if (s.preuve != null) s.preuve,
        ],
        'pieces_ids': [
          for (final s in c.seances)
            if (s.preuve != null) s.preuveId ?? '',
        ],
        'mode': mode,
        'coordonnees': coordonnees,
        'palier_courant': 1,
        'palier_rejet': null,
        'motif_rejet': null,
        'dates': <String, dynamic>{},
        'acteurs': <String, dynamic>{},
        'historique': <String>[],
        'date_init': Fb.ts(date),
        'cree_le': FieldValue.serverTimestamp(),
      });
      tx.set(Fb.db.collection(Col.validations).doc(), {
        'dossier_id': c.id,
        'annee_id': annee.id,
        'reference': reference,
        'palier': 1,
        'role': 'SECRETAIRE',
        'action': 'INITIALISE',
        'autorite_id': me.id,
        'autorite_nom': me.nomComplet,
        'motif': null,
        'horodatage': FieldValue.serverTimestamp(),
      });
    });
  });

  Future<bool> soumettre(DossierWf d) async {
    final ok = await _agir(
      d,
      {'palier_courant': 2, ..._acteur(1)},
      'SOUMIS',
      palier: 1,
    );
    if (ok) {
      Notifier.auRole(
        'DOYEN',
        faculteId: d.faculteId,
        type: 'DOSSIER',
        titre: 'Dossier à valider',
        message:
            '${d.reference} · ${d.enseignant} (${d.code}) attend votre signature.',
        cible: d.id,
      );
    }
    return ok;
  }

  /// Après un rejet : le dossier retourne au palier qui l'avait rejeté.
  Future<bool> reinitialiser(
    DossierWf d, {
    required String mode,
    required String coordonnees,
    required List<String> pieces,
    List<String>? piecesIds,
    String? commentaire,
  }) {
    final p = d.palierRejet!;
    final faculteId = d.faculteId;
    final ref = d.reference;
    final idDossier = d.id;
    final texte =
        'Rejeté par le ${kActeursCourts[p - 1]} le ${fmtDate(d.dates[p] ?? DateTime.now())} : ${d.motifRejet ?? ''}'
        '${(commentaire == null || commentaire.isEmpty) ? '' : '\nCorrection : $commentaire'}';
    return _agir(
      d,
      {
        'mode': mode,
        'coordonnees': coordonnees,
        'pieces': pieces,
        if (piecesIds != null) 'pieces_ids': piecesIds,
        'palier_rejet': null,
        'motif_rejet': null,
        'dates.$p': FieldValue.delete(),
        'historique': FieldValue.arrayUnion([texte]),
      },
      'CORRIGE',
      motif: commentaire,
      palier: 1,
    ).then((ok) {
      if (ok) {
        _versPalier(
          p,
          faculteId,
          type: 'DOSSIER',
          titre: 'Dossier corrigé',
          message: '$ref a été corrigé par la secrétaire et vous revient.',
          cible: idDossier,
        );
      }
      return ok;
    });
  }

  /// Notifie les titulaires du palier [p] (doyen limité à sa faculté).
  void _versPalier(
    int p,
    String faculteId, {
    required String type,
    required String titre,
    required String message,
    String? cible,
  }) {
    Notifier.auRole(
      _roles[p - 1],
      faculteId: p == 2 ? faculteId : null,
      type: type,
      titre: titre,
      message: message,
      cible: cible,
    );
  }

  // ───────────── Autorités ─────────────
  Future<bool> valider(DossierWf d) async {
    final p = d.palierCourant;
    final ok = await _agir(d, {
      'palier_courant': p + 1,
      ..._acteur(p),
    }, 'VALIDE');
    if (ok) {
      _versPalier(
        p + 1,
        d.faculteId,
        type: 'DOSSIER',
        titre: 'Dossier à valider',
        message:
            '${d.reference} · ${d.enseignant} (${d.code}) attend votre signature.',
        cible: d.id,
      );
      Notifier.envoyer(
        [d.enseignantId],
        type: 'DOSSIER',
        titre: 'Votre dossier avance',
        message: '${d.reference} a été validé par le ${kActeursCourts[p - 1]}.',
        cible: d.id,
      );
    }
    return ok;
  }

  Future<bool> rejeter(DossierWf d, String motif) async {
    final p = d.palierCourant;
    final ok = await _agir(
      d,
      {'palier_rejet': p, 'motif_rejet': motif, ..._acteur(p)},
      'REJETE',
      motif: motif,
    );
    if (ok) {
      final msg =
          '${d.reference} rejeté par le ${kActeursCourts[p - 1]} : $motif';
      Notifier.auRole(
        'SECRETAIRE',
        faculteId: d.faculteId,
        type: 'REJET',
        titre: 'Dossier rejeté',
        message: msg,
        cible: d.id,
      );
      Notifier.envoyer(
        [d.enseignantId],
        type: 'REJET',
        titre: 'Dossier en correction',
        message: '${d.reference} est retourné à la secrétaire pour correction.',
        cible: d.id,
      );
    }
    return ok;
  }

  // ───────────── Comptabilité ─────────────
  Future<bool> payer(
    DossierWf d, {
    required String reference,
    required DateTime date,
    required String modeReglement,
    required String bordereau,
    String? imputation,
    String? bordereauId,
  }) async {
    final ok = await _agir(
      d,
      {
        'bordereau_id': bordereauId,
        'palier_courant': 7,
        'reference_paiement': reference,
        'mode_reglement': modeReglement,
        'bordereau': bordereau,
        'imputation': imputation,
        'dates.6': Fb.ts(date),
        'acteurs.6': Session.instance.me!.nomComplet,
      },
      'PAYE',
      palier: 6,
    );
    if (ok) {
      Notifier.envoyer(
        [d.enseignantId],
        type: 'PAIEMENT',
        titre: 'Paiement effectué',
        message:
            '${d.reference} : ${d.net.toStringAsFixed(2)} \$ vous ont été réglés.',
        cible: d.id,
      );
      Notifier.auRole(
        'SECRETAIRE',
        faculteId: d.faculteId,
        type: 'PAIEMENT',
        titre: 'Dossier payé',
        message: '${d.reference} est clôturé (payé).',
        cible: d.id,
      );
    }
    return ok;
  }
}
