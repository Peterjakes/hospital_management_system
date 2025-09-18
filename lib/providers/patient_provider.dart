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
}
