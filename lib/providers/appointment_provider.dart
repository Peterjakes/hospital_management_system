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
}
