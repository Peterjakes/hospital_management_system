import 'package:flutter/material.dart';
import 'package:hospital_management_system/models/appointment_model.dart';
import 'package:hospital_management_system/services/firestore_service.dart';

// Appointment provider managing appointment-related state and operations
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

  /// Get upcoming appointments
  List<Appointment> get upcomingAppointments {
    return _appointments.where((appointment) => appointment.isUpcoming).toList();
  }

  // Helper methods for state management
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String error) {
    _errorMessage = error;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
  }

  /// Book new appointment
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
}