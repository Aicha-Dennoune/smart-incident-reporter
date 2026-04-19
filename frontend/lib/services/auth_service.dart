import 'package:firebase_auth/firebase_auth.dart';

/// Connexion Firebase Auth (email / mot de passe).
class AuthService {
  AuthService([FirebaseAuth? auth]) : _auth = auth ?? FirebaseAuth.instance;

  final FirebaseAuth _auth;

  Future<UserCredential> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) {
    return _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
  }

  /// Messages utilisateur en français (sans exposer les codes techniques).
  static String messageForFirebaseAuth(FirebaseAuthException e) {
    switch (e.code) {
      case 'invalid-email':
        return 'Adresse e-mail invalide.';
      case 'user-disabled':
        return 'Ce compte a été désactivé. Contactez l’administrateur.';
      case 'user-not-found':
        return 'Aucun compte ne correspond à cet e-mail.';
      case 'wrong-password':
        return 'Mot de passe incorrect.';
      case 'invalid-credential':
      case 'invalid-login-credentials':
        return 'E-mail ou mot de passe incorrect.';
      case 'too-many-requests':
        return 'Trop de tentatives. Réessayez plus tard.';
      case 'network-request-failed':
        return 'Problème réseau. Vérifiez votre connexion.';
      case 'operation-not-allowed':
        return 'La connexion par e-mail n’est pas activée sur ce projet.';
      default:
        return 'Connexion impossible. Vérifiez vos identifiants.';
    }
  }
}
