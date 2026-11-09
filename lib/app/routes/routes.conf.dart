import 'package:go_router/go_router.dart';
import 'package:prestora/app/routes/routes.path.dart';
import 'package:prestora/app/view/admin/admin.dart';
import 'package:prestora/app/view/home/home.dart';
import 'package:prestora/app/view/login/login.dart';
import 'package:prestora/app/view/payslip/accountant/comptabilite.dart';
import 'package:prestora/app/view/payslip/authority/autorite.dart';
import 'package:prestora/app/view/payslip/authority/paie_data.dart';
import 'package:prestora/app/view/payslip/secretary/secretaire.dart';
import 'package:prestora/app/view/prestation/student/student.dart';
import 'package:prestora/app/view/prestation/supervisor/encadreur.dart';
import 'package:prestora/app/view/setting/setting.dart';
import 'package:prestora/app/view/teacher/enseignant.dart';
import 'package:prestora/app/view/admin/admin_data.dart';
import 'package:prestora/data/services/session.dart';
import 'package:prestora/mainview.dart';

/// Page d'accueil de chaque rôle.
String routeFor(TypeCompte t) => switch (t) {
  TypeCompte.administrateur => RoutePath.admin,
  TypeCompte.chefPromotion => RoutePath.etudiant,
  TypeCompte.encadreur => RoutePath.encadreur,
  TypeCompte.enseignant => RoutePath.enseignant,
  TypeCompte.secretaire => RoutePath.secretaire,
  TypeCompte.doyen => RoutePath.doyen,
  TypeCompte.vra => RoutePath.vra,
  TypeCompte.recteur => RoutePath.recteur,
  TypeCompte.ag => RoutePath.ag,
  TypeCompte.comptabilite => RoutePath.comptabilite,
};

final Set<String> _pagesDeRole = {
  for (final t in TypeCompte.values) routeFor(t),
};

GoRouter router = GoRouter(
  initialLocation: RoutePath.login,
  refreshListenable: Session.instance,
  redirect: (context, state) {
    final s = Session.instance;
    final loc = state.matchedLocation;
    final me = s.me;
    if (me == null) return loc == RoutePath.login ? null : RoutePath.login;
    final home = routeFor(me.type);
    if (loc == RoutePath.login || loc == '/') return home;
    // Chaque rôle n'accède qu'à sa propre page
    if (_pagesDeRole.contains(loc) && loc != home) return home;
    return null;
  },
  routes: [
    GoRoute(
      name: "mainview",
      path: RoutePath.mainview,
      builder: (context, state) => Mainview(),
    ),
    GoRoute(
      name: "home",
      path: RoutePath.home,
      builder: (context, state) => Home(),
    ),
    GoRoute(
      name: "setting",
      path: RoutePath.setting,
      builder: (context, state) => Setting(),
    ),
    GoRoute(
      name: "admin",
      path: RoutePath.admin,
      builder: (context, state) => Admin(),
    ),
    GoRoute(
      name: "etudiant",
      path: RoutePath.etudiant,
      builder: (context, state) => Etudiant(),
    ),

    GoRoute(
      name: "encadreur",
      path: RoutePath.encadreur,
      builder: (context, state) => Encadreur(),
    ),

    GoRoute(
      name: "ensignant",
      path: RoutePath.enseignant,
      builder: (context, state) => Enseignant(),
    ),

    GoRoute(
      name: "login",
      path: RoutePath.login,
      builder: (context, state) => Login(),
    ),

    GoRoute(
      name: "doyen",
      path: RoutePath.doyen,
      builder: (context, state) => Autorite(role: RoleAutorite.doyen),
    ),

    GoRoute(
      name: "vra",
      path: RoutePath.vra,
      builder: (context, state) => Autorite(role: RoleAutorite.vra),
    ),
    GoRoute(
      name: "recteur",
      path: RoutePath.recteur,
      builder: (context, state) => Autorite(role: RoleAutorite.recteur),
    ),
    GoRoute(
      name: "ag",
      path: RoutePath.ag,
      builder: (context, state) => Autorite(role: RoleAutorite.ag),
    ),
    GoRoute(
      name: "secretaire",
      path: RoutePath.secretaire,
      builder: (context, state) => Secretaire(),
    ),

    GoRoute(
      name: "comptabilite",
      path: RoutePath.comptabilite,
      builder: (context, state) => Comptabilite(),
    ),
  ],
);
