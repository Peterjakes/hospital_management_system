import 'package:flutter/material.dart';
import 'package:hospital_management_system/models/appointment_model.dart';
import 'package:hospital_management_system/services/firestore_service.dart';
import 'package:hospital_management_system/services/mpesa_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Appointment provider managing appointment-related state and operations
class AppointmentProvider with ChangeNotifier {
  final FirestoreService _firestoreService = FirestoreService();

  // State variables
  List<Appointment> _appointments = [];
  List<Appointment> _patientAppointments = [];
  List<Appointment> _doctorAppointments = [];
  Appointment? _selectedAppointment;
  bool _isLoading = false;
  String? _errorMessage;
  bool _isPaymentPolling = false;
  String? _paymentStatus;

  // Getters for accessing state
  List<Appointment> get appointments => _appointments;
  List<Appointment> get patientAppointments => _patientAppointments;
  List<Appointment> get doctorAppointments => _doctorAppointments;
  Appointment? get selectedAppointment => _selectedAppointment;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isPaymentPolling => _isPaymentPolling;
  String? get paymentStatus => _paymentStatus;

  // Get upcoming appointments
  List<Appointment> get upcomingAppointments {
    return _appointments.where((appointment) => appointment.isUpcoming).toList();
  }

  // Helper method to get day of week
  String _getDayOfWeek(DateTime date) {
    const days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    return days[date.weekday - 1];
  }

  /// Book appointment with M-Pesa payment integration
  Future<Map<String, dynamic>> bookAppointmentWithPayment({
    required String patientId,
    required String doctorId,
    required String departmentId,
    required DateTime appointmentDate,
    required String appointmentTime,
    required String reasonForVisit,
    required double consultationFee,
    required String phoneNumber,
  }) async {
    _setLoading(true);
    _clearError();

    try {
      // Normalize date to midnight for consistent comparison
      final normalizedDate = DateTime(
        appointmentDate.year, 
        appointmentDate.month, 
        appointmentDate.day
      );

      // Normalize time format (ensure HH:mm format)
      final normalizedTime = appointmentTime.length == 4 ? "0$appointmentTime" : appointmentTime;

      debugPrint('=== APPOINTMENT BOOKING WITH PAYMENT DEBUG ===');
      debugPrint('Patient ID: $patientId');
      debugPrint('Doctor ID: $doctorId');
      debugPrint('Normalized Date: $normalizedDate');
      debugPrint('Normalized Time: $normalizedTime');
      debugPrint('Phone Number: $phoneNumber');

      // Check doctor availability first
      final isAvailable = await _firestoreService.checkDoctorAvailability(
        doctorId: doctorId,
        date: normalizedDate,
        time: normalizedTime,
      );

      if (!isAvailable) {
        _setError('Doctor is not available at the selected time');
        _setLoading(false);
        return {'success': false, 'error': 'Doctor not available'};
      }

      // Create temporary booking model
      final tempBooking = Appointment(
        id: '', // Will be set after payment success
        patientId: patientId,
        doctorId: doctorId,
        departmentId: departmentId,
        appointmentDate: normalizedDate,
        appointmentTime: normalizedTime,
        reasonForVisit: reasonForVisit,
        consultationFee: consultationFee,
        paymentStatus: PaymentStatus.pending,
        isPaid: false,
        paymentPhoneNumber: phoneNumber,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Initiate M-Pesa payment
      final paymentResponse = await MpesaService.initiateSTKPush(
        phoneNumber: phoneNumber,
        amount: consultationFee,
        accountReference: 'APPOINTMENT-${DateTime.now().millisecondsSinceEpoch}',
        transactionDesc: 'Medical Appointment Payment',
      );

      if (paymentResponse != null && paymentResponse['success'] == true) {
        final checkoutRequestId = paymentResponse['data']['checkoutRequestId'];
        debugPrint('Payment initiated with CheckoutRequestID: $checkoutRequestId');

        // Start polling payment status
        _startPaymentPolling(checkoutRequestId, tempBooking);

        _setLoading(false);
        return {
          'success': true, 
          'checkoutRequestId': checkoutRequestId,
          'message': 'Payment request sent to your phone'
        };
      } else {
        _setError('Failed to initiate payment');
        _setLoading(false);
        return {'success': false, 'error': 'Payment initiation failed'};
      }

    } catch (e) {
      debugPrint('Booking error: ${e.toString()}');
      _setError('Failed to book appointment: ${e.toString()}');
      _setLoading(false);
      return {'success': false, 'error': e.toString()};
    }
  }

  /// Start polling payment status
  void _startPaymentPolling(String checkoutRequestId, Appointment tempBooking) {
    _isPaymentPolling = true;
    _paymentStatus = 'Waiting for payment...';
    notifyListeners();

    _pollPaymentStatus(checkoutRequestId, tempBooking);
  }

  /// Poll payment status until success, failure, or timeout
  Future<void> _pollPaymentStatus(String checkoutRequestId, Appointment tempBooking) async {
    int attempts = 0;
    const maxAttempts = 30; // 5 minutes polling (every 10 seconds)
    
    while (attempts < maxAttempts && _isPaymentPolling) {
      await Future.delayed(const Duration(seconds: 10));
      
      try {
        final statusResponse = await MpesaService.getTransactionStatus(
          checkoutRequestId: checkoutRequestId,
        );

        if (statusResponse != null && statusResponse['success'] == true) {
          final data = statusResponse['data'];
          final status = data['status'] as String? ?? 'PENDING';
          
          debugPrint('Payment status check: $status');
          _paymentStatus = 'Checking payment status... ($status)';
          notifyListeners();

          if (status == 'SUCCESS') {
            // Payment successful → save booking
            await _saveBookingAfterPayment(tempBooking, data);
            return;
          } else if (status == 'CANCELLED') {
            _handlePaymentFailure('Payment cancelled by user');
            return;
          } else if (status == 'FAILED') {
            _handlePaymentFailure('Payment failed: ${data['resultDesc'] ?? 'Unknown error'}');
            return;
          }
          // Continue polling if status is PENDING
        }
        
        attempts++;
      } catch (e) {
        debugPrint('Error polling payment status: $e');
        attempts++;
        
        if (attempts >= maxAttempts) {
          _handlePaymentFailure('Payment verification timeout. Please contact support if money was deducted.');
          return;
        }
      }
    }
    
    // Timeout reached
    if (_isPaymentPolling) {
      _handlePaymentFailure('Payment timeout. Please try again.');
    }
  }

  /// Save booking after successful payment
  Future<void> _saveBookingAfterPayment(Appointment tempBooking, Map<String, dynamic> paymentData) async {
    try {
      debugPrint('Saving booking after successful payment');
      
      // Create appointment with payment details
      final appointmentWithPayment = tempBooking.copyWith(
        paymentStatus: PaymentStatus.paid,
        isPaid: true,
        paymentReference: paymentData['checkoutRequestId'],
        mpesaReceiptNumber: paymentData['mpesaReceiptNumber'],
        paymentAmount: double.tryParse(paymentData['amount']?.toString() ?? '0'),
        paymentDate: paymentData['transactionDate'],
        paidAt: DateTime.now(),
      );

      // Save to Firestore
      final appointmentId = await _firestoreService.createAppointment(appointmentWithPayment);
      debugPrint('Appointment saved with ID: $appointmentId');
      
      // Create final appointment with ID
      final finalAppointment = appointmentWithPayment.copyWith(id: appointmentId);
      
      // Add to ALL relevant local state lists
      _appointments.add(finalAppointment);
      _patientAppointments.add(finalAppointment); 
      
      // Update status
      _isPaymentPolling = false;
      _paymentStatus = 'Payment successful! Appointment booked.';
      
      debugPrint('Appointment booking completed successfully');
      debugPrint('Total patient appointments now: ${_patientAppointments.length}');
      notifyListeners();
      
    } catch (e) {
      debugPrint('Error saving booking after payment: $e');
      _handlePaymentFailure('Payment successful but booking failed. Please contact support.');
    }
  }

  /// Handle payment failure
  void _handlePaymentFailure(String message) {
    _isPaymentPolling = false;
    _paymentStatus = null;
    _setError(message);
    debugPrint('Payment failed: $message');
  }

  /// Stop payment polling (for cleanup)
  void stopPaymentPolling() {
    _isPaymentPolling = false;
    _paymentStatus = null;
    notifyListeners();
  }

  // Book new appointment with payment reference support (legacy method)
  Future<bool> bookAppointment({
    required String patientId,
    required String doctorId,
    required String departmentId,
    required DateTime appointmentDate,
    required String appointmentTime,
    required String reasonForVisit,
    required double consultationFee,
    String? paymentReference,
    String? paymentStatus,
    String? mpesaReceiptNumber,
    double? paymentAmount,
    String? paymentDate,
  }) async {
    _setLoading(true);
    _clearError();

    try {
      // Normalize date to midnight for consistent comparison
      final normalizedDate = DateTime(
        appointmentDate.year, 
        appointmentDate.month, 
        appointmentDate.day
      );

      // Normalize time format (ensure HH:mm format)
      final normalizedTime = appointmentTime.length == 4 ? "0$appointmentTime" : appointmentTime;

      debugPrint('=== APPOINTMENT BOOKING DEBUG ===');
      debugPrint('Patient ID: $patientId');
      debugPrint('Doctor ID: $doctorId');
      debugPrint('Original Date: $appointmentDate');
      debugPrint('Normalized Date: $normalizedDate');
      debugPrint('Original Time: $appointmentTime');
      debugPrint('Normalized Time: $normalizedTime');
      debugPrint('Day of Week: ${_getDayOfWeek(normalizedDate)}');
      debugPrint('Payment Reference: $paymentReference');
      debugPrint('M-Pesa Receipt: $mpesaReceiptNumber');

      // Check doctor availability with normalized date and time
      final isAvailable = await _firestoreService.checkDoctorAvailability(
        doctorId: doctorId,
        date: normalizedDate,
        time: normalizedTime,
      );

      debugPrint('Doctor Available: $isAvailable');

      if (!isAvailable) {
        debugPrint('❌ Doctor not available - setting error');
        _setError('Doctor is not available at the selected time');
        _setLoading(false);
        return false;
      }

      // Determine payment status properly
      PaymentStatus finalPaymentStatus = PaymentStatus.pending;
      bool finalIsPaid = false;
      DateTime? finalPaidAt;
      
      if (paymentStatus != null) {
        finalPaymentStatus = PaymentStatusExtension.fromString(paymentStatus);
      } else if (paymentReference != null) {
        // If payment reference exists, assume payment is completed
        finalPaymentStatus = PaymentStatus.paid;
      }

      if (finalPaymentStatus == PaymentStatus.paid) {
        finalIsPaid = true;
        finalPaidAt = DateTime.now();
      }

      debugPrint('Payment Status: ${finalPaymentStatus.value}');
      debugPrint('Is Paid: $finalIsPaid');

      // Create appointment object with correct payment information
      final appointment = Appointment(
        id: '', // Will be set by Firestore
        patientId: patientId,
        doctorId: doctorId,
        departmentId: departmentId,
        appointmentDate: normalizedDate,
        appointmentTime: normalizedTime,
        reasonForVisit: reasonForVisit,
        consultationFee: consultationFee,
        paymentReference: paymentReference,
        paymentStatus: finalPaymentStatus,
        isPaid: finalIsPaid,
        paymentPhoneNumber: paymentReference != null ? 'M-Pesa' : null,
        paidAt: finalPaidAt,
        mpesaReceiptNumber: mpesaReceiptNumber,
        paymentAmount: paymentAmount ?? consultationFee,
        paymentDate: paymentDate,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      debugPrint('Creating appointment with data: ${appointment.toMap()}');

      // Save appointment to Firestore
      final appointmentId = await _firestoreService.createAppointment(appointment);
      debugPrint('✅ Appointment created with ID: $appointmentId');
      
      // Create updated appointment with the generated ID
      final appointmentWithId = appointment.copyWith(id: appointmentId);
      
      // Add to ALL relevant local state lists
      _appointments.add(appointmentWithId);
      _patientAppointments.add(appointmentWithId); // CRITICAL FIX: Add to patient appointments

      debugPrint('=== BOOKING SUCCESS ===');
      debugPrint('Total patient appointments now: ${_patientAppointments.length}');
      _setLoading(false);
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('❌ Booking error: ${e.toString()}');
      debugPrint('Stack trace: ${StackTrace.current}');
      _setError('Failed to book appointment: ${e.toString()}');
      _setLoading(false);
      return false;
    }
  }

  /// Update payment status for an appointment
  Future<bool> updatePaymentStatus({
    required String appointmentId,
    required String paymentStatus,
    String? paymentReference,
    String? mpesaReceiptNumber,
    double? paymentAmount,
    String? paymentDate,
  }) async {
    _setLoading(true);
    _clearError();

    try {
      // Use correct field names that match your Firestore structure
      final updateData = <String, dynamic>{
        'paymentStatus': paymentStatus,
        'isPaid': paymentStatus == 'paid',
        'updatedAt': DateTime.now(),
      };

      if (paymentReference != null) {
        updateData['paymentReference'] = paymentReference;
      }

      if (mpesaReceiptNumber != null) {
        updateData['mpesaReceiptNumber'] = mpesaReceiptNumber;
      }

      if (paymentAmount != null) {
        updateData['paymentAmount'] = paymentAmount;
      }

      if (paymentDate != null) {
        updateData['paymentDate'] = paymentDate;
      }

      if (paymentStatus == 'paid') {
        updateData['paidAt'] = DateTime.now();
      }

      await _firestoreService.updateAppointment(appointmentId, updateData);

      // Update local state
      _updateLocalPaymentStatus(
        appointmentId, 
        paymentStatus, 
        paymentReference, 
        mpesaReceiptNumber,
        paymentAmount,
        paymentDate,
      );

      _setLoading(false);
      notifyListeners();
      return true;
    } catch (e) {
      _setError('Failed to update payment status: ${e.toString()}');
      _setLoading(false);
      return false;
    }
  }

  /// Helper method to update payment status in local state
  void _updateLocalPaymentStatus(
    String appointmentId, 
    String paymentStatus, 
    String? paymentReference, 
    String? mpesaReceiptNumber,
    double? paymentAmount,
    String? paymentDate,
  ) {
    final newPaymentStatus = PaymentStatusExtension.fromString(paymentStatus);
    final isPaid = newPaymentStatus == PaymentStatus.paid;
    final paidAt = isPaid ? DateTime.now() : null;

    // Update in main appointments list
    final appointmentIndex = _appointments.indexWhere((a) => a.id == appointmentId);
    if (appointmentIndex != -1) {
      _appointments[appointmentIndex] = _appointments[appointmentIndex].copyWith(
        paymentStatus: newPaymentStatus,
        isPaid: isPaid,
        paymentReference: paymentReference,
        mpesaReceiptNumber: mpesaReceiptNumber,
        paymentAmount: paymentAmount,
        paymentDate: paymentDate,
        paidAt: paidAt,
        updatedAt: DateTime.now(),
      );
    }
    
    // Update in patient appointments list
    final patientIndex = _patientAppointments.indexWhere((a) => a.id == appointmentId);
    if (patientIndex != -1) {
      _patientAppointments[patientIndex] = _patientAppointments[patientIndex].copyWith(
        paymentStatus: newPaymentStatus,
        isPaid: isPaid,
        paymentReference: paymentReference,
        mpesaReceiptNumber: mpesaReceiptNumber,
        paymentAmount: paymentAmount,
        paymentDate: paymentDate,
        paidAt: paidAt,
        updatedAt: DateTime.now(),
      );
    }
    
    // Update in doctor appointments list
    final doctorIndex = _doctorAppointments.indexWhere((a) => a.id == appointmentId);
    if (doctorIndex != -1) {
      _doctorAppointments[doctorIndex] = _doctorAppointments[doctorIndex].copyWith(
        paymentStatus: newPaymentStatus,
        isPaid: isPaid,
        paymentReference: paymentReference,
        mpesaReceiptNumber: mpesaReceiptNumber,
        paymentAmount: paymentAmount,
        paymentDate: paymentDate,
        paidAt: paidAt,
        updatedAt: DateTime.now(),
      );
    }
  }

  /// Load patient appointments with comprehensive debugging
  Future<void> loadPatientAppointments(String patientId) async {
    _setLoading(true);
    _clearError();

    try {
      debugPrint('=== LOADING PATIENT APPOINTMENTS ===');
      debugPrint('Patient ID: $patientId');
      debugPrint('Current appointments count: ${_patientAppointments.length}');
      
      _patientAppointments = await _firestoreService.getPatientAppointments(patientId);
      
      debugPrint('Loaded appointments count: ${_patientAppointments.length}');
      
      // Print details of each appointment
      for (int i = 0; i < _patientAppointments.length; i++) {
        final appointment = _patientAppointments[i];
        debugPrint('Appointment $i:');
        debugPrint('  ID: ${appointment.id}');
        debugPrint('  Date: ${appointment.formattedDateTime}');
        debugPrint('  Reason: ${appointment.reasonForVisit}');
        debugPrint('  Status: ${appointment.status.displayName}');
        debugPrint('  Is Paid: ${appointment.isPaid}');
      }
      
      _setLoading(false);
      notifyListeners();
      
    } catch (e, stackTrace) {
      debugPrint('Error loading patient appointments: $e');
      debugPrint('Stack trace: $stackTrace');
      _setError('Failed to load appointments: ${e.toString()}');
      _setLoading(false);
    }
  }

  /// Debug method to test appointment retrieval
  Future<void> testAppointmentCreation(String patientId) async {
    try {
      debugPrint('=== TESTING APPOINTMENT RETRIEVAL ===');
      
      // Get all appointments and see if any match our patient
      final allAppointmentsQuery = await FirebaseFirestore.instance
          .collection('appointments')
          .get();
      
      debugPrint('Total appointments in database: ${allAppointmentsQuery.docs.length}');
      
      final matchingAppointments = allAppointmentsQuery.docs.where((doc) {
        final data = doc.data();
        return data['patientId'] == patientId;
      }).toList();
      
      debugPrint('Appointments matching patient ID $patientId: ${matchingAppointments.length}');
      
      for (var doc in matchingAppointments) {
        final data = doc.data();
        debugPrint('Found appointment: ${doc.id}');
        debugPrint('  Patient ID: ${data['patientId']}');
        debugPrint('  Doctor ID: ${data['doctorId']}');
        debugPrint('  Date: ${data['appointmentDate']}');
        debugPrint('  Time: ${data['appointmentTime']}');
        debugPrint('  Reason: ${data['reasonForVisit']}');
      }
      
    } catch (e) {
      debugPrint('Error in test method: $e');
    }
  }

  /// Add a method to refresh patient appointments after booking
  Future<void> refreshPatientAppointments(String patientId) async {
    try {
      debugPrint('=== REFRESHING PATIENT APPOINTMENTS ===');
      _patientAppointments = await _firestoreService.getPatientAppointments(patientId);
      debugPrint('Refreshed appointments count: ${_patientAppointments.length}');
      notifyListeners();
    } catch (e) {
      debugPrint('Error refreshing patient appointments: $e');
    }
  }

  /// Load doctor appointments
  Future<void> loadDoctorAppointments(String doctorId, {DateTime? date}) async {
    _setLoading(true);
    _clearError();

    try {
      _doctorAppointments = await _firestoreService.getDoctorAppointments(
        doctorId,
        date: date,
      );
      _setLoading(false);
      notifyListeners();
    } catch (e) {
      _setError('Failed to load appointments: ${e.toString()}');
      _setLoading(false);
    }
  }


  /// Update appointment status
  Future<bool> updateAppointmentStatus(
    String appointmentId,
    AppointmentStatus status,
  ) async {
    _setLoading(true);
    _clearError();

    try {
      await _firestoreService.updateAppointment(appointmentId, {
        'status': status.value,
        'updatedAt': DateTime.now(),
      });

      // Update local state using copyWith
      _updateLocalAppointmentStatus(appointmentId, status);

      _setLoading(false);
      notifyListeners();
      return true;
    } catch (e) {
      _setError('Failed to update appointment: ${e.toString()}');
      _setLoading(false);
      return false;
    }
  }

  /// Cancel appointment
  Future<bool> cancelAppointment(String appointmentId, String reason) async {
    _setLoading(true);
    _clearError();

    try {
      await _firestoreService.cancelAppointment(appointmentId, reason);
      
      // Update local state
      _updateLocalAppointmentStatus(appointmentId, AppointmentStatus.cancelled);
      
      _setLoading(false);
      notifyListeners();
      return true;
    } catch (e) {
      _setError('Failed to cancel appointment: ${e.toString()}');
      _setLoading(false);
      return false;
    }
  }

  /// Helper method to update appointment status in local state
  void _updateLocalAppointmentStatus(String appointmentId, AppointmentStatus status) {
    // Update in main appointments list
    final appointmentIndex = _appointments.indexWhere((a) => a.id == appointmentId);
    if (appointmentIndex != -1) {
      _appointments[appointmentIndex] = _appointments[appointmentIndex].copyWith(
        status: status,
        updatedAt: DateTime.now(),
      );
    }
    
    // Update in patient appointments list
    final patientIndex = _patientAppointments.indexWhere((a) => a.id == appointmentId);
    if (patientIndex != -1) {
      _patientAppointments[patientIndex] = _patientAppointments[patientIndex].copyWith(
        status: status,
        updatedAt: DateTime.now(),
      );
    }
    
    // Update in doctor appointments list
    final doctorIndex = _doctorAppointments.indexWhere((a) => a.id == appointmentId);
    if (doctorIndex != -1) {
      _doctorAppointments[doctorIndex] = _doctorAppointments[doctorIndex].copyWith(
        status: status,
        updatedAt: DateTime.now(),
      );
    }
  }

  /// Set loading state
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  /// Set error message
  void _setError(String error) {
    _errorMessage = error;
    notifyListeners();
  }

  /// Clear error message
  void _clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  /// Clear error manually
  void clearError() {
    _clearError();
  }

  @override
  void dispose() {
    stopPaymentPolling();
    super.dispose();
  }

  
}