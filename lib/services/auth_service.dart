import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/user.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get current user stream
  Stream<AppUser?> get user {
    return _auth.authStateChanges().map((firebaseUser) {
      return firebaseUser != null ? AppUser.fromFirebaseUser(firebaseUser) : null;
    });
  }

  // Get current user
  AppUser? get currentUser {
    final firebaseUser = _auth.currentUser;
    return firebaseUser != null ? AppUser.fromFirebaseUser(firebaseUser) : null;
  }

  // Sign in anonymously for testing
  Future<AppUser?> signInAnonymously() async {
    try {
      final UserCredential result = await _auth.signInAnonymously();
      final User? firebaseUser = result.user;
      
      if (firebaseUser != null) {
        final appUser = AppUser.fromFirebaseUser(firebaseUser);
        await _createUserDocument(appUser);
        return appUser;
      }
      return null;
    } catch (e) {
      debugPrint('Error signing in anonymously: $e');
      return null;
    }
  }

  // Sign in with email and password
  Future<AppUser?> signInWithEmail(String email, String password) async {
    try {
      // Set language to avoid locale issues
      await _auth.setLanguageCode('en');
      
      final UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      final User? firebaseUser = result.user;
      
      if (firebaseUser != null) {
        final appUser = AppUser.fromFirebaseUser(firebaseUser);
        await _updateUserDocument(appUser);
        return appUser;
      }
      return null;
    } on FirebaseAuthException catch (e) {
      debugPrint('Firebase Auth sign-in error: ${e.code} - ${e.message}');
      rethrow;
    } catch (e) {
      debugPrint('Error signing in with email: $e');
      rethrow;
    }
  }

  // Register with email and password
  Future<AppUser?> registerWithEmail(String email, String password, String displayName) async {
    try {
      // Set language to avoid locale issues
      await _auth.setLanguageCode('en');
      
      final UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      final User? firebaseUser = result.user;
      
      if (firebaseUser != null) {
        // Update display name
        await firebaseUser.updateDisplayName(displayName);
        await firebaseUser.reload();
        
        final updatedUser = _auth.currentUser;
        if (updatedUser != null) {
          final appUser = AppUser.fromFirebaseUser(updatedUser);
          await _createUserDocument(appUser);
          return appUser;
        }
      }
      return null;
    } on FirebaseAuthException catch (e) {
      debugPrint('Firebase Auth error: ${e.code} - ${e.message}');
      
      // Handle specific Firebase Auth errors
      switch (e.code) {
        case 'configuration-not-found':
        case 'unknown':
          // Fallback: try with different settings
          return await _registerWithFallback(email, password, displayName);
        default:
          rethrow;
      }
    } catch (e) {
      debugPrint('Error registering with email: $e');
      rethrow;
    }
  }
  
  // Fallback registration method
  Future<AppUser?> _registerWithFallback(String email, String password, String displayName) async {
    try {
      // Clear any cached auth state
      await _auth.signOut();
      
      // Try registration without reCAPTCHA verification
      final UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      final User? firebaseUser = result.user;
      if (firebaseUser != null) {
        await firebaseUser.updateDisplayName(displayName);
        await firebaseUser.reload();
        
        final updatedUser = _auth.currentUser;
        if (updatedUser != null) {
          final appUser = AppUser.fromFirebaseUser(updatedUser);
          await _createUserDocument(appUser);
          return appUser;
        }
      }
      return null;
    } catch (e) {
      debugPrint('Fallback registration error: $e');
      return null;
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } catch (e) {
      debugPrint('Error signing out: $e');
      rethrow;
    }
  }

  // Send password reset email
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } catch (e) {
      debugPrint('Error sending password reset email: $e');
      rethrow;
    }
  }

  // Update user profile
  Future<void> updateUserProfile(String displayName, String? photoUrl) async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        await user.updateDisplayName(displayName);
        if (photoUrl != null) {
          await user.updatePhotoURL(photoUrl);
        }
        await user.reload();
        
        final updatedUser = _auth.currentUser;
        if (updatedUser != null) {
          final appUser = AppUser.fromFirebaseUser(updatedUser);
          await _updateUserDocument(appUser);
        }
      }
    } catch (e) {
      debugPrint('Error updating user profile: $e');
      rethrow;
    }
  }

  // Create user document in Firestore
  Future<void> _createUserDocument(AppUser user) async {
    try {
      await _firestore.collection('users').doc(user.id).set(user.toMap());
    } catch (e) {
      debugPrint('Error creating user document: $e');
    }
  }

  // Update user document in Firestore
  Future<void> _updateUserDocument(AppUser user) async {
    try {
      await _firestore.collection('users').doc(user.id).update({
        'lastLoginAt': user.lastLoginAt.toIso8601String(),
        'displayName': user.displayName,
        'photoUrl': user.photoUrl,
        'isEmailVerified': user.isEmailVerified,
      });
    } catch (e) {
      debugPrint('Error updating user document: $e');
    }
  }

  // Delete user account
  Future<void> deleteAccount() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        // Delete user data from Firestore
        await _firestore.collection('users').doc(user.uid).delete();
        
        // Delete all user's tasks
        final tasksQuery = await _firestore
            .collection('tasks')
            .where('userId', isEqualTo: user.uid)
            .get();
        
        for (final doc in tasksQuery.docs) {
          await doc.reference.delete();
        }
        
        // Delete Firebase Auth account
        await user.delete();
      }
    } catch (e) {
      debugPrint('Error deleting account: $e');
      rethrow;
    }
  }
}