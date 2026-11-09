import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';

/// Authentification Firebase (email + mot de passe).
class AuthService {
  AuthService._();

  static FirebaseAuth get _auth => FirebaseAuth.instance;

  static Future<void> signIn(String email, String password) async {
    try {
      await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      throw Exception(message(e));
    }
  }

  static Future<void> signOut() => _auth.signOut();

  static Future<void> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
    } on FirebaseAuthException catch (e) {
      throw Exception(message(e));
    }
  }

  /// Crée un compte Firebase Auth SANS déconnecter l'administrateur :
  /// on passe par une seconde instance de l'application Firebase.
  /// (Évite d'avoir besoin d'une Cloud Function, donc du forfait Blaze.)
  /// Si l'email existe déjà et que [password] correspond, retourne l'uid existant.
  static Future<String> createAccount(String email, String password) async {
    final app = await _secondaryApp();
    final auth = FirebaseAuth.instanceFor(app: app);
    try {
      final cred = await auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      return cred.user!.uid;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'email-already-in-use') {
        try {
          final cred = await auth.signInWithEmailAndPassword(
            email: email.trim(),
            password: password,
          );
          return cred.user!.uid;
        } on FirebaseAuthException {
          throw Exception('Cet email possède déjà un compte.');
        }
      }
      throw Exception(message(e));
    } finally {
      await auth.signOut();
    }
  }

  static Future<FirebaseApp> _secondaryApp() async {
    try {
      return Firebase.app('creation_comptes');
    } catch (_) {
      return Firebase.initializeApp(
        name: 'creation_comptes',
        options: Firebase.app().options,
      );
    }
  }

  static String message(FirebaseAuthException e) {
    switch (e.code) {
      case 'invalid-credential':
      case 'wrong-password':
      case 'user-not-found':
      case 'invalid-email':
        return 'Email ou mot de passe incorrect.';
      case 'user-disabled':
        return 'Ce compte a été désactivé.';
      case 'too-many-requests':
        return 'Trop de tentatives. Réessayez dans quelques minutes.';
      case 'network-request-failed':
        return 'Réseau indisponible. Vérifiez votre connexion.';
      case 'weak-password':
        return 'Mot de passe trop faible (6 caractères minimum).';
      case 'email-already-in-use':
        return 'Cet email possède déjà un compte.';
      case 'operation-not-allowed':
        return "La connexion par email n'est pas activée dans Firebase.";
      default:
        return 'Erreur d\'authentification (${e.code}).';
    }
  }
}
