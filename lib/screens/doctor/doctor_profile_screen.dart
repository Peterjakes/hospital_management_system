import 'package:flutter/material.dart';
import 'package:hospital_management_system/const/app_theme.dart';
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
                const SizedBox(height: 20),
                _buildProfilePictureSection(doctor),
                const SizedBox(height: 20),
                _buildProfessionalInfoCard(doctor),
                // Additional UI components will go here
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildProfilePictureSection(doctor) {
    return Center(
      child: Stack(
        children: [
          CircleAvatar(
            radius: 50,
            backgroundColor: AppTheme.doctorColor,
            backgroundImage: doctor?.profileImageUrl != null
                ? NetworkImage(doctor!.profileImageUrl!)
                : null,
            child: doctor?.profileImageUrl == null
                ? Text(
                    doctor != null
                        ? '${doctor.firstName[0]}${doctor.lastName[0]}'
                        : 'D',
                    style: const TextStyle(
                        fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white),
                  )
                : null,
          ),
          if (_isEditing)
            Positioned(
              bottom: 0,
              right: 0,
              child: IconButton(
                onPressed: _changeProfilePicture,
                icon: const Icon(Icons.camera_alt, color: Colors.white, size: 20),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildProfessionalInfoCard(doctor) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.medical_services, color: AppTheme.doctorColor),
                const SizedBox(width: 8),
                const Text('Professional Information',
                    style: TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 16),
            _buildInfoRow('Specialization', doctor.specialization),
            _buildInfoRow('Qualification', doctor.qualification),
            _buildInfoRow('Experience', '${doctor.experienceYears} years'),
          ],
        ),
      ),
    );
  }
}