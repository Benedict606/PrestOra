import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Noms des collections Firestore (voir firebase/firestore_schema.md).
class Col {
  static const utilisateurs = 'utilisateurs';
  static const paiement = 'paiement'; // sous-collection de utilisateurs
  static const facultes = 'facultes';
  static const departements = 'departements';
  static const promotions = 'promotions';
  static const cours = 'cours';
  static const baremes = 'baremes';
  static const parametres = 'parametres';
  static const annees = 'annees_academiques';
  static const offres = 'offres_cours';
  static const affectations = 'affectations_promotion';
  static const sessions = 'sessions_suivi';
  static const seances = 'seances'; // sous-collection de sessions_suivi
  static const dossiers = 'dossiers_paie';
  static const validations = 'validations';
  static const notifications = 'notifications';
  static const pieces = 'pieces';
}

/// Accès raccourcis aux instances Firebase.
class Fb {
  static FirebaseFirestore get db => FirebaseFirestore.instance;
  static FirebaseAuth get auth => FirebaseAuth.instance;

  static CollectionReference<Map<String, dynamic>> col(String name) =>
      db.collection(name);

  static DateTime? date(dynamic v) => v is Timestamp ? v.toDate() : null;
  static Timestamp ts(DateTime d) => Timestamp.fromDate(d);
}
