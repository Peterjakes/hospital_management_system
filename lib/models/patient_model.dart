import 'package:cloud_firestore/cloud_firestore.dart';
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

  // Create Patient from Firestore document
  factory Patient.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return Patient(
      id: doc.id,
      email: data['email'] ?? '',
      firstName: data['firstName'] ?? '',
      lastName: data['lastName'] ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isActive: data['isActive'] ?? true,
      dateOfBirth: (data['dateOfBirth'] as Timestamp?)?.toDate() ?? DateTime.now(),
      gender: data['gender'] ?? '',
      phoneNumber: data['phoneNumber'] ?? '',
      address: data['address'] ?? '',
      emergencyContactName: data['emergencyContactName'] ?? '',
      emergencyContactPhone: data['emergencyContactPhone'] ?? '',
      bloodGroup: data['bloodGroup'] ?? '',
      allergies: List<String>.from(data['allergies'] ?? []),
      medicalHistory: List<String>.from(data['medicalHistory'] ?? []),
      insuranceNumber: data['insuranceNumber'],
      insuranceProvider: data['insuranceProvider'],
      profileImageUrl: data['profileImageUrl'],
    );
  }

  // Convert Patient to Map for Firestore storage
  @override
  Map<String, dynamic> toMap() {
    final baseMap = super.toMap();
    baseMap.addAll({
      'dateOfBirth': Timestamp.fromDate(dateOfBirth),
      'gender': gender,
      'phoneNumber': phoneNumber,
      'address': address,
      'emergencyContactName': emergencyContactName,
      'emergencyContactPhone': emergencyContactPhone,
      'bloodGroup': bloodGroup,
      'allergies': allergies,
      'medicalHistory': medicalHistory,
      'insuranceNumber': insuranceNumber,
      'insuranceProvider': insuranceProvider,
      'profileImageUrl': profileImageUrl,
    });
    return baseMap;
  }

      

}
