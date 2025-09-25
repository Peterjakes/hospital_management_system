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

// Payment status enumeration for M-Pesa integration
enum PaymentStatus {
  pending,
  paid,
  failed,
  refunded,
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

// Extension for PaymentStatus enum
extension PaymentStatusExtension on PaymentStatus {
  String get value {
    switch (this) {
      case PaymentStatus.pending:
        return 'pending';
      case PaymentStatus.paid:
        return 'paid';
      case PaymentStatus.failed:
        return 'failed';
      case PaymentStatus.refunded:
        return 'refunded';
    }
  }

  String get displayName {
    switch (this) {
      case PaymentStatus.pending:
        return 'Pending';
      case PaymentStatus.paid:
        return 'Paid';
      case PaymentStatus.failed:
        return 'Failed';
      case PaymentStatus.refunded:
        return 'Refunded';
    }
  }

  static PaymentStatus fromString(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return PaymentStatus.pending;
      case 'paid':
        return PaymentStatus.paid;
      case 'failed':
        return PaymentStatus.failed;
      case 'refunded':
        return PaymentStatus.refunded;
      default:
        return PaymentStatus.pending;
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
  final bool isPaid; // Kept for backward compatibility
  final PaymentStatus paymentStatus; // New payment status enum
  final String? paymentId; // Generic payment ID (kept for backward compatibility)
  final String? paymentReference; // M-Pesa checkout request ID
  final String? mpesaReceiptNumber; // M-Pesa receipt number after successful payment
  final String? paymentPhoneNumber; // Phone number used for M-Pesa payment
  final double? paymentAmount; // Actual amount paid (may differ from consultation fee)
  final String? paymentDate; // Date when payment was processed (ISO string)
  final DateTime? paidAt; // Timestamp when payment was completed
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
    this.isPaid = false, // Derived from paymentStatus
    this.paymentStatus = PaymentStatus.pending,
    this.paymentId,
    this.paymentReference,
    this.mpesaReceiptNumber,
    this.paymentPhoneNumber,
    this.paymentAmount,
    this.paymentDate,
    this.paidAt,
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

  // Get formatted payment amount (actual amount paid)
  String get formattedPaymentAmount {
    final amount = paymentAmount ?? consultationFee;
    return 'KSh ${amount.toStringAsFixed(0)}';
  }

  // Get payment status display with icon
  String get paymentStatusDisplay {
    switch (paymentStatus) {
      case PaymentStatus.pending:
        return '⏳ Payment Pending';
      case PaymentStatus.paid:
        return '✅ Paid';
      case PaymentStatus.failed:
        return '❌ Payment Failed';
      case PaymentStatus.refunded:
        return '💰 Refunded';
    }
  }

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

  // Check if payment is completed
  bool get isPaymentCompleted => paymentStatus == PaymentStatus.paid;

  // Check if payment is pending
  bool get isPaymentPending => paymentStatus == PaymentStatus.pending;

  // Check if payment has failed
  bool get hasPaymentFailed => paymentStatus == PaymentStatus.failed;

  // Get payment method display
  String get paymentMethodDisplay {
    if (paymentReference != null) {
      return 'M-Pesa';
    } else if (paymentId != null) {
      return 'Other';
    }
    return 'Not Specified';
  }

  // Get M-Pesa receipt info
  String? get mpesaReceiptInfo {
    if (mpesaReceiptNumber != null) {
      return 'Receipt: $mpesaReceiptNumber';
    }
    return null;
  }

  // Get payment date display
  String? get paymentDateDisplay {
    if (paymentDate != null) {
      try {
        final date = DateTime.parse(paymentDate!);
        return '${date.day}/${date.month}/${date.year}';
      } catch (e) {
        return paymentDate; // Return as-is if parsing fails
      }
    }
    return null;
  }

  // Check if there's a payment discrepancy
  bool get hasPaymentDiscrepancy {
    if (paymentAmount == null) return false;
    return (paymentAmount! - consultationFee).abs() > 0.01; // Allow for small rounding differences
  }

  // Create Appointment from Firestore document
  factory Appointment.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    // Handle backward compatibility for payment status
    PaymentStatus derivedPaymentStatus = PaymentStatus.pending;
    bool derivedIsPaid = data['isPaid'] ?? false;
    
    if (data['paymentStatus'] != null) {
      derivedPaymentStatus = PaymentStatusExtension.fromString(data['paymentStatus']);
      derivedIsPaid = derivedPaymentStatus == PaymentStatus.paid;
    } else {
      // Fallback to isPaid field for backward compatibility
      derivedPaymentStatus = derivedIsPaid ? PaymentStatus.paid : PaymentStatus.pending;
    }
    
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
      isPaid: derivedIsPaid,
      paymentStatus: derivedPaymentStatus,
      paymentId: data['paymentId'],
      paymentReference: data['paymentReference'],
      mpesaReceiptNumber: data['mpesaReceiptNumber'],
      paymentPhoneNumber: data['paymentPhoneNumber'],
      paymentAmount: data['paymentAmount']?.toDouble(),
      paymentDate: data['paymentDate'],
      paidAt: (data['paidAt'] as Timestamp?)?.toDate(),
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
      'paymentStatus': paymentStatus.value,
      'paymentId': paymentId,
      'paymentReference': paymentReference,
      'mpesaReceiptNumber': mpesaReceiptNumber,
      'paymentPhoneNumber': paymentPhoneNumber,
      'paymentAmount': paymentAmount,
      'paymentDate': paymentDate,
      'paidAt': paidAt != null ? Timestamp.fromDate(paidAt!) : null,
      'cancelReason': cancelReason,
      'cancelledAt': cancelledAt != null ? Timestamp.fromDate(cancelledAt!) : null,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  // Create a copy of Appointment with updated fields
  Appointment copyWith({
    String? id,
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
    PaymentStatus? paymentStatus,
    String? paymentId,
    String? paymentReference,
    String? mpesaReceiptNumber,
    String? paymentPhoneNumber,
    double? paymentAmount,
    String? paymentDate,
    DateTime? paidAt,
    String? cancelReason,
    DateTime? cancelledAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    final newPaymentStatus = paymentStatus ?? this.paymentStatus;
    final newIsPaid = isPaid ?? (newPaymentStatus == PaymentStatus.paid);
    
    return Appointment(
      id: id ?? this.id,
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
      isPaid: newIsPaid,
      paymentStatus: newPaymentStatus,
      paymentId: paymentId ?? this.paymentId,
      paymentReference: paymentReference ?? this.paymentReference,
      mpesaReceiptNumber: mpesaReceiptNumber ?? this.mpesaReceiptNumber,
      paymentPhoneNumber: paymentPhoneNumber ?? this.paymentPhoneNumber,
      paymentAmount: paymentAmount ?? this.paymentAmount,
      paymentDate: paymentDate ?? this.paymentDate,
      paidAt: paidAt ?? this.paidAt,
      cancelReason: cancelReason ?? this.cancelReason,
      cancelledAt: cancelledAt ?? this.cancelledAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // Create appointment with M-Pesa payment details
  factory Appointment.withMpesaPayment({
    required String id,
    required String patientId,
    required String doctorId,
    required String departmentId,
    required DateTime appointmentDate,
    required String appointmentTime,
    required String reasonForVisit,
    required double consultationFee,
    required String paymentReference,
    required String paymentPhoneNumber,
    AppointmentStatus status = AppointmentStatus.scheduled,
    PaymentStatus paymentStatus = PaymentStatus.pending,
    String? mpesaReceiptNumber,
    double? paymentAmount,
    String? paymentDate,
    DateTime? paidAt,
  }) {
    final now = DateTime.now();
    return Appointment(
      id: id,
      patientId: patientId,
      doctorId: doctorId,
      departmentId: departmentId,
      appointmentDate: appointmentDate,
      appointmentTime: appointmentTime,
      status: status,
      reasonForVisit: reasonForVisit,
      consultationFee: consultationFee,
      isPaid: paymentStatus == PaymentStatus.paid,
      paymentStatus: paymentStatus,
      paymentReference: paymentReference,
      paymentPhoneNumber: paymentPhoneNumber,
      mpesaReceiptNumber: mpesaReceiptNumber,
      paymentAmount: paymentAmount ?? consultationFee,
      paymentDate: paymentDate,
      paidAt: paidAt,
      createdAt: now,
      updatedAt: now,
    );
  }
}