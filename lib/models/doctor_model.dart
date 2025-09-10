import 'package:hospital_management_system/models/user_model.dart';

// Doctor model with scheduling and availability
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

  // Scheduling fields
  final List<String> availableDays;
  final String startTime;
  final String endTime;
  final int consultationDuration;

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

  String get formattedFee => 'KSh ${consultationFee.toStringAsFixed(0)}';
  String get formattedRating => rating.toStringAsFixed(1);

  // Check if doctor is available on specific day
  bool isAvailableOnDay(String dayOfWeek) {
    return availableDays.contains(dayOfWeek);
  }

  // Generate available time slots
  List<String> getAvailableTimeSlots() {
    List<String> slots = [];
    final startHour = int.parse(startTime.split(':')[0]);
    final startMinute = int.parse(startTime.split(':')[1]);
    final endHour = int.parse(this.endTime.split(':')[0]);
    final endMinute = int.parse(this.endTime.split(':')[1]);

    DateTime currentSlot = DateTime(2024, 1, 1, startHour, startMinute);
    final endDateTime = DateTime(2024, 1, 1, endHour, endMinute);

    while (currentSlot.isBefore(endDateTime)) {
      final timeString =
          '${currentSlot.hour.toString().padLeft(2, '0')}:${currentSlot.minute.toString().padLeft(2, '0')}';
      slots.add(timeString);
      currentSlot = currentSlot.add(Duration(minutes: consultationDuration));
    }

    return slots;
  }
}
