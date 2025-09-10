import 'package:hospital_management_system/models/user_model.dart';

// Doctor model with profile fields
class Doctor extends User {
  final String specialization;
  final String qualification;
  final String licenseNumber;
  final String phoneNumber;
  final String departmentId;
  final int experienceYears;
  final double consultationFee;
  final bool isAvailable;

  // New fields
  final double rating;
  final int totalRatings;
  final String? biography;
  final String? profileImageUrl;

  Doctor({
    required super.id,
    required super.email,
    required super.firstName,
    required super.lastName,
    required super.createdAt,
    super.isActive,
    required this.specialization,
    required this.qualification,
    required this.licenseNumber,
    required this.phoneNumber,
    required this.departmentId,
    required this.experienceYears,
    required this.consultationFee,
    this.isAvailable = true,
    this.rating = 0.0,
    this.totalRatings = 0,
    this.biography,
    this.profileImageUrl,
  }) : super(role: UserRole.doctor);

  // Get formatted consultation fee
  String get formattedFee => 'KSh ${consultationFee.toStringAsFixed(0)}';

  // Get formatted rating display
  String get formattedRating => rating.toStringAsFixed(1);
}