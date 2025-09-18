import 'package:flutter/material.dart';
import 'package:hospital_management_system/models/doctor_model.dart';
import 'package:hospital_management_system/services/firestore_service.dart';

/// Doctor provider managing doctor-related state and operations
/// Handles doctor data, search, filtering, and CRUD operations
class DoctorProvider with ChangeNotifier {
  final FirestoreService _firestoreService = FirestoreService();

  // State variables
  List<Doctor> _doctors = [];
  List<Doctor> _filteredDoctors = [];
  Doctor? _selectedDoctor;
  bool _isLoading = false;
  String? _errorMessage;
  String _searchQuery = '';
  String? _selectedDepartment;
  String? _selectedSpecialization;

  // Getters for accessing state
  List<Doctor> get doctors => _doctors;
  List<Doctor> get filteredDoctors => _filteredDoctors.isEmpty ? _doctors : _filteredDoctors;
  Doctor? get selectedDoctor => _selectedDoctor;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String get searchQuery => _searchQuery;
  String? get selectedDepartment => _selectedDepartment;
  String? get selectedSpecialization => _selectedSpecialization;

  /// Get available doctors only
  /// Returns doctors who are currently available for appointments
  List<Doctor> get availableDoctors {
    return _doctors.where((doctor) => doctor.isAvailable && doctor.isActive).toList();
  }

  /// Get doctors by rating (highest first)
  /// Returns doctors sorted by their rating in descending order
  List<Doctor> get doctorsByRating {
    final sortedDoctors = List<Doctor>.from(_doctors);
    sortedDoctors.sort((a, b) => b.rating.compareTo(a.rating));
    return sortedDoctors;
  }

  /// Get unique specializations
  /// Returns list of all unique specializations from doctors
  List<String> get specializations {
    final specs = _doctors.map((doctor) => doctor.specialization).toSet().toList();
    specs.sort();
    return specs;
  }

  /// Load all doctors
  /// Fetches all doctors from Firestore and updates state
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

  /// Load doctors by department
  /// Fetches doctors filtered by specific department
  Future<void> loadDoctorsByDepartment(String departmentId) async {
    _setLoading(true);
    _clearError();

    try {
      _doctors = await _firestoreService.getDoctorsByDepartment(departmentId);
      _filteredDoctors = [];
      _selectedDepartment = departmentId;
      _setLoading(false);
      notifyListeners();
    } catch (e) {
      _setError('Failed to load doctors: ${e.toString()}');
      _setLoading(false);
    }
  }

  /// Get doctor by ID
  /// Fetches specific doctor and sets as selected
  Future<void> getDoctor(String doctorId) async {
    _setLoading(true);
    _clearError();

    try {
      _selectedDoctor = await _firestoreService.getDoctor(doctorId);
      _setLoading(false);
      notifyListeners();
    } catch (e) {
      _setError('Failed to load doctor: ${e.toString()}');
      _setLoading(false);
    }
  }

  /// Search doctors by name or specialization - ENHANCED
  /// Filters doctors based on search query
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

  /// Filter doctors by specialization - ENHANCED
  /// Filters doctors based on selected specialization
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

  /// Filter doctors by department
  /// Filters doctors based on selected department
  void filterByDepartment(String? departmentId) {
    _selectedDepartment = departmentId;
    
    if (departmentId == null || departmentId.isEmpty) {
      _filteredDoctors = [];
    } else {
      _filteredDoctors = _doctors.where((doctor) {
        return doctor.departmentId == departmentId;
      }).toList();
    }
    
    notifyListeners();
  }

  /// Filter doctors by availability
  /// Shows only available doctors
  void filterByAvailability(bool availableOnly) {
    if (availableOnly) {
      _filteredDoctors = _doctors.where((doctor) => doctor.isAvailable).toList();
    } else {
      _filteredDoctors = [];
    }
    
    notifyListeners();
  }

  /// Sort doctors by rating - ENHANCED
  /// Sorts current doctor list by rating (high to low)
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

  /// Sort doctors by experience - ENHANCED
  /// Sorts current doctor list by experience years (high to low)
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

  /// Sort doctors by consultation fee - ENHANCED
  /// Sorts current doctor list by fee (low to high)
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

  /// Update doctor availability
  /// Updates doctor's availability status
  Future<bool> updateDoctorAvailability(String doctorId, bool isAvailable) async {
    _setLoading(true);
    _clearError();

    try {
      await _firestoreService.updateDoctor(doctorId, {
        'isAvailable': isAvailable,
      });

      // Update local state
      _updateLocalDoctor(doctorId, {'isAvailable': isAvailable});

      _setLoading(false);
      notifyListeners();
      return true;
    } catch (e) {
      _setError('Failed to update availability: ${e.toString()}');
      _setLoading(false);
      return false;
    }
  }

  /// Update doctor schedule
  /// Updates doctor's working hours and available days
  Future<bool> updateDoctorSchedule({
    required String doctorId,
    required List<String> availableDays,
    required String startTime,
    required String endTime,
    required int consultationDuration,
  }) async {
    _setLoading(true);
    _clearError();

    try {
      await _firestoreService.updateDoctor(doctorId, {
        'availableDays': availableDays,
        'startTime': startTime,
        'endTime': endTime,
        'consultationDuration': consultationDuration,
      });

      // Update local state
      _updateLocalDoctor(doctorId, {
        'availableDays': availableDays,
        'startTime': startTime,
        'endTime': endTime,
        'consultationDuration': consultationDuration,
      });

      _setLoading(false);
      notifyListeners();
      return true;
    } catch (e) {
      _setError('Failed to update schedule: ${e.toString()}');
      _setLoading(false);
      return false;
    }
  }

  /// Update doctor profile
  /// Updates doctor's profile information
  Future<bool> updateDoctorProfile({
    required String doctorId,
    String? firstName,
    String? lastName,
    String? phoneNumber,
    String? biography,
    String? profileImageUrl,
    double? consultationFee,
  }) async {
    _setLoading(true);
    _clearError();

    try {
      final updateData = <String, dynamic>{};
      
      if (firstName != null) updateData['firstName'] = firstName;
      if (lastName != null) updateData['lastName'] = lastName;
      if (phoneNumber != null) updateData['phoneNumber'] = phoneNumber;
      if (biography != null) updateData['biography'] = biography;
      if (profileImageUrl != null) updateData['profileImageUrl'] = profileImageUrl;
      if (consultationFee != null) updateData['consultationFee'] = consultationFee;

      await _firestoreService.updateDoctor(doctorId, updateData);

      // Update local state
      _updateLocalDoctor(doctorId, updateData);

      _setLoading(false);
      notifyListeners();
      return true;
    } catch (e) {
      _setError('Failed to update profile: ${e.toString()}');
      _setLoading(false);
      return false;
    }
  }

  /// Delete doctor (Admin only)
  /// Soft deletes doctor by setting isActive to false
  Future<bool> deleteDoctor(String doctorId) async {
    _setLoading(true);
    _clearError();

    try {
      await _firestoreService.deleteDoctor(doctorId);

      // Remove from local state
      _doctors.removeWhere((doctor) => doctor.id == doctorId);
      _filteredDoctors.removeWhere((doctor) => doctor.id == doctorId);

      if (_selectedDoctor?.id == doctorId) {
        _selectedDoctor = null;
      }

      _setLoading(false);
      notifyListeners();
      return true;
    } catch (e) {
      _setError('Failed to delete doctor: ${e.toString()}');
      _setLoading(false);
      return false;
    }
  }

  /// Get doctor's available time slots for a specific day
  /// Returns available time slots based on doctor's schedule
  List<String> getDoctorTimeSlots(String doctorId, String dayOfWeek) {
    final doctor = _doctors.firstWhere(
      (d) => d.id == doctorId,
      orElse: () => _selectedDoctor!,
    );

    if (doctor.isAvailableOnDay(dayOfWeek)) {
      return doctor.getAvailableTimeSlots();
    }

    return [];
  }

  /// Check if doctor is available on specific day
  /// Returns true if doctor works on the given day
  bool isDoctorAvailableOnDay(String doctorId, String dayOfWeek) {
    final doctor = _doctors.firstWhere(
      (d) => d.id == doctorId,
      orElse: () => _selectedDoctor!,
    );

    return doctor.isAvailableOnDay(dayOfWeek);
  }

  /// Get doctors with highest ratings
  /// Returns top-rated doctors (rating >= 4.0)
  List<Doctor> getTopRatedDoctors({int limit = 10}) {
    final topDoctors = _doctors.where((doctor) => doctor.rating >= 4.0).toList();
    topDoctors.sort((a, b) => b.rating.compareTo(a.rating));
    
    return topDoctors.take(limit).toList();
  }

  /// Get doctors by experience level
  /// Returns doctors filtered by minimum experience years
  List<Doctor> getDoctorsByExperience(int minYears) {
    return _doctors.where((doctor) => doctor.experienceYears >= minYears).toList();
  }

  /// Clear all filters - ENHANCED
  /// Resets all filters and shows all doctors
  void clearFilters() {
    _searchQuery = '';
    _selectedDepartment = null;
    _selectedSpecialization = null;
    _filteredDoctors = [];
    notifyListeners();
  }

  /// Update local doctor in state
  /// Helper method to update doctor in local lists
  void _updateLocalDoctor(String doctorId, Map<String, dynamic> updates) {
    // Update in main doctors list
    final doctorIndex = _doctors.indexWhere((d) => d.id == doctorId);
    if (doctorIndex != -1) {
      // In a real implementation, you would properly update the doctor object
      notifyListeners();
    }

    // Update in filtered doctors list
    final filteredIndex = _filteredDoctors.indexWhere((d) => d.id == doctorId);
    if (filteredIndex != -1) {
      notifyListeners();
    }

    // Update selected doctor
    if (_selectedDoctor?.id == doctorId) {
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

  /// Clear selected doctor
  void clearSelectedDoctor() {
    _selectedDoctor = null;
    notifyListeners();
  }

  /// Refresh doctors
  /// Reloads doctors from Firestore
  Future<void> refreshDoctors() async {
    await loadDoctors();
  }
}