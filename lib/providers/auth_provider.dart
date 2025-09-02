import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:hospital_management_system/models/user_model.dart' as app_user;
import 'package:hospital_management_system/services/auth_service.dart';

/// Authentication provider managing user authentication state
/// Basic state management
class AuthProvider with ChangeNotifier {
  final AuthService _authService = AuthService();

  // Authentication state variables
  User? _currentFirebaseUser;
  Map<String, dynamic>? _currentUserData;
  bool _isLoading = false;
  String? _errorMessage;

  // Getters for accessing authentication state
  User? get currentFirebaseUser => _currentFirebaseUser;
  Map<String, dynamic>? get currentUserData => _currentUserData;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  
  /// Check if user is authenticated
  bool get isAuthenticated => _currentFirebaseUser != null;
  
  /// Get current user's role
  app_user.UserRole? get currentUserRole {
    if (_currentUserData != null) {
      return app_user.UserRoleExtension.fromString(_currentUserData!['role'] ?? 'patient');
    }
    return null;
  }
  
  /// Get current user ID
  String? get currentUserId => _currentFirebaseUser?.uid;

  /// Initialize authentication provider
  Future<void> initialize() async {
    _setLoading(true);
    
    // Listen to authentication state changes
    _authService.authStateChanges.listen((User? user) async {
      _currentFirebaseUser = user;
      
      if (user != null) {
        // Load user data from Firestore
        await _loadCurrentUserData();
      } else {
        _currentUserData = null;
      }
      
      notifyListeners();
    });
    
    _setLoading(false);
  }

  /// Load current user data from Firestore
  Future<void> _loadCurrentUserData() async {
    try {
      if (_currentFirebaseUser != null) {
        final userData = await _authService.getCurrentUserData();
        _currentUserData = userData;
        _clearError();
      }
    } catch (e) {
      _setError('Failed to load user data: ${e.toString()}');
    }
  }

  /// Sign in with email and password
  Future<bool> signIn({
    required String email,
    required String password,
  }) async {
    _setLoading(true);
    _clearError();

    try {
      final userData = await _authService.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (userData != null) {
        _currentUserData = userData;
        _setLoading(false);
        return true;
      }
    } catch (e) {
      _setError(e.toString());
    }

    _setLoading(false);
    return false;
  }

  /// Register new user 
  Future<bool> registerUser({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    app_user.UserRole role = app_user.UserRole.patient,
  }) async {
    _setLoading(true);
    _clearError();

    try {
      final user = await _authService.registerUser(
        email: email,
        password: password,
        firstName: firstName,
        lastName: lastName,
        role: role,
      );

      if (user != null) {
        _setLoading(false);
        return true;
      }
    } catch (e) {
      _setError(e.toString());
    }

    _setLoading(false);
    return false;
  }

  /// Send password reset email
  Future<bool> sendPasswordResetEmail(String email) async {
    _setLoading(true);
    _clearError();

    try {
      await _authService.sendPasswordResetEmail(email);
      _setLoading(false);
      return true;
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
      return false;
    }
  }

  /// Sign out current user
  Future<void> signOut() async {
    _setLoading(true);
    
    try {
      await _authService.signOut();
      _currentUserData = null;
      _clearError();
    } catch (e) {
      _setError(e.toString());
    }
    
    _setLoading(false);
  }

  /// Set loading state
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  /// Set error message
  void _setError(String error) {
    _errorMessage = error;
    notifyListeners();
  }

  /// Clear error message
  void _clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  /// Clear error manually
  void clearError() {
    _clearError();
  }
}