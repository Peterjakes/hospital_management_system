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

  // Medical data
  final String? notes;
  final String? diagnosis;
  final String? prescription;
  final String? prescriptionFileUrl;

  // Payment data
  final double consultationFee;
  final bool isPaid;
  final String? paymentId;

  // Cancellation data
  final String? cancelReason;
  final DateTime? cancelledAt;

  // Metadata
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
}

extension AppointmentLogic on Appointment {
  // Formatted appointment date + time
  String get formattedDateTime {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${appointmentDate.day} ${months[appointmentDate.month - 1]} ${appointmentDate.year} at $appointmentTime';
  }

  // Formatted consultation fee
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
}
