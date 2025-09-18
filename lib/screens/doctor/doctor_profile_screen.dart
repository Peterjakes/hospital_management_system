import 'package:flutter/material.dart';
import 'package:hospital_management_system/const/app_theme.dart';
import 'package:provider/provider.dart';
import 'package:hospital_management_system/providers/auth_provider.dart';
import 'package:hospital_management_system/providers/doctor_provider.dart';
import 'package:hospital_management_system/widgets/custom_text_field.dart';
import 'package:hospital_management_system/widgets/custom_button.dart';
import 'package:hospital_management_system/services/image_service.dart';

/// Doctor profile screen with edit functionality
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

  void _populateFields(doctor) {
    if (doctor != null) {
      _firstNameController.text = doctor.firstName;
      _lastNameController.text = doctor.lastName;
      _phoneController.text = doctor.phoneNumber;
      _biographyController.text = doctor.biography ?? '';
      _consultationFeeController.text = doctor.consultationFee.toString();
      _selectedDays = List<String>.from(doctor.availableDays);
      _startTime = doctor.startTime;
      _endTime = doctor.endTime;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<AuthProvider, DoctorProvider>(
      builder: (context, authProvider, doctorProvider, child) {
        final doctor = doctorProvider.selectedDoctor;
        
        if (doctor != null && !_isEditing) {
          _populateFields(doctor);
        }

        if (doctorProvider.isLoading) {
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
                        'Manage your professional information',
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
              _buildProfilePictureSection(doctor),
              const SizedBox(height: 24),

              // Professional Information
              if (doctor != null) ...[
                _buildProfessionalInfoCard(doctor),
                const SizedBox(height: 16),
              ],

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
                      controller: _biographyController,
                      labelText: 'Biography',
                      prefixIcon: Icons.description,
                      maxLines: 3,
                      enabled: _isEditing,
                      hintText: 'Tell patients about your experience and expertise...',
                    ),
                    const SizedBox(height: 16),

                    CustomTextField(
                      controller: _consultationFeeController,
                      labelText: 'Consultation Fee (KSh)',
                      prefixIcon: Icons.attach_money,
                      keyboardType: TextInputType.number,
                      enabled: _isEditing,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Consultation fee is required';
                        }
                        final fee = double.tryParse(value);
                        if (fee == null || fee <= 0) {
                          return 'Please enter a valid fee amount';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),

                    // Schedule Settings
                    if (_isEditing) ...[
                      _buildSectionHeader('Schedule Settings'),
                      const SizedBox(height: 16),
                      
                      // Available Days
                      Text(
                        'Available Days:',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        children: AppConstants.daysOfWeek.map((day) {
                          final isSelected = _selectedDays.contains(day);
                          return FilterChip(
                            label: Text(day),
                            selected: isSelected,
                            onSelected: (selected) {
                              setState(() {
                                if (selected) {
                                  _selectedDays.add(day);
                                } else {
                                  _selectedDays.remove(day);
                                }
                              });
                            },
                            selectedColor: AppTheme.doctorColor,
                            checkmarkColor: Colors.white,
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 16),

                      // Working Hours
                      Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              value: _startTime,
                              decoration: const InputDecoration(
                                labelText: 'Start Time',
                                prefixIcon: Icon(Icons.access_time),
                              ),
                              items: AppConstants.timeSlots.map((time) {
                                return DropdownMenuItem(
                                  value: time,
                                  child: Text(time),
                                );
                              }).toList(),
                              onChanged: (value) {
                                setState(() {
                                  _startTime = value!;
                                });
                              },
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              value: _endTime,
                              decoration: const InputDecoration(
                                labelText: 'End Time',
                                prefixIcon: Icon(Icons.access_time),
                              ),
                              items: AppConstants.timeSlots.map((time) {
                                return DropdownMenuItem(
                                  value: time,
                                  child: Text(time),
                                );
                              }).toList(),
                              onChanged: (value) {
                                setState(() {
                                  _endTime = value!;
                                });
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 32),
                    ],

                    // Save Button
                    if (_isEditing)
                      CustomButton(
                        text: 'Save Changes',
                        onPressed: () => _saveProfile(doctorProvider, authProvider),
                        isLoading: doctorProvider.isLoading,
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

  Widget _buildProfilePictureSection(doctor) {
    return Center(
      child: Column(
        children: [
          Stack(
            children: [
              CircleAvatar(
                radius: 50,
                backgroundColor: AppTheme.doctorColor,
                backgroundImage: doctor?.profileImageUrl != null 
                    ? NetworkImage(
                        ImageService().getOptimizedImageUrl(
                          doctor!.profileImageUrl!,
                          width: 200,
                          height: 200,
                        ),
                      )
                    : null,
                child: doctor?.profileImageUrl == null
                    ? Text(
                        doctor != null 
                            ? '${doctor.firstName[0]}${doctor.lastName[0]}'
                            : 'D',
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
                      color: AppTheme.doctorColor,
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
                Text(
                  'Professional Information',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildInfoRow('Specialization', doctor.specialization),
            _buildInfoRow('Qualification', doctor.qualification),
            _buildInfoRow('License Number', doctor.licenseNumber),
            _buildInfoRow('Experience', '${doctor.experienceYears} years'),
            _buildInfoRow('Rating', '${doctor.formattedRating} (${doctor.totalRatings} reviews)'),
            _buildInfoRow('Consultation Fee', doctor.formattedFee),
          ],
        ),
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
            color: AppTheme.doctorColor,
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

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: AppTheme.textSecondary,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _changeProfilePicture() async {
    try {
      final String? imageUrl = await ImageService().uploadProfileImage(
        context,
        folder: 'doctors',
      );
      
      if (imageUrl != null) {
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        final doctorProvider = Provider.of<DoctorProvider>(context, listen: false);
        
        await doctorProvider.updateDoctorProfile(
          doctorId: authProvider.currentUserId!,
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

  Future<void> _saveProfile(DoctorProvider doctorProvider, AuthProvider authProvider) async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedDays.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select at least one available day'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
      return;
    }

    // Update profile
    final profileSuccess = await doctorProvider.updateDoctorProfile(
      doctorId: authProvider.currentUserId!,
      firstName: _firstNameController.text.trim(),
      lastName: _lastNameController.text.trim(),
      phoneNumber: _phoneController.text.trim(),
      biography: _biographyController.text.trim(),
      consultationFee: double.parse(_consultationFeeController.text),
    );

    // Update schedule
    final scheduleSuccess = await doctorProvider.updateDoctorSchedule(
      doctorId: authProvider.currentUserId!,
      availableDays: _selectedDays,
      startTime: _startTime,
      endTime: _endTime,
      consultationDuration: 30,
    );

    if (!mounted) return;

    if (profileSuccess && scheduleSuccess) {
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
          content: Text(doctorProvider.errorMessage ?? 'Failed to update profile'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    }
  }
}