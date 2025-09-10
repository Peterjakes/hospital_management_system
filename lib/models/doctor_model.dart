import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hospital_management_system/models/user_model.dart';

// Doctor model with professional information and scheduling
class Doctor extends User {
  final String specialization;
  final String qualification;
  final String licenseNumber;
  final String phoneNumber;
  final String departmentId;
  final int experienceYears;
  final double consultationFee;
  final bool isAvailable;
  final double rating;
  final int totalRatings;
  final String? biography;
  final String? profileImageUrl;
  final List<String> availableDays; // ['Monday', 'Tuesday', etc.]
  final String startTime; // '09:00'
  final String endTime; // '17:00'
  final int consultationDuration; // minutes

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
    this.availableDays = const [],
    this.startTime = '09:00',
    this.endTime = '17:00',
    this.consultationDuration = 30,
  }) : super(role: UserRole.doctor);

  // Get formatted consultation fee
  String get formattedFee => 'KSh ${consultationFee.toStringAsFixed(0)}';

  // Get formatted rating display
  String get formattedRating => rating.toStringAsFixed(1);

  // Check if doctor is available on specific day
  bool isAvailableOnDay(String dayOfWeek) {
    return availableDays.contains(dayOfWeek);
  }

  // Get available time slots for the day
  List<String> getAvailableTimeSlots() {
    List<String> slots = [];
    
    // Parse start and end times
    final startHour = int.parse(startTime.split(':')[0]);
    final startMinute = int.parse(startTime.split(':')[1]);
    final endHour = int.parse(this.endTime.split(':')[0]);
    final endMinute = int.parse(this.endTime.split(':')[1]);
    
    // Create DateTime objects for calculation
    DateTime currentSlot = DateTime(2024, 1, 1, startHour, startMinute);
    final endDateTime = DateTime(2024, 1, 1, endHour, endMinute);
    
    // Generate time slots
    while (currentSlot.isBefore(endDateTime)) {
      final timeString = '${currentSlot.hour.toString().padLeft(2, '0')}:${currentSlot.minute.toString().padLeft(2, '0')}';
      slots.add(timeString);
      currentSlot = currentSlot.add(Duration(minutes: consultationDuration));
    }
    
    return slots;
  }

  // Create Doctor from Firestore document
  factory Doctor.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    return Doctor(
      id: doc.id,
      email: data['email'] ?? '',
      firstName: data['firstName'] ?? '',
      lastName: data['lastName'] ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isActive: data['isActive'] ?? true,
      specialization: data['specialization'] ?? '',
      qualification: data['qualification'] ?? '',
      licenseNumber: data['licenseNumber'] ?? '',
      phoneNumber: data['phoneNumber'] ?? '',
      departmentId: data['departmentId'] ?? '',
      experienceYears: data['experienceYears'] ?? 0,
      consultationFee: (data['consultationFee'] ?? 0.0).toDouble(),
      isAvailable: data['isAvailable'] ?? true,
      rating: (data['rating'] ?? 0.0).toDouble(),
      totalRatings: data['totalRatings'] ?? 0,
      biography: data['biography'],
      profileImageUrl: data['profileImageUrl'],
      availableDays: List<String>.from(data['availableDays'] ?? []),
      startTime: data['startTime'] ?? '09:00',
      endTime: data['endTime'] ?? '17:00',
      consultationDuration: data['consultationDuration'] ?? 30,
    );
  }

  // Convert Doctor to Map for Firestore storage
  @override
  Map<String, dynamic> toMap() {
    final baseMap = super.toMap();
    baseMap.addAll({
      'specialization': specialization,
      'qualification': qualification,
      'licenseNumber': licenseNumber,
      'phoneNumber': phoneNumber,
      'departmentId': departmentId,
      'experienceYears': experienceYears,
      'consultationFee': consultationFee,
      'isAvailable': isAvailable,
      'rating': rating,
      'totalRatings': totalRatings,
      'biography': biography,
      'profileImageUrl': profileImageUrl,
      'availableDays': availableDays,
      'startTime': startTime,
      'endTime': endTime,
      'consultationDuration': consultationDuration,
    });
    return baseMap;
  }

  // Create a copy of Doctor with updated fields
  Doctor copyWith({
    String? firstName,
    String? lastName,
    String? email,
    String? specialization,
    String? qualification,
    String? licenseNumber,
    String? phoneNumber,
    String? departmentId,
    int? experienceYears,
    double? consultationFee,
    bool? isAvailable,
    double? rating,
    int? totalRatings,
    String? biography,
    String? profileImageUrl,
    List<String>? availableDays,
    String? startTime,
    String? endTime,
    int? consultationDuration,
    bool? isActive,
  }) {
    return Doctor(
      id: id,
      email: email ?? this.email,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      createdAt: createdAt,
      isActive: isActive ?? this.isActive,
      specialization: specialization ?? this.specialization,
      qualification: qualification ?? this.qualification,
      licenseNumber: licenseNumber ?? this.licenseNumber,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      departmentId: departmentId ?? this.departmentId,
      experienceYears: experienceYears ?? this.experienceYears,
      consultationFee: consultationFee ?? this.consultationFee,
      isAvailable: isAvailable ?? this.isAvailable,
      rating: rating ?? this.rating,
      totalRatings: totalRatings ?? this.totalRatings,
      biography: biography ?? this.biography,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      availableDays: availableDays ?? this.availableDays,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      consultationDuration: consultationDuration ?? this.consultationDuration,
    );
  }
}