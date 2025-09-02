import 'package:cloud_firestore/cloud_firestore.dart';

/// Enum defining different user roles in the hospital system
enum UserRole {
  patient,
  doctor,
  admin,
}

/// Extension to convert UserRole enum to string and vice versa
/// dart does not support methods in enums directly
extension UserRoleExtension on UserRole {
  /// Convert enum to string for database storage
  String get value {
    switch (this) {
      case UserRole.patient:
        return 'patient';
      case UserRole.doctor:
        return 'doctor';
      case UserRole.admin:
        return 'admin';
    }
  }
  
  /// Create UserRole from string value
  static UserRole fromString(String role) {
    switch (role.toLowerCase()) {
      case 'patient':
        return UserRole.patient;
      case 'doctor':
        return UserRole.doctor;
      case 'admin':
        return UserRole.admin;
      default:
        return UserRole.patient; // Default to patient if unknown role
    }
  }
}

/// Base User model representing common user properties
class User {
  final String id;
  final String email;
  final String firstName;
  final String lastName;
  final UserRole role;
  final DateTime createdAt;
  final bool isActive;

  User({
    required this.id,
    required this.email,
    required this.firstName,
    required this.lastName,
    required this.role,
    required this.createdAt,
    this.isActive = true,
  });

  /// Get full name by combining first and last name
  String get fullName => '$firstName $lastName';

  /// Create User instance from Firestore document
  /// data serialization
  factory User.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    return User(
      id: doc.id,
      email: data['email'] ?? '',
      firstName: data['firstName'] ?? '',
      lastName: data['lastName'] ?? '',
      role: UserRoleExtension.fromString(data['role'] ?? 'patient'),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isActive: data['isActive'] ?? true,
    );
  }

  /// Convert User instance to Map for Firestore storage
  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'firstName': firstName,
      'lastName': lastName,
      'role': role.value,
      'createdAt': Timestamp.fromDate(createdAt),
      'isActive': isActive,
    };
  }
}