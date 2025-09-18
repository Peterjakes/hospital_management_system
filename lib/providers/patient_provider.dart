import 'package:flutter/material.dart';
import 'package:hospital_management_system/models/patient_model.dart';
import 'package:hospital_management_system/services/firestore_service.dart';

class PatientProvider with ChangeNotifier {
  final FirestoreService _firestoreService = FirestoreService();

  List<Patient> _patients = [];
  List<Patient> _filteredPatients = [];
  Patient? _selectedPatient;
  bool _isLoading = false;
  String? _errorMessage;
  String _searchQuery = '';

  List<Patient> get patients => _patients;
  List<Patient> get filteredPatients => _filteredPatients.isEmpty ? _patients : _filteredPatients;
  Patient? get selectedPatient => _selectedPatient;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String get searchQuery => _searchQuery;

  // Load patients from Firestore
  Future<void> loadPatients({int? limit}) async {
    _setLoading(true);
    _clearError();
    try {
      _patients = await _firestoreService.getAllPatients(limit: limit);
      _filteredPatients = [];
      _setLoading(false);
      notifyListeners();
    } catch (e) {
      _setError('Failed to load patients: ${e.toString()}');
      _setLoading(false);
    }
  }

  // Search patients by name, email, or phone
  void searchPatients(String query) {
    _searchQuery = query;
    if (query.isEmpty) {
      _filteredPatients = [];
    } else {
      final lower = query.toLowerCase();
      _filteredPatients = _patients.where((p) =>
        '${p.firstName} ${p.lastName}'.toLowerCase().contains(lower) ||
        p.email.toLowerCase().contains(lower) ||
        p.phoneNumber.toLowerCase().contains(lower)
      ).toList();
    }
    notifyListeners();
  }

  // Filter patients by gender
  void filterByGender(String? gender) {
    if (gender == null || gender.isEmpty) {
      _filteredPatients = [];
    } else {
      _filteredPatients = _patients.where((p) => 
        p.gender?.toLowerCase() == gender.toLowerCase()
      ).toList();
    }
    notifyListeners();
  }

  // Filter patients by blood group
  void filterByBloodGroup(String? group) {
    if (group == null || group.isEmpty) {
      _filteredPatients = [];
    } else {
      _filteredPatients = _patients.where((p) => 
        p.bloodGroup?.toLowerCase() == group.toLowerCase()
      ).toList();
    }
    notifyListeners();
  }

  // Helper methods
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
  }

  void _setError(String error) {
    _errorMessage = error;
    notifyListeners();
  }

  // Clear all filters
  void clearFilters() {
    _filteredPatients = [];
    _searchQuery = '';
    notifyListeners();
  }

  // Select a specific patient
  void selectPatient(Patient patient) {
    _selectedPatient = patient;
    notifyListeners();
  }

  // Clear selected patient
  void clearSelectedPatient() {
    _selectedPatient = null;
    notifyListeners();
  }
}