import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:prestora/app/view/admin/admin_data.dart';
import 'package:prestora/app/view/payslip/authority/paie_data.dart' hide fmtDate;
import 'package:prestora/app/view/prestation/student/etudiant_data.dart';
import 'package:prestora/app/view/prestation/supervisor/encadreur_data.dart';
import 'package:prestora/app/view/teacher/enseignant_data.dart';
import 'package:prestora/data/firebase/fb.dart';
import 'package:prestora/data/models/annee.dart';
import 'package:prestora/data/repositories/notification_repository.dart';
import 'package:prestora/data/repositories/annee_repository.dart';

/// Session de l'utilisateur connecté : profil + années académiques.
/// Singleton écouté par le routeur (redirections) et par les pages.
class Session extends ChangeNotifier {
  Session._();
  static final Session instance = Session._();

  Compte? me;
  String? faculteNom; // nom de la faculté de l'utilisateur
  String? promotionNom; // nom de sa promotion (chef de promotion)
  String? _libKey;
  String? erreur; // ex. « compte désactivé » affiché sur la page de connexion
  bool ready = false;
  double? retenue; // retenue fiscale en % (parametres/retenue_fiscale)

  List<AnneeAcademique> annees = const [];
  String? _choisie; // année consultée (id) ; par défaut l'année active

  StreamSubscription<dynamic>? _authSub;
  StreamSubscription<dynamic>? _meSub;
  StreamSubscription<dynamic>? _anneesSub;
  StreamSubscription<dynamic>? _retenueSub;
  String? _uid;

  // ───────────── Années ─────────────
  AnneeAcademique? get active =>
      annees.where((a) => a.estActive).firstOrNull;

  /// Année actuellement consultée : choix de l'utilisateur, sinon l'année
  /// active, sinon la plus récente.
  AnneeAcademique? get consultee {
    final c = annees.where((a) => a.id == _choisie).firstOrNull;
    return c ?? active ?? annees.firstOrNull;
  }

  /// Lecture seule : une année clôturée, ou aucune année active en cours.
  bool get lectureSeule => consultee == null || !consultee!.estActive;

  void consulter(String anneeId) {
    _choisie = anneeId;
    notifyListeners();
  }

  bool get gereAnnees =>
      me != null &&
      (me!.type == TypeCompte.administrateur || me!.gereAnnees);

  // ───────────── Cycle de vie ─────────────
  /// À appeler une fois dans main() : attend l'état d'authentification initial.
  Future<void> init() async {
    final first = await Fb.auth.authStateChanges().first;
    await _bind(first?.uid);
    _authSub = Fb.auth.authStateChanges().listen((u) => _bind(u?.uid));
  }

  Future<void> _bind(String? uid) async {
    if (uid == _uid && ready) return;
    _uid = uid;
    await _meSub?.cancel();
    _meSub = null;
    await _anneesSub?.cancel();
    _anneesSub = null;
    await _retenueSub?.cancel();
    _retenueSub = null;

    if (uid == null) {
      retenue = null;
      me = null;
      annees = const [];
      faculteNom = null;
      promotionNom = null;
      _libKey = null;
      _arreterDepots();
      adminStore.stop();
      ready = true;
      notifyListeners();
      return;
    }

    final first = Completer<void>();
    _meSub = Fb.db
        .collection(Col.utilisateurs)
        .doc(uid)
        .snapshots()
        .listen(
          (d) async {
            if (!d.exists) {
              erreur = "Profil introuvable. Contactez l'administrateur.";
              await Fb.auth.signOut();
            } else if (d.data()?['est_actif'] != true) {
              erreur = 'Ce compte est désactivé.';
              await Fb.auth.signOut();
            } else {
              erreur = null;
              me = Compte.fromMap(d.id, d.data()!);
              _demarrerDonnees();
              ready = true;
              notifyListeners();
            }
            if (!first.isCompleted) first.complete();
          },
          onError: (Object e) {
            erreur = e.toString().contains('permission-denied')
                ? "Profil introuvable ou compte désactivé. Contactez l'administrateur."
                : 'Lecture du profil impossible. Vérifiez votre connexion.';
            Fb.auth.signOut();
            ready = true;
            notifyListeners();
            if (!first.isCompleted) first.complete();
          },
        );
    await first.future;
  }

  void _demarrerDonnees() {
    _anneesSub ??= AnneeRepository.instance.watchAnnees().listen((l) {
      annees = l;
      notifyListeners();
    }, onError: (Object e) => debugPrint('annees: $e'));
    _retenueSub ??= Fb.db
        .collection(Col.parametres)
        .doc('retenue_fiscale')
        .snapshots()
        .listen((d) {
          retenue = (d.data()?['pourcentage'] as num?)?.toDouble();
          notifyListeners();
        }, onError: (Object e) => debugPrint('retenue: $e'));
    final c = me;
    if (c == null) return;
    _chargerLibelles(c);
    notificationStore.start(c.id);
    switch (c.type) {
      case TypeCompte.administrateur:
        adminStore.start();
      case TypeCompte.chefPromotion:
        etudiantStore.start();
      case TypeCompte.encadreur:
        encadreurStore.start();
      case TypeCompte.enseignant:
        enseignantStore.start();
      case TypeCompte.secretaire:
      case TypeCompte.doyen:
      case TypeCompte.vra:
      case TypeCompte.recteur:
      case TypeCompte.ag:
      case TypeCompte.comptabilite:
        paieStore.start();
    }
  }

  void _arreterDepots() {
    etudiantStore.stop();
    encadreurStore.stop();
    enseignantStore.stop();
    paieStore.stop();
    notificationStore.stop();
  }

  /// Charge les noms de faculté / promotion (affichés dans les en-têtes).
  Future<void> _chargerLibelles(Compte c) async {
    final cle = '${c.faculteId}|${c.promotionId}';
    if (cle == _libKey) return;
    _libKey = cle;
    try {
      if (c.faculteId != null) {
        final d = await Fb.db.collection(Col.facultes).doc(c.faculteId).get();
        faculteNom = d.data()?['nom_faculte'] as String?;
      } else {
        faculteNom = null;
      }
      if (c.promotionId != null) {
        final d = await Fb.db
            .collection(Col.promotions)
            .doc(c.promotionId)
            .get();
        promotionNom = d.data()?['nom'] as String?;
      } else {
        promotionNom = null;
      }
      notifyListeners();
    } catch (e) {
      debugPrint('libellés: $e');
    }
  }

  Future<void> dispose2() async {
    await _authSub?.cancel();
    await _meSub?.cancel();
    await _anneesSub?.cancel();
    await _retenueSub?.cancel();
  }
}
