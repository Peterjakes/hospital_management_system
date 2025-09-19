import 'package:flutter/material.dart';
import 'package:hospital_management_system/const/app_theme.dart';
import 'package:provider/provider.dart';
import 'package:hospital_management_system/providers/auth_provider.dart';
import 'package:hospital_management_system/providers/patient_provider.dart';
import 'package:hospital_management_system/widgets/custom_text_field.dart';
import 'package:hospital_management_system/widgets/custom_button.dart';
import 'package:hospital_management_system/services/image_service.dart';

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
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'My Profile',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Manage your personal information',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    onPressed: () {
                      setState(() {
                        _isEditing = !_isEditing;
                      });
                    },
                    icon: Icon(_isEditing ? Icons.close : Icons.edit),
                    tooltip: _isEditing ? 'Cancel' : 'Edit Profile',
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Profile Picture Section
              _buildProfilePictureSection(patient),
              const SizedBox(height: 24),

              // Profile Form
              Form(
                key: _formKey,
                child: Column(
                  children: [
                    // Personal Information
                    _buildSectionHeader('Personal Information'),
                    const SizedBox(height: 16),
                    
                    Row(
                      children: [
                        Expanded(
                          child: CustomTextField(
                            controller: _firstNameController,
                            labelText: 'First Name',
                            prefixIcon: Icons.person,
                            enabled: _isEditing,
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'First name is required';
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: CustomTextField(
                            controller: _lastNameController,
                            labelText: 'Last Name',
                            prefixIcon: Icons.person,
                            enabled: _isEditing,
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Last name is required';
                              }
                              return null;
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    CustomTextField(
                      controller: _phoneController,
                      labelText: 'Phone Number',
                      prefixIcon: Icons.phone,
                      keyboardType: TextInputType.phone,
                      enabled: _isEditing,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Phone number is required';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    CustomTextField(
                      controller: _addressController,
                      labelText: 'Address',
                      prefixIcon: Icons.location_on,
                      maxLines: 2,
                      enabled: _isEditing,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Address is required';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),

                    // Emergency Contact
                    _buildSectionHeader('Emergency Contact'),
                    const SizedBox(height: 16),

                    CustomTextField(
                      controller: _emergencyNameController,
                      labelText: 'Emergency Contact Name',
                      prefixIcon: Icons.contact_emergency,
                      enabled: _isEditing,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Emergency contact name is required';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    CustomTextField(
                      controller: _emergencyPhoneController,
                      labelText: 'Emergency Contact Phone',
                      prefixIcon: Icons.phone,
                      keyboardType: TextInputType.phone,
                      enabled: _isEditing,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Emergency contact phone is required';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 32),

                    // Save Button
                    if (_isEditing)
                      CustomButton(
                        text: 'Save Changes',
                        onPressed: () => _saveProfile(patientProvider, authProvider),
                        isLoading: patientProvider.isLoading,
                        width: double.infinity,
                        icon: Icons.save,
                      ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildProfilePictureSection(patient) {
    return Center(
      child: Column(
        children: [
          Stack(
            children: [
              CircleAvatar(
                radius: 50,
                backgroundColor: AppTheme.patientColor,
                backgroundImage: patient?.profileImageUrl != null 
                    ? NetworkImage(
                        ImageService().getOptimizedImageUrl(
                          patient!.profileImageUrl!,
                          width: 200,
                          height: 200,
                        ),
                      )
                    : null,
                child: patient?.profileImageUrl == null
                    ? Text(
                        patient != null 
                            ? '${patient.firstName[0]}${patient.lastName[0]}'
                            : 'P',
                        style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      )
                    : null,
              ),
              if (_isEditing)
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: IconButton(
                      onPressed: _changeProfilePicture,
                      icon: const Icon(Icons.camera_alt, color: Colors.white, size: 20),
                      constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          if (_isEditing)
            TextButton.icon(
              onPressed: _changeProfilePicture,
              icon: const Icon(Icons.camera_alt),
              label: const Text('Change Photo'),
            ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 20,
          decoration: BoxDecoration(
            color: AppTheme.patientColor,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Future<void> _changeProfilePicture() async {
    try {
      final String? imageUrl = await ImageService().uploadProfileImage(
        context,
        folder: 'patients',
      );
      
      if (imageUrl != null) {
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        final patientProvider = Provider.of<PatientProvider>(context, listen: false);
        
        await patientProvider.updatePatientProfile(
          patientId: authProvider.currentUserId!,
          profileImageUrl: imageUrl,
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to upload image: ${e.toString()}'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    }
  }

  void _changeProfilePictureOld() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Photo upload feature coming soon!'),
        backgroundColor: AppTheme.warningColor,
      ),
    );
  }

  Future<void> _saveProfile(PatientProvider patientProvider, AuthProvider authProvider) async {
    if (!_formKey.currentState!.validate()) return;

    final success = await patientProvider.updatePatientProfile(
      patientId: authProvider.currentUserId!,
      firstName: _firstNameController.text.trim(),
      lastName: _lastNameController.text.trim(),
      phoneNumber: _phoneController.text.trim(),
      address: _addressController.text.trim(),
      emergencyContactName: _emergencyNameController.text.trim(),
      emergencyContactPhone: _emergencyPhoneController.text.trim(),
    );

    if (!mounted) return;

    if (success) {
    
      setState(() {
        _isEditing = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Profile updated successfully!'),
          backgroundColor: AppTheme.successColor,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(patientProvider.errorMessage ?? 'Failed to update profile'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    }
  }
}