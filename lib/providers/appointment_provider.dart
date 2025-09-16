import 'package:flutter/material.dart';
import 'package:hospital_management_system/models/appointment_model.dart';
import 'package:hospital_management_system/services/firestore_service.dart';

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

  // Getters for accessing state
  List<Appointment> get appointments => _appointments;
  List<Appointment> get patientAppointments => _patientAppointments;
  List<Appointment> get doctorAppointments => _doctorAppointments;
  Appointment? get selectedAppointment => _selectedAppointment;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // Get upcoming appointments
  List<Appointment> get upcomingAppointments {
    return _appointments.where((appointment) => appointment.isUpcoming).toList();
  }

  // Book new appointment
  Future<bool> bookAppointment({
    required String patientId,
    required String doctorId,
    required String departmentId,
    required DateTime appointmentDate,
    required String appointmentTime,
    required String reasonForVisit,
    required double consultationFee,
  }) async {
    _setLoading(true);
    _clearError();

    try {
      // Check doctor availability first
      final isAvailable = await _firestoreService.checkDoctorAvailability(
        doctorId: doctorId,
        date: appointmentDate,
        time: appointmentTime,
      );

      if (!isAvailable) {
        _setError('Doctor is not available at the selected time');
        _setLoading(false);
        return false;
      }

      // Create appointment object
      final appointment = Appointment(
        id: '', // will be set by Firestore
        patientId: patientId,
        doctorId: doctorId,
        departmentId: departmentId,
        appointmentDate: appointmentDate,
        appointmentTime: appointmentTime,
        reasonForVisit: reasonForVisit,
        consultationFee: consultationFee,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Save appointment to Firestore
      final appointmentId = await _firestoreService.createAppointment(appointment);
      
      // Create updated appointment with the generated ID
      final appointmentWithId = Appointment(
        id: appointmentId,
        patientId: patientId,
        doctorId: doctorId,
        departmentId: departmentId,
        appointmentDate: appointmentDate,
        appointmentTime: appointmentTime,
        reasonForVisit: reasonForVisit,
        consultationFee: consultationFee,
        createdAt: appointment.createdAt,
        updatedAt: appointment.updatedAt,
      );
      
      // Add to local state
      _appointments.add(appointmentWithId);

      _setLoading(false);
      notifyListeners();
      return true;
    } catch (e) {
      _setError('Failed to book appointment: ${e.toString()}');
      _setLoading(false);
      return false;
    }
  }

  /// Load patient appointments
  Future<void> loadPatientAppointments(String patientId) async {
    _setLoading(true);
    _clearError();

    try {
      _patientAppointments = await _firestoreService.getPatientAppointments(patientId);
      _setLoading(false);
      notifyListeners();
    } catch (e) {
      _setError('Failed to load appointments: ${e.toString()}');
      _setLoading(false);
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
      });

      // Update local state
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
      // Use copyWith if available, otherwise create new appointment
      try {
        _appointments[appointmentIndex] = _appointments[appointmentIndex].copyWith(status: status);
      } catch (e) {
        // If copyWith doesn't exist, find and replace manually
        final oldAppointment = _appointments[appointmentIndex];
        _appointments[appointmentIndex] = Appointment(
          id: oldAppointment.id,
          patientId: oldAppointment.patientId,
          doctorId: oldAppointment.doctorId,
          departmentId: oldAppointment.departmentId,
          appointmentDate: oldAppointment.appointmentDate,
          appointmentTime: oldAppointment.appointmentTime,
          reasonForVisit: oldAppointment.reasonForVisit,
          consultationFee: oldAppointment.consultationFee,
          status: status,
          createdAt: oldAppointment.createdAt,
          updatedAt: DateTime.now(),
        );
      }
    }
    
    // Update in patient appointments list
    final patientIndex = _patientAppointments.indexWhere((a) => a.id == appointmentId);
    if (patientIndex != -1) {
      try {
        _patientAppointments[patientIndex] = _patientAppointments[patientIndex].copyWith(status: status);
      } catch (e) {
        final oldAppointment = _patientAppointments[patientIndex];
        _patientAppointments[patientIndex] = Appointment(
          id: oldAppointment.id,
          patientId: oldAppointment.patientId,
          doctorId: oldAppointment.doctorId,
          departmentId: oldAppointment.departmentId,
          appointmentDate: oldAppointment.appointmentDate,
          appointmentTime: oldAppointment.appointmentTime,
          reasonForVisit: oldAppointment.reasonForVisit,
          consultationFee: oldAppointment.consultationFee,
          status: status,
          createdAt: oldAppointment.createdAt,
          updatedAt: DateTime.now(),
        );
      }
    }
    
    // Update in doctor appointments list
    final doctorIndex = _doctorAppointments.indexWhere((a) => a.id == appointmentId);
    if (doctorIndex != -1) {
      try {
        _doctorAppointments[doctorIndex] = _doctorAppointments[doctorIndex].copyWith(status: status);
      } catch (e) {
        final oldAppointment = _doctorAppointments[doctorIndex];
        _doctorAppointments[doctorIndex] = Appointment(
          id: oldAppointment.id,
          patientId: oldAppointment.patientId,
          doctorId: oldAppointment.doctorId,
          departmentId: oldAppointment.departmentId,
          appointmentDate: oldAppointment.appointmentDate,
          appointmentTime: oldAppointment.appointmentTime,
          reasonForVisit: oldAppointment.reasonForVisit,
          consultationFee: oldAppointment.consultationFee,
          status: status,
          createdAt: oldAppointment.createdAt,
          updatedAt: DateTime.now(),
        );
      }
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
}