import 'package:hospital_management_system/models/user_model.dart';

// Doctor model with basic professional information
class Doctor extends User {
  final String specialization;
  final String qualification;
  final String licenseNumber;
  final String phoneNumber;
  final String departmentId;
  final int experienceYears;
  final double consultationFee;
  final bool isAvailable;

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
  }) : super(role: UserRole.doctor);
}
