import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<User?> signInWithEmail(String email, String password) async {
    try {
      final result = await _auth.signInWithEmailAndPassword(email: email, password: password);
      return result.user;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthError(e);
    }
  }

  Future<User?> signUp({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    required String phone,
  }) async {
    try {
      final result = await _auth.createUserWithEmailAndPassword(email: email, password: password);
      if (result.user != null) {
        await _firestore.collection('users').doc(result.user!.uid).set({
          'firstName': firstName,
          'lastName': lastName,
          'email': email,
          'phone': phone,
          'isAdmin': false,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }
      return result.user;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthError(e);
    }
  }

  Future<void> signOut() async => await _auth.signOut();

  Future<void> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      throw _handleAuthError(e);
    }
  }

  User? getCurrentUser() => _auth.currentUser;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  String _handleAuthError(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found': return 'No user found with this email.';
      case 'wrong-password': return 'Wrong password.';
      case 'email-already-in-use': return 'Email already in use.';
      case 'weak-password': return 'Password is too weak.';
      case 'invalid-email': return 'Invalid email address.';
      default: return 'An error occurred. Please try again.';
    }
  }
}