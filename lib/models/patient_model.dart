import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hospital_management_system/models/user_model.dart';

// Patient model extending the base User model
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
    
    // Adjust if birthday hasn't occurred this year
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
  // Learning: Boolean helper methods
  bool get hasAllergies => allergies.isNotEmpty;

  // Check if patient has medical history
  bool get hasMedicalHistory => medicalHistory.isNotEmpty;

  // Check if patient has insurance
  bool get hasInsurance => insuranceNumber != null && insuranceNumber!.isNotEmpty;

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

  //Convert Patient to Map for Firestore storage
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

  //Create a copy of Patient with updated fields
  //Immutable object updates
  Patient copyWith({
    String? firstName,
    String? lastName,
    String? email,
    DateTime? dateOfBirth,
    String? gender,
    String? phoneNumber,
    String? address,
    String? emergencyContactName,
    String? emergencyContactPhone,
    String? bloodGroup,
    List<String>? allergies,
    List<String>? medicalHistory,
    String? insuranceNumber,
    String? insuranceProvider,
    String? profileImageUrl,
    bool? isActive,
  }) {
    return Patient(
      id: id,
      email: email ?? this.email,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      createdAt: createdAt,
      isActive: isActive ?? this.isActive,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      gender: gender ?? this.gender,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      address: address ?? this.address,
      emergencyContactName: emergencyContactName ?? this.emergencyContactName,
      emergencyContactPhone: emergencyContactPhone ?? this.emergencyContactPhone,
      bloodGroup: bloodGroup ?? this.bloodGroup,
      allergies: allergies ?? this.allergies,
      medicalHistory: medicalHistory ?? this.medicalHistory,
      insuranceNumber: insuranceNumber ?? this.insuranceNumber,
      insuranceProvider: insuranceProvider ?? this.insuranceProvider,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
    );
  }
}