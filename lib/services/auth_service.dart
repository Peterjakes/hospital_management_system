import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hospital_management_system/models/user_model.dart' as app_user;
import 'package:hospital_management_system/models/patient_model.dart';

/// Authentication service handling Firebase Auth operations
class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Get current authenticated user
  User? get currentUser => _auth.currentUser;

  /// Stream of authentication state changes
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Sign in user with email and password
  /// Basic login functionality
  Future<Map<String, dynamic>?> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      // Authenticate with Firebase Auth
      final UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (userCredential.user != null) {
        // Get user data from Firestore
        final DocumentSnapshot userDoc = await _firestore
            .collection('users')
            .doc(userCredential.user!.uid)
            .get();

        if (userDoc.exists) {
          final userData = userDoc.data() as Map<String, dynamic>;
          userData['id'] = userDoc.id;
          return userData;
        }
      }
    } on FirebaseAuthException catch (e) {
      throw Exception(_handleAuthException(e));
    } catch (e) {
      throw Exception('Failed to sign in: ${e.toString()}');
    }
    return null;
  }

  /// Register a new user (basic registration for doctors/admins)
  Future<app_user.User?> registerUser({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    app_user.UserRole role = app_user.UserRole.patient, // Default to patient
  }) async {
    try {
      // Create user in Firebase Auth
      final UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (userCredential.user != null) {
        // Create user object
        final user = app_user.User(
          id: userCredential.user!.uid,
          email: email,
          firstName: firstName,
          lastName: lastName,
          role: role,
          createdAt: DateTime.now(),
        );

        // Store user data in Firestore
        await _firestore
            .collection('users')
            .doc(userCredential.user!.uid)
            .set(user.toMap());

        return user;
      }
    } on FirebaseAuthException catch (e) {
      throw Exception(_handleAuthException(e));
    } catch (e) {
      throw Exception('Failed to register user: ${e.toString()}');
    }
    return null;
  }

  /// Register new patient with complete medical information
  Future<Patient?> registerPatient({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    required DateTime dateOfBirth,
    required String gender,
    required String phoneNumber,
    required String address,
    required String emergencyContactName,
    required String emergencyContactPhone,
    required String bloodGroup,
  }) async {
    try {
      // Create Firebase user account
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (userCredential.user != null) {
        // Create Patient model with medical data
        final patient = Patient(
          id: userCredential.user!.uid,
          email: email,
          firstName: firstName,
          lastName: lastName,
          createdAt: DateTime.now(),
          dateOfBirth: dateOfBirth,
          gender: gender,
          phoneNumber: phoneNumber,
          address: address,
          emergencyContactName: emergencyContactName,
          emergencyContactPhone: emergencyContactPhone,
          bloodGroup: bloodGroup,
          isActive: true,
        );

        // Save patient data to Firestore
        await _firestore
            .collection('users')
            .doc(userCredential.user!.uid)
            .set(patient.toMap());

        return patient;
      }
    } on FirebaseAuthException catch (e) {
      throw Exception(_handleAuthException(e));
    } catch (e) {
      throw Exception('Failed to register patient: ${e.toString()}');
    }
    
    return null;
  }

  /// Send password reset email
  /// forgot password functionality
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      throw Exception(_handleAuthException(e));
    } catch (e) {
      throw Exception('Failed to send password reset email: ${e.toString()}');
    }
  }

  /// Sign out current user
  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } catch (e) {
      throw Exception('Failed to sign out: ${e.toString()}');
    }
  }

  /// Get current user data from Firestore
  Future<Map<String, dynamic>?> getCurrentUserData() async {
    try {
      if (_auth.currentUser != null) {
        final DocumentSnapshot userDoc = await _firestore
            .collection('users')
            .doc(_auth.currentUser!.uid)
            .get();

        if (userDoc.exists) {
          final userData = userDoc.data() as Map<String, dynamic>;
          userData['id'] = userDoc.id;
          return userData;
        }
      }
    } catch (e) {
      throw Exception('Failed to get user data: ${e.toString()}');
    }
    return null;
  }

  /// Helper method to handle Firebase Auth exceptions
  String _handleAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'weak-password':
        return 'The password provided is too weak. Please use at least 6 characters.';
      case 'email-already-in-use':
        return 'An account already exists for this email address.';
      case 'invalid-email':
        return 'The email address is not valid.';
      case 'operation-not-allowed':
        return 'Email/password accounts are not enabled.';
      case 'user-disabled':
        return 'This user account has been disabled.';
      case 'user-not-found':
        return 'No user found for this email address.';
      case 'wrong-password':
        return 'Wrong password provided.';
      case 'too-many-requests':
        return 'Too many failed login attempts. Please try again later.';
      case 'network-request-failed':
        return 'Network error. Please check your internet connection.';
      default:
        return e.message ?? 'An authentication error occurred.';
    }
  }
}