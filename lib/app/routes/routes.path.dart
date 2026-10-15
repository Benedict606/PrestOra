import 'package:prestora/app/view/admin/admin.dart';
import 'package:prestora/app/view/home/home.dart';
import 'package:prestora/app/view/login/login.dart';
import 'package:prestora/app/view/payslip/accountant/comptabilite.dart';
import 'package:prestora/app/view/payslip/authority/autorite.dart';
import 'package:prestora/app/view/payslip/secretary/secretaire.dart';
import 'package:prestora/app/view/prestation/student/student.dart';
import 'package:prestora/app/view/prestation/supervisor/Encadreur.dart';
import 'package:prestora/app/view/setting/setting.dart';
import 'package:prestora/app/view/teacher/enseignant.dart';
import 'package:prestora/mainview.dart';

class RoutePath {
  static dynamic mainview = Mainview.route;
  static dynamic home = Home.route;
  static dynamic admin = Admin.route;
  static dynamic setting = Setting.route;
  static dynamic etudiant = Etudiant.route;
  static dynamic encadreur = Encadreur.route;
  static dynamic enseignant = Enseignant.route;
  static dynamic login = Login.route;
  static dynamic doyen = Autorite.routeDoyen;
  static dynamic vra = Autorite.routeVra;
  static dynamic recteur = Autorite.routeRecteur;
  static dynamic ag = Autorite.routeAg;
  static dynamic secretaire = Secretaire.route;
  static dynamic comptabilite = Comptabilite.route;
}
