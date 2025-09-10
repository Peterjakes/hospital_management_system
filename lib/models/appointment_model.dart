import 'package:cloud_firestore/cloud_firestore.dart';

// Appointment status enumeration
enum AppointmentStatus {
  scheduled,
  confirmed,
  inProgress,
  completed,
  cancelled,
  noShow,
}

// Extension for AppointmentStatus enum
extension AppointmentStatusExtension on AppointmentStatus {
  String get value {
    switch (this) {
      case AppointmentStatus.scheduled:
        return 'scheduled';
      case AppointmentStatus.confirmed:
        return 'confirmed';
      case AppointmentStatus.inProgress:
        return 'in_progress';
      case AppointmentStatus.completed:
        return 'completed';
      case AppointmentStatus.cancelled:
        return 'cancelled';
      case AppointmentStatus.noShow:
        return 'no_show';
    }
  }

  String get displayName {
    switch (this) {
      case AppointmentStatus.scheduled:
        return 'Scheduled';
      case AppointmentStatus.confirmed:
        return 'Confirmed';
      case AppointmentStatus.inProgress:
        return 'In Progress';
      case AppointmentStatus.completed:
        return 'Completed';
      case AppointmentStatus.cancelled:
        return 'Cancelled';
      case AppointmentStatus.noShow:
        return 'No Show';
    }
  }
  
  static AppointmentStatus fromString(String status) {
    switch (status.toLowerCase()) {
      case 'scheduled':
        return AppointmentStatus.scheduled;
      case 'confirmed':
        return AppointmentStatus.confirmed;
      case 'in_progress':
        return AppointmentStatus.inProgress;
      case 'completed':
        return AppointmentStatus.completed;
      case 'cancelled':
        return AppointmentStatus.cancelled;
      case 'no_show':
        return AppointmentStatus.noShow;
      default:
        return AppointmentStatus.scheduled;
    }
  }
}

// Appointment model for patient-doctor appointments
class Appointment {
  final String id;
  final String patientId;
  final String doctorId;
  final String departmentId;
  final DateTime appointmentDate;
  final String appointmentTime;
  final AppointmentStatus status;
  final String reasonForVisit;
  final String? notes; // Doctor's notes
  final String? diagnosis; // Doctor's diagnosis
  final String? prescription; // Prescription details
  final String? prescriptionFileUrl; // PDF file URL
  final double consultationFee;
  final bool isPaid;
  final String? paymentId;
  final String? cancelReason;
  final DateTime? cancelledAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  Appointment({
    required this.id,
    required this.patientId,
    required this.doctorId,
    required this.departmentId,
    required this.appointmentDate,
    required this.appointmentTime,
    this.status = AppointmentStatus.scheduled,
    required this.reasonForVisit,
    this.notes,
    this.diagnosis,
    this.prescription,
    this.prescriptionFileUrl,
    required this.consultationFee,
    this.isPaid = false,
    this.paymentId,
    this.cancelReason,
    this.cancelledAt,
    required this.createdAt,
    required this.updatedAt,
  });

  // Get formatted appointment date and time
  String get formattedDateTime {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    
    return '${appointmentDate.day} ${months[appointmentDate.month - 1]} ${appointmentDate.year} at $appointmentTime';
  }

  // Get formatted consultation fee
  String get formattedFee => 'KSh ${consultationFee.toStringAsFixed(0)}';

  // Check if appointment is upcoming
  bool get isUpcoming {
    final now = DateTime.now();
    final appointmentDateTime = DateTime(
      appointmentDate.year,
      appointmentDate.month,
      appointmentDate.day,
      int.parse(appointmentTime.split(':')[0]),
      int.parse(appointmentTime.split(':')[1]),
    );
    
    return appointmentDateTime.isAfter(now) && 
           (status == AppointmentStatus.scheduled || status == AppointmentStatus.confirmed);
  }

  // Check if appointment is today
  bool get isToday {
    final now = DateTime.now();
    return appointmentDate.year == now.year &&
           appointmentDate.month == now.month &&
           appointmentDate.day == now.day;
  }

  // Check if appointment can be cancelled
  bool get canBeCancelled {
    return status == AppointmentStatus.scheduled || status == AppointmentStatus.confirmed;
  }

  // Check if appointment has prescription
  bool get hasPrescription => prescription != null && prescription!.isNotEmpty;

  // Create Appointment from Firestore document
  factory Appointment.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    return Appointment(
      id: doc.id,
      patientId: data['patientId'] ?? '',
      doctorId: data['doctorId'] ?? '',
      departmentId: data['departmentId'] ?? '',
      appointmentDate: (data['appointmentDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      appointmentTime: data['appointmentTime'] ?? '',
      status: AppointmentStatusExtension.fromString(data['status'] ?? 'scheduled'),
      reasonForVisit: data['reasonForVisit'] ?? '',
      notes: data['notes'],
      diagnosis: data['diagnosis'],
      prescription: data['prescription'],
      prescriptionFileUrl: data['prescriptionFileUrl'],
      consultationFee: (data['consultationFee'] ?? 0.0).toDouble(),
      isPaid: data['isPaid'] ?? false,
      paymentId: data['paymentId'],
      cancelReason: data['cancelReason'],
      cancelledAt: (data['cancelledAt'] as Timestamp?)?.toDate(),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  // Convert Appointment to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'patientId': patientId,
      'doctorId': doctorId,
      'departmentId': departmentId,
      'appointmentDate': Timestamp.fromDate(appointmentDate),
      'appointmentTime': appointmentTime,
      'status': status.value,
      'reasonForVisit': reasonForVisit,
      'notes': notes,
      'diagnosis': diagnosis,
      'prescription': prescription,
      'prescriptionFileUrl': prescriptionFileUrl,
      'consultationFee': consultationFee,
      'isPaid': isPaid,
      'paymentId': paymentId,
      'cancelReason': cancelReason,
      'cancelledAt': cancelledAt != null ? Timestamp.fromDate(cancelledAt!) : null,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  // Create a copy of Appointment with updated fields
  Appointment copyWith({
    String? patientId,
    String? doctorId,
    String? departmentId,
    DateTime? appointmentDate,
    String? appointmentTime,
    AppointmentStatus? status,
    String? reasonForVisit,
    String? notes,
    String? diagnosis,
    String? prescription,
    String? prescriptionFileUrl,
    double? consultationFee,
    bool? isPaid,
    String? paymentId,
    String? cancelReason,
    DateTime? cancelledAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Appointment(
      id: id,
      patientId: patientId ?? this.patientId,
      doctorId: doctorId ?? this.doctorId,
      departmentId: departmentId ?? this.departmentId,
      appointmentDate: appointmentDate ?? this.appointmentDate,
      appointmentTime: appointmentTime ?? this.appointmentTime,
      status: status ?? this.status,
      reasonForVisit: reasonForVisit ?? this.reasonForVisit,
      notes: notes ?? this.notes,
      diagnosis: diagnosis ?? this.diagnosis,
      prescription: prescription ?? this.prescription,
      prescriptionFileUrl: prescriptionFileUrl ?? this.prescriptionFileUrl,
      consultationFee: consultationFee ?? this.consultationFee,
      isPaid: isPaid ?? this.isPaid,
      paymentId: paymentId ?? this.paymentId,
      cancelReason: cancelReason ?? this.cancelReason,
      cancelledAt: cancelledAt ?? this.cancelledAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}