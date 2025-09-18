import 'package:flutter/material.dart';
import 'package:hospital_management_system/providers/auth_provider.dart';
import 'package:hospital_management_system/providers/doctor_provider.dart';
import 'package:provider/provider.dart';

class DoctorProfileScreen extends StatefulWidget {
  const DoctorProfileScreen({super.key});

  @override
  State<DoctorProfileScreen> createState() => _DoctorProfileScreenState();
}

class _DoctorProfileScreenState extends State<DoctorProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _biographyController = TextEditingController();
  final _consultationFeeController = TextEditingController();

  bool _isEditing = false;
  List<String> _selectedDays = [];
  String _startTime = '09:00';
  String _endTime = '17:00';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final doctorProvider = Provider.of<DoctorProvider>(context, listen: false);
      if (authProvider.currentUserId != null) {
        doctorProvider.getDoctor(authProvider.currentUserId!);
      }
    });
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    _biographyController.dispose();
    _consultationFeeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<AuthProvider, DoctorProvider>(
      builder: (context, authProvider, doctorProvider, child) {
        final doctor = doctorProvider.selectedDoctor;
        if (doctorProvider.isLoading) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        return Scaffold(
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('My Profile', style: Theme.of(context).textTheme.headlineSmall),
                // Additional UI components will go here
              ],
            ),
          ),
        );
      },
    );
  }
}