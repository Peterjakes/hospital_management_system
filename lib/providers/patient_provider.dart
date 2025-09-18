import 'package:flutter/material.dart';
import 'package:hospital_management_system/models/patient_model.dart';
import 'package:hospital_management_system/services/firestore_service.dart';

/// Patient provider managing patient-related state and operations
// handles patient data, medical history, and profile management
class PatientProvider with ChangeNotifier {
  final FirestoreService _firestoreService = FirestoreService();

  // State variables
  List<Patient> _patients = [];
  List<Patient> _filteredPatients = [];
  Patient? _selectedPatient;
  bool _isLoading = false;
  String? _errorMessage;
  String _searchQuery = '';

  // Getters for accessing state
  List<Patient> get patients => _patients;
  List<Patient> get filteredPatients => _filteredPatients.isEmpty ? _patients : _filteredPatients;
  Patient? get selectedPatient => _selectedPatient;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String get searchQuery => _searchQuery;

  /// Get active patients only
  /// returns patients who are currently active
  List<Patient> get activePatients {
    return _patients.where((patient) => patient.isActive).toList();
  }

  /// Get patients by age group
  /// Returns patients filtered by age range
  List<Patient> getPatientsByAgeGroup(int minAge, int maxAge) {
    return _patients.where((patient) {
      final age = patient.age;
      return age >= minAge && age <= maxAge;
    }).toList();
  }

  /// Get patients by blood group
  /// Returns patients with specific blood group
  List<Patient> getPatientsByBloodGroup(String bloodGroup) {
    return _patients.where((patient) => patient.bloodGroup == bloodGroup).toList();
  }

  /// Get patients with allergies
  /// Returns patients who have recorded allergies
  List<Patient> getPatientsWithAllergies() {
    return _patients.where((patient) => patient.allergies.isNotEmpty).toList();
  }

  /// Load all patients (Admin function)
  /// Fetches all patients from Firestore
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

  /// Get patient by ID
  /// Fetches specific patient and sets as selected
  Future<void> getPatient(String patientId) async {
    _setLoading(true);
    _clearError();

    try {
      _selectedPatient = await _firestoreService.getPatient(patientId);
      _setLoading(false);
      notifyListeners();
    } catch (e) {
      _setError('Failed to load patient: ${e.toString()}');
      _setLoading(false);
    }
  }

  /// Search patients by name, email, or phone
  /// Filters patients based on search query
  void searchPatients(String query) {
    _searchQuery = query;
    
    if (query.isEmpty) {
      _filteredPatients = [];
    } else {
      _filteredPatients = _patients.where((patient) {
        final fullName = '${patient.firstName} ${patient.lastName}'.toLowerCase();
        final email = patient.email.toLowerCase();
        final phone = patient.phoneNumber.toLowerCase();
        final searchLower = query.toLowerCase();
        
        return fullName.contains(searchLower) || 
               email.contains(searchLower) ||
               phone.contains(searchLower);
      }).toList();
    }
    
    notifyListeners();
  }

  /// Filter patients by gender
  /// Filters patients based on selected gender
  void filterByGender(String? gender) {
    if (gender == null || gender.isEmpty) {
      _filteredPatients = [];
    } else {
      _filteredPatients = _patients.where((patient) {
        return patient.gender.toLowerCase() == gender.toLowerCase();
      }).toList();
    }
    
    notifyListeners();
  }

  /// Filter patients by blood group
  /// Filters patients based on selected blood group
  void filterByBloodGroup(String? bloodGroup) {
    if (bloodGroup == null || bloodGroup.isEmpty) {
      _filteredPatients = [];
    } else {
      _filteredPatients = _patients.where((patient) {
        return patient.bloodGroup == bloodGroup;
      }).toList();
    }
    
    notifyListeners();
  }

  /// Sort patients by name
  /// Sorts current patient list alphabetically by name
  void sortByName() {
    final patientsToSort = _filteredPatients.isEmpty ? _patients : _filteredPatients;
    patientsToSort.sort((a, b) => a.fullName.compareTo(b.fullName));
    
    if (_filteredPatients.isNotEmpty) {
      _filteredPatients = patientsToSort;
    } else {
      _patients = patientsToSort;
    }
    
    notifyListeners();
  }

  /// Sort patients by age
  /// Sorts current patient list by age (youngest to oldest)
  void sortByAge({bool youngestFirst = true}) {
    final patientsToSort = _filteredPatients.isEmpty ? _patients : _filteredPatients;
    
    if (youngestFirst) {
      patientsToSort.sort((a, b) => a.age.compareTo(b.age));
    } else {
      patientsToSort.sort((a, b) => b.age.compareTo(a.age));
    }
    
    if (_filteredPatients.isNotEmpty) {
      _filteredPatients = patientsToSort;
    } else {
      _patients = patientsToSort;
    }
    
    notifyListeners();
  }

  /// Sort patients by registration date
  /// Sorts current patient list by registration date (newest first)
  void sortByRegistrationDate({bool newestFirst = true}) {
    final patientsToSort = _filteredPatients.isEmpty ? _patients : _filteredPatients;
    
    if (newestFirst) {
      patientsToSort.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    } else {
      patientsToSort.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    }
    
    if (_filteredPatients.isNotEmpty) {
      _filteredPatients = patientsToSort;
    } else {
      _patients = patientsToSort;
    }
    
    notifyListeners();
  }

  /// Update patient profile
  /// Updates patient's personal information
  Future<bool> updatePatientProfile({
    required String patientId,
    String? firstName,
    String? lastName,
    String? phoneNumber,
    String? address,
    String? emergencyContactName,
    String? emergencyContactPhone,
    String? profileImageUrl,
  }) async {
    _setLoading(true);
    _clearError();

    try {
      final updateData = <String, dynamic>{};
      
      if (firstName != null) updateData['firstName'] = firstName;
      if (lastName != null) updateData['lastName'] = lastName;
      if (phoneNumber != null) updateData['phoneNumber'] = phoneNumber;
      if (address != null) updateData['address'] = address;
      if (emergencyContactName != null) updateData['emergencyContactName'] = emergencyContactName;
      if (emergencyContactPhone != null) updateData['emergencyContactPhone'] = emergencyContactPhone;
      if (profileImageUrl != null) updateData['profileImageUrl'] = profileImageUrl;

      await _firestoreService.updatePatient(patientId, updateData);

      // Update local state
      _updateLocalPatient(patientId, updateData);

      _setLoading(false);
      notifyListeners();
      return true;
    } catch (e) {
      _setError('Failed to update profile: ${e.toString()}');
      _setLoading(false);
      return false;
    }
  }

  /// Update patient medical information
  /// Updates patient's medical history and allergies
  Future<bool> updatePatientMedicalInfo({
    required String patientId,
    String? bloodGroup,
    List<String>? allergies,
    List<String>? medicalHistory,
    String? insuranceNumber,
    String? insuranceProvider,
  }) async {
    _setLoading(true);
    _clearError();

    try {
      final updateData = <String, dynamic>{};
      
      if (bloodGroup != null) updateData['bloodGroup'] = bloodGroup;
      if (allergies != null) updateData['allergies'] = allergies;
      if (medicalHistory != null) updateData['medicalHistory'] = medicalHistory;
      if (insuranceNumber != null) updateData['insuranceNumber'] = insuranceNumber;
      if (insuranceProvider != null) updateData['insuranceProvider'] = insuranceProvider;

      await _firestoreService.updatePatient(patientId, updateData);

      // Update local state
      _updateLocalPatient(patientId, updateData);

      _setLoading(false);
      notifyListeners();
      return true;
    } catch (e) {
      _setError('Failed to update medical info: ${e.toString()}');
      _setLoading(false);
      return false;
    }
  }

  /// Add allergy to patient
  /// Adds a new allergy to patient's allergy list
  Future<bool> addPatientAllergy(String patientId, String allergy) async {
    final patient = _patients.firstWhere((p) => p.id == patientId, orElse: () => _selectedPatient!);
    
    if (patient.allergies.contains(allergy)) {
      _setError('Allergy already exists');
      return false;
    }

    final updatedAllergies = List<String>.from(patient.allergies)..add(allergy);
    
    return await updatePatientMedicalInfo(
      patientId: patientId,
      allergies: updatedAllergies,
    );
  }

  /// Remove allergy from patient
  /// Removes an allergy from patient's allergy list
  Future<bool> removePatientAllergy(String patientId, String allergy) async {
    final patient = _patients.firstWhere((p) => p.id == patientId, orElse: () => _selectedPatient!);
    
    final updatedAllergies = List<String>.from(patient.allergies)..remove(allergy);
    
    return await updatePatientMedicalInfo(
      patientId: patientId,
      allergies: updatedAllergies,
    );
  }

  /// Add medical history entry
  /// Adds a new entry to patient's medical history
  Future<bool> addMedicalHistoryEntry(String patientId, String entry) async {
    final patient = _patients.firstWhere((p) => p.id == patientId, orElse: () => _selectedPatient!);
    
    final updatedHistory = List<String>.from(patient.medicalHistory)..add(entry);
    
    return await updatePatientMedicalInfo(
      patientId: patientId,
      medicalHistory: updatedHistory,
    );
  }

  /// Remove medical history entry
  /// Removes an entry from patient's medical history
  Future<bool> removeMedicalHistoryEntry(String patientId, String entry) async {
    final patient = _patients.firstWhere((p) => p.id == patientId, orElse: () => _selectedPatient!);
    
    final updatedHistory = List<String>.from(patient.medicalHistory)..remove(entry);
    
    return await updatePatientMedicalInfo(
      patientId: patientId,
      medicalHistory: updatedHistory,
    );
  }

  /// Get patient statistics
  /// Returns various statistics about patients
  Map<String, dynamic> getPatientStatistics() {
    if (_patients.isEmpty) return {};

    final totalPatients = _patients.length;
    final malePatients = _patients.where((p) => p.gender.toLowerCase() == 'male').length;
    final femalePatients = _patients.where((p) => p.gender.toLowerCase() == 'female').length;
    
    // Age groups
    final children = _patients.where((p) => p.age < 18).length;
    final adults = _patients.where((p) => p.age >= 18 && p.age < 65).length;
    final seniors = _patients.where((p) => p.age >= 65).length;
    
    // Blood groups
    final bloodGroups = <String, int>{};
    for (final patient in _patients) {
      bloodGroups[patient.bloodGroup] = (bloodGroups[patient.bloodGroup] ?? 0) + 1;
    }
    
    // Patients with allergies
    final patientsWithAllergies = _patients.where((p) => p.allergies.isNotEmpty).length;
    
    return {
      'total': totalPatients,
      'male': malePatients,
      'female': femalePatients,
      'children': children,
      'adults': adults,
      'seniors': seniors,
      'bloodGroups': bloodGroups,
      'withAllergies': patientsWithAllergies,
    };
  }

  /// Get unique blood groups
  /// Returns list of all unique blood groups from patients
  List<String> get bloodGroups {
    final groups = _patients.map((patient) => patient.bloodGroup).toSet().toList();
    groups.sort();
    return groups;
  }

  /// Get patients by insurance provider
  /// Returns patients filtered by insurance provider
  List<Patient> getPatientsByInsurance(String insuranceProvider) {
    return _patients.where((patient) {
      return patient.insuranceProvider?.toLowerCase() == insuranceProvider.toLowerCase();
    }).toList();
  }

  /// Clear all filters
  /// Resets all filters and shows all patients
  void clearFilters() {
    _searchQuery = '';
    _filteredPatients = [];
    notifyListeners();
  }

  /// Update local patient in state
  /// Helper method to update patient in local lists
  void _updateLocalPatient(String patientId, Map<String, dynamic> updates) {
    // Update in main patients list
    final patientIndex = _patients.indexWhere((p) => p.id == patientId);
    if (patientIndex != -1) {
      // In a real implementation, you would properly update the patient object
      notifyListeners();
    }

    // Update in filtered patients list
    final filteredIndex = _filteredPatients.indexWhere((p) => p.id == patientId);
    if (filteredIndex != -1) {
      notifyListeners();
    }

    // Update selected patient
    if (_selectedPatient?.id == patientId) {
      notifyListeners();
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

  /// Clear selected patient
  void clearSelectedPatient() {
    _selectedPatient = null;
    notifyListeners();
  }

  /// Refresh patients
  /// Reloads patients from Firestore
  Future<void> refreshPatients() async {
    await loadPatients();
  }
}