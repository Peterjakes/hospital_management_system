import 'package:flutter/material.dart';
import 'package:hospital_management_system/const/app_theme.dart';
import 'package:provider/provider.dart';
import 'package:hospital_management_system/providers/auth_provider.dart';
import 'package:hospital_management_system/providers/patient_provider.dart';
import 'package:hospital_management_system/widgets/custom_text_field.dart';
import 'package:hospital_management_system/widgets/custom_button.dart';

/// Patient profile screen with edit functionality
class PatientProfileScreen extends StatefulWidget {
  const PatientProfileScreen({super.key});

  @override
  State<PatientProfileScreen> createState() => _PatientProfileScreenState();
}

class _PatientProfileScreenState extends State<PatientProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _emergencyNameController = TextEditingController();
  final _emergencyPhoneController = TextEditingController();

  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final patientProvider = Provider.of<PatientProvider>(context, listen: false);

      if (authProvider.currentUserId != null) {
        patientProvider.getPatient(authProvider.currentUserId!);
      }
    });
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _emergencyNameController.dispose();
    _emergencyPhoneController.dispose();
    super.dispose();
  }

  void _populateFields(patient) {
    if (patient != null) {
      _firstNameController.text = patient.firstName;
      _lastNameController.text = patient.lastName;
      _phoneController.text = patient.phoneNumber;
      _addressController.text = patient.address;
      _emergencyNameController.text = patient.emergencyContactName;
      _emergencyPhoneController.text = patient.emergencyContactPhone;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<AuthProvider, PatientProvider>(
      builder: (context, authProvider, patientProvider, child) {
        final patient = patientProvider.selectedPatient;

        if (patient != null && !_isEditing) {
          _populateFields(patient);
        }

        if (patientProvider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('My Profile',
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                              )),
                      Text('Manage your personal information',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: AppTheme.textSecondary,
                              )),
                    ],
                  ),
                  IconButton(
                    onPressed: () => setState(() => _isEditing = !_isEditing),
                    icon: Icon(_isEditing ? Icons.close : Icons.edit),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              // Profile form fields will be here
            ],
          ),
        );
      },
    );
  }
}
