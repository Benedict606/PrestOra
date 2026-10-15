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
import 'package:prestora/app/view/prestation/supervisor/Encadreur.dart';
import 'package:prestora/app/view/setting/setting.dart';
import 'package:prestora/app/view/teacher/enseignant.dart';
import 'package:prestora/mainview.dart';

GoRouter router = GoRouter(
  initialLocation: RoutePath.login,
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
