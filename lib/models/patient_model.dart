import 'package:hospital_management_system/models/user_model.dart';

// Base patient structure
class Patient extends User {
  final DateTime dateOfBirth;
  final String gender;
  final String phoneNumber;
  final String address;
  final String emergencyContactName;
  final String emergencyContactPhone;
  final String bloodGroup;

  Patient({
    required super.id,
    required super.email,
    required super.firstName,
    required super.lastName,
    required super.createdAt,
    super.isActive,
    required this.dateOfBirth,
    required this.gender,
    required this.phoneNumber,
    required this.address,
    required this.emergencyContactName,
    required this.emergencyContactPhone,
    required this.bloodGroup,
  }) : super(role: UserRole.patient);
}
