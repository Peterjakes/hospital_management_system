import 'package:flutter/foundation.dart';
import 'package:hospital_management_system/models/doctor_model.dart';
import 'package:hospital_management_system/services/firestore_service.dart';

class DoctorProvider with ChangeNotifier {
  final FirestoreService _firestoreService = FirestoreService();

  List<Doctor> _doctors = [];
  List<Doctor> _filteredDoctors = [];
  Doctor? _selectedDoctor;
  bool _isLoading = false;
  String? _errorMessage;
  String _searchQuery = '';

  List<Doctor> get doctors => _doctors;
  List<Doctor> get filteredDoctors => _filteredDoctors;
  Doctor? get selectedDoctor => _selectedDoctor;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String get searchQuery => _searchQuery;
}