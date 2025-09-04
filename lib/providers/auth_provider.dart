import 'package:flutter/foundation.dart';
import '../models/user.dart';
import '../services/auth_service.dart';

class AuthProvider with ChangeNotifier {
  final AuthService _authService = AuthService();
  
  AppUser? _user;
  bool _isLoading = false;
  String? _error;

  // Getters
  AppUser? get user => _user;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _user != null;

  // Initialize auth provider
  void initialize() {
    _authService.user.listen((user) {
      _user = user;
      notifyListeners();
    });
  }

  // Set loading state
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  // Set error
  void _setError(String? error) {
    _error = error;
    notifyListeners();
  }

  // Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }

  // Sign in anonymously
  Future<bool> signInAnonymously() async {
    _setLoading(true);
    _setError(null);
    
    try {
      final user = await _authService.signInAnonymously();
      _setLoading(false);
      return user != null;
    } catch (e) {
      _setError('Failed to sign in anonymously: ${e.toString()}');
      _setLoading(false);
      return false;
    }
  }

  // Sign in with email and password
  Future<bool> signInWithEmail(String email, String password) async {
    _setLoading(true);
    _setError(null);
    
    try {
      final user = await _authService.signInWithEmail(email, password);
      _setLoading(false);
      return user != null;
    } catch (e) {
      _setError('Failed to sign in: ${e.toString()}');
      _setLoading(false);
      return false;
    }
  }

  // Register with email and password
  Future<bool> registerWithEmail(String email, String password, String displayName) async {
    _setLoading(true);
    _setError(null);
    
    try {
      final user = await _authService.registerWithEmail(email, password, displayName);
      _setLoading(false);
      return user != null;
    } catch (e) {
      _setError('Failed to register: ${e.toString()}');
      _setLoading(false);
      return false;
    }
  }

  // Sign out
  Future<void> signOut() async {
    _setLoading(true);
    _setError(null);
    
    try {
      await _authService.signOut();
      _user = null;
      _setLoading(false);
    } catch (e) {
      _setError('Failed to sign out: ${e.toString()}');
      _setLoading(false);
    }
  }

  // Send password reset email
  Future<bool> sendPasswordResetEmail(String email) async {
    _setLoading(true);
    _setError(null);
    
    try {
      await _authService.sendPasswordResetEmail(email);
      _setLoading(false);
      return true;
    } catch (e) {
      _setError('Failed to send password reset email: ${e.toString()}');
      _setLoading(false);
      return false;
    }
  }

  // Update user profile
  Future<bool> updateUserProfile(String displayName, String? photoUrl) async {
    _setLoading(true);
    _setError(null);
    
    try {
      await _authService.updateUserProfile(displayName, photoUrl);
      _setLoading(false);
      return true;
    } catch (e) {
      _setError('Failed to update profile: ${e.toString()}');
      _setLoading(false);
      return false;
    }
  }

  // Delete account
  Future<bool> deleteAccount() async {
    _setLoading(true);
    _setError(null);
    
    try {
      await _authService.deleteAccount();
      _user = null;
      _setLoading(false);
      return true;
    } catch (e) {
      _setError('Failed to delete account: ${e.toString()}');
      _setLoading(false);
      return false;
    }
  }
}