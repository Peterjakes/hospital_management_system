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
  final List<String> allergies;
  final List<String> medicalHistory;
  final String? insuranceNumber;
  final String? insuranceProvider;
  final String? profileImageUrl;

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
    this.allergies = const [],
    this.medicalHistory = const [],
    this.insuranceNumber,
    this.insuranceProvider,
    this.profileImageUrl,
  }) : super(role: UserRole.patient);

    // Calculate patient's age from date of birth
  int get age {
    final now = DateTime.now();
    int age = now.year - dateOfBirth.year;

    if (now.month < dateOfBirth.month ||
        (now.month == dateOfBirth.month && now.day < dateOfBirth.day)) {
      age--;
    }
    return age;
  }

  // Get formatted date of birth
  String get formattedDateOfBirth {
    return '${dateOfBirth.day}/${dateOfBirth.month}/${dateOfBirth.year}';
  }

  // Check if patient has any allergies
  bool get hasAllergies => allergies.isNotEmpty;

  // Check if patient has medical history
  bool get hasMedicalHistory => medicalHistory.isNotEmpty;

  // Check if patient has insurance
  bool get hasInsurance =>
      insuranceNumber != null && insuranceNumber!.isNotEmpty;



      

}
