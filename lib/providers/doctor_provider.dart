import 'package:flutter/foundation.dart';
import 'package:hospital_management_system/models/doctor_model.dart';
import 'package:hospital_management_system/services/firestore_service.dart';

class DoctorProvider with ChangeNotifier {
  final FirestoreService _firestoreService = FirestoreService();
  
  // State fields
  List<Doctor> _doctors = [];
  List<Doctor> _filteredDoctors = [];
  Doctor? _selectedDoctor;
  bool _isLoading = false;
  String? _errorMessage;
  String _searchQuery = '';
  String? _selectedSpecialization;
  
  // Getters
  List<Doctor> get doctors => _doctors;
  List<Doctor> get filteredDoctors => _filteredDoctors.isEmpty ? _doctors : _filteredDoctors;
  Doctor? get selectedDoctor => _selectedDoctor;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String get searchQuery => _searchQuery;
  String? get selectedSpecialization => _selectedSpecialization;
  
  /// Get unique specializations from all doctors
  List<String> get specializations {
    final specs = _doctors.map((doctor) => doctor.specialization).toSet().toList();
    specs.sort();
    return specs;
  }
  
  /// Get doctors sorted by rating (highest first)
  List<Doctor> get doctorsByRating {
    final sortedDoctors = List<Doctor>.from(_doctors);
    sortedDoctors.sort((a, b) => b.rating.compareTo(a.rating));
    return sortedDoctors;
  }
  
  /// Load all doctors from Firestore
  Future<void> loadDoctors() async {
    _setLoading(true);
    _clearError();
    try {
      _doctors = await _firestoreService.getAllDoctors();
      _filteredDoctors = [];
      _setLoading(false);
      notifyListeners();
    } catch (e) {
      _setError('Failed to load doctors: ${e.toString()}');
      _setLoading(false);
    }
  }
  
  /// Search doctors by name, specialization, or qualification
  void searchDoctors(String query) {
    _searchQuery = query;
    
    if (query.isEmpty) {
      _filteredDoctors = [];
    } else {
      _filteredDoctors = _doctors.where((doctor) {
        final fullName = '${doctor.firstName} ${doctor.lastName}'.toLowerCase();
        final specialization = doctor.specialization.toLowerCase();
        final qualification = doctor.qualification.toLowerCase();
        final searchLower = query.toLowerCase();
        
        return fullName.contains(searchLower) || 
               specialization.contains(searchLower) ||
               qualification.contains(searchLower);
      }).toList();
    }
    
    notifyListeners();
  }
  
  /// Filter doctors by specialization
  void filterBySpecialization(String? specialization) {
    _selectedSpecialization = specialization;
    
    if (specialization == null || specialization.isEmpty) {
      _filteredDoctors = [];
    } else {
      _filteredDoctors = _doctors.where((doctor) {
        return doctor.specialization.toLowerCase() == specialization.toLowerCase();
      }).toList();
    }
    
    notifyListeners();
  }
  
  /// Sort doctors by rating (high to low)
  void sortByRating() {
    final doctorsToSort = _filteredDoctors.isEmpty ? _doctors : _filteredDoctors;
    doctorsToSort.sort((a, b) => b.rating.compareTo(a.rating));
    
    if (_filteredDoctors.isNotEmpty) {
      _filteredDoctors = doctorsToSort;
    } else {
      _doctors = doctorsToSort;
    }
    
    notifyListeners();
  }
  
  /// Sort doctors by experience (high to low)
  void sortByExperience() {
    final doctorsToSort = _filteredDoctors.isEmpty ? _doctors : _filteredDoctors;
    doctorsToSort.sort((a, b) => b.experienceYears.compareTo(a.experienceYears));
    
    if (_filteredDoctors.isNotEmpty) {
      _filteredDoctors = doctorsToSort;
    } else {
      _doctors = doctorsToSort;
    }
    
    notifyListeners();
  }
  
  /// Sort doctors by consultation fee (low to high by default)
  void sortByFee({bool lowToHigh = true}) {
    final doctorsToSort = _filteredDoctors.isEmpty ? _doctors : _filteredDoctors;
    
    if (lowToHigh) {
      doctorsToSort.sort((a, b) => a.consultationFee.compareTo(b.consultationFee));
    } else {
      doctorsToSort.sort((a, b) => b.consultationFee.compareTo(a.consultationFee));
    }
    
    if (_filteredDoctors.isNotEmpty) {
      _filteredDoctors = doctorsToSort;
    } else {
      _doctors = doctorsToSort;
    }
    
    notifyListeners();
  }
  
  /// Clear all filters and search
  void clearFilters() {
    _searchQuery = '';
    _selectedSpecialization = null;
    _filteredDoctors = [];
    notifyListeners();
  }
  
  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
  
  void _setError(String message) {
    _errorMessage = message;
    notifyListeners();
  }
  
  void _clearError() {
    _errorMessage = null;
  }
}