import 'package:flutter/material.dart';
import 'package:hospital_management_system/const/app_theme.dart';
import 'package:provider/provider.dart';
import 'package:hospital_management_system/providers/patient_provider.dart';
import 'package:hospital_management_system/providers/doctor_provider.dart';
import 'package:hospital_management_system/models/user_model.dart';

/// Admin users management screen
class AdminUsersScreen extends StatefulWidget {
  const AdminUsersScreen({super.key});

  @override
  State<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends State<AdminUsersScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<PatientProvider>(context, listen: false).loadPatients();
      Provider.of<DoctorProvider>(context, listen: false).loadDoctors();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Header with search
        _buildHeader(),
        
        // Tab Bar
        TabBar(
          controller: _tabController,
          labelColor: AppTheme.adminColor,
          indicatorColor: AppTheme.adminColor,
          tabs: const [
            Tab(text: 'Patients', icon: Icon(Icons.people)),
            Tab(text: 'Doctors', icon: Icon(Icons.medical_services)),
          ],
        ),
        
        // Tab Views
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildPatientsTab(),
              _buildDoctorsTab(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'User Management',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Manage patients and doctors in the system',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search users...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      onPressed: () {
                        _searchController.clear();
                        _clearSearch();
                      },
                      icon: const Icon(Icons.clear),
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onChanged: _performSearch,
          ),
        ],
      ),
    );
  }

  Widget _buildPatientsTab() {
    return Consumer<PatientProvider>(
      builder: (context, patientProvider, child) {
        if (patientProvider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        final patients = patientProvider.filteredPatients;

        if (patients.isEmpty) {
          return _buildEmptyState('No patients found');
        }

        return RefreshIndicator(
          onRefresh: () => patientProvider.refreshPatients(),
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: patients.length,
            itemBuilder: (context, index) {
              return _buildPatientCard(patients[index], patientProvider);
            },
          ),
        );
      },
    );
  }

  Widget _buildDoctorsTab() {
    return Consumer<DoctorProvider>(
      builder: (context, doctorProvider, child) {
        if (doctorProvider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        final doctors = doctorProvider.filteredDoctors;

        if (doctors.isEmpty) {
          return _buildEmptyState('No doctors found');
        }

        return RefreshIndicator(
          onRefresh: () => doctorProvider.refreshDoctors(),
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: doctors.length,
            itemBuilder: (context, index) {
              return _buildDoctorCard(doctors[index], doctorProvider);
            },
          ),
        );
      },
    );
  }

  Widget _buildEmptyState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.people_outline,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPatientCard(patient, PatientProvider patientProvider) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: AppTheme.patientColor,
          child: Text(
            '${patient.firstName[0]}${patient.lastName[0]}',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(
          patient.fullName,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Age: ${patient.age} • ${patient.gender}'),
            Text('Email: ${patient.email}'),
            Text('Phone: ${patient.phoneNumber}'),
            if (patient.hasAllergies)
              Text(
                'Allergies: ${patient.allergies.join(', ')}',
                style: TextStyle(
                  color: AppTheme.errorColor,
                  fontSize: 12,
                ),
              ),
          ],
        ),
        trailing: PopupMenuButton(
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'view',
              child: Row(
                children: [
                  Icon(Icons.visibility, size: 16),
                  SizedBox(width: 8),
                  Text('View Details'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'edit',
              child: Row(
                children: [
                  Icon(Icons.edit, size: 16),
                  SizedBox(width: 8),
                  Text('Edit Patient'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'change_role',
              child: Row(
                children: [
                  Icon(Icons.person_pin, size: 16, color: Colors.blue),
                  SizedBox(width: 8),
                  Text('Change Role', style: TextStyle(color: Colors.blue)),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'deactivate',
              child: Row(
                children: [
                  Icon(Icons.block, size: 16, color: Colors.red),
                  SizedBox(width: 8),
                  Text('Deactivate', style: TextStyle(color: Colors.red)),
                ],
              ),
            ),
          ],
          onSelected: (value) {
            _handlePatientAction(patient, value.toString(), patientProvider);
          },
        ),
      ),
    );
  }

  Widget _buildDoctorCard(doctor, DoctorProvider doctorProvider) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: AppTheme.doctorColor,
          child: Text(
            '${doctor.firstName[0]}${doctor.lastName[0]}',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(
          'Dr. ${doctor.fullName}',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Specialization: ${doctor.specialization}'),
            Text('Experience: ${doctor.experienceYears} years'),
            Text('Email: ${doctor.email}'),
            Text('Phone: ${doctor.phoneNumber}'),
            Row(
              children: [
                Icon(Icons.star, size: 16, color: Colors.amber),
                Text(' ${doctor.formattedRating} (${doctor.totalRatings} reviews)'),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: doctor.isAvailable ? AppTheme.successColor : AppTheme.errorColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    doctor.isAvailable ? 'Available' : 'Unavailable',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
        trailing: PopupMenuButton(
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'view',
              child: Row(
                children: [
                  Icon(Icons.visibility, size: 16),
                  SizedBox(width: 8),
                  Text('View Details'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'edit',
              child: Row(
                children: [
                  Icon(Icons.edit, size: 16),
                  SizedBox(width: 8),
                  Text('Edit Doctor'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'change_role',
              child: Row(
                children: [
                  Icon(Icons.person_pin, size: 16, color: Colors.blue),
                  SizedBox(width: 8),
                  Text('Change Role', style: TextStyle(color: Colors.blue)),
                ],
              ),
            ),
            PopupMenuItem(
              value: doctor.isAvailable ? 'deactivate' : 'activate',
              child: Row(
                children: [
                  Icon(
                    doctor.isAvailable ? Icons.block : Icons.check_circle,
                    size: 16,
                    color: doctor.isAvailable ? Colors.red : Colors.green,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    doctor.isAvailable ? 'Deactivate' : 'Activate',
                    style: TextStyle(
                      color: doctor.isAvailable ? Colors.red : Colors.green,
                    ),
                  ),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  Icon(Icons.delete, size: 16, color: Colors.red),
                  SizedBox(width: 8),
                  Text('Delete', style: TextStyle(color: Colors.red)),
                ],
              ),
            ),
          ],
          onSelected: (value) {
            _handleDoctorAction(doctor, value.toString(), doctorProvider);
          },
        ),
      ),
    );
  }

  void _handlePatientAction(patient, String action, PatientProvider patientProvider) {
    switch (action) {
      case 'view':
        _showPatientDetails(patient);
        break;
      case 'edit':
        _showEditPatientDialog(patient, patientProvider);
        break;
      case 'change_role':
        _showChangeRoleDialog(patient.id, patient.fullName, 'patient');
        break;
      case 'deactivate':
        _showDeactivateDialog('patient', patient.fullName, () async {
          final success = await patientProvider.deactivatePatient(patient.id);
          if (success && mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Patient deactivated successfully'),
                backgroundColor: AppTheme.successColor,
              ),
            );
          } else if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Failed to deactivate patient'),
                backgroundColor: AppTheme.errorColor,
              ),
            );
          }
        });
        break;
    }
  }

  void _handleDoctorAction(doctor, String action, DoctorProvider doctorProvider) {
    switch (action) {
      case 'view':
        _showDoctorDetails(doctor);
        break;
      case 'edit':
        _showEditDoctorDialog(doctor, doctorProvider);
        break;
      case 'change_role':
        _showChangeRoleDialog(doctor.id, doctor.fullName, 'doctor');
        break;
      case 'activate':
      case 'deactivate':
        _toggleDoctorAvailability(doctor, doctorProvider);
        break;
      case 'delete':
        _showDeleteDialog('doctor', doctor.fullName, () async {
          final success = await doctorProvider.deleteDoctor(doctor.id);
          if (success && mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Doctor deleted successfully'),
                backgroundColor: AppTheme.successColor,
              ),
            );
          }
        });
        break;
    }
  }

  void _showPatientDetails(patient) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Patient Details - ${patient.fullName}'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow('Age', '${patient.age} years'),
              _buildDetailRow('Gender', patient.gender),
              _buildDetailRow('Blood Group', patient.bloodGroup),
              _buildDetailRow('Phone', patient.phoneNumber),
              _buildDetailRow('Email', patient.email),
              _buildDetailRow('Address', patient.address),
              _buildDetailRow('Emergency Contact', patient.emergencyContactName),
              _buildDetailRow('Emergency Phone', patient.emergencyContactPhone),
              if (patient.hasInsurance) ...[
                _buildDetailRow('Insurance Provider', patient.insuranceProvider ?? 'N/A'),
                _buildDetailRow('Insurance Number', patient.insuranceNumber ?? 'N/A'),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showDoctorDetails(doctor) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Doctor Details - Dr. ${doctor.fullName}'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow('Specialization', doctor.specialization),
              _buildDetailRow('Qualification', doctor.qualification),
              _buildDetailRow('License Number', doctor.licenseNumber),
              _buildDetailRow('Experience', '${doctor.experienceYears} years'),
              _buildDetailRow('Phone', doctor.phoneNumber),
              _buildDetailRow('Email', doctor.email),
              _buildDetailRow('Consultation Fee', doctor.formattedFee),
              _buildDetailRow('Rating', '${doctor.formattedRating} (${doctor.totalRatings} reviews)'),
              _buildDetailRow('Available Days', doctor.availableDays.join(', ')),
              _buildDetailRow('Working Hours', '${doctor.startTime} - ${doctor.endTime}'),
              if (doctor.biography != null && doctor.biography!.isNotEmpty)
                _buildDetailRow('Biography', doctor.biography!),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showEditPatientDialog(patient, PatientProvider patientProvider) {
    final firstNameController = TextEditingController(text: patient.firstName);
    final lastNameController = TextEditingController(text: patient.lastName);
    final phoneController = TextEditingController(text: patient.phoneNumber);
    final addressController = TextEditingController(text: patient.address);
    final emergencyContactController = TextEditingController(text: patient.emergencyContactName);
    final emergencyPhoneController = TextEditingController(text: patient.emergencyContactPhone);
    final insuranceNumberController = TextEditingController(text: patient.insuranceNumber ?? '');
    final insuranceProviderController = TextEditingController(text: patient.insuranceProvider ?? '');
    
    String selectedBloodGroup = patient.bloodGroup;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Edit Patient - ${patient.fullName}'),
        content: SizedBox(
          width: MediaQuery.of(context).size.width * 0.8,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Basic Information
                TextField(
                  controller: firstNameController,
                  decoration: const InputDecoration(
                    labelText: 'First Name',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: lastNameController,
                  decoration: const InputDecoration(
                    labelText: 'Last Name',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: phoneController,
                  decoration: const InputDecoration(
                    labelText: 'Phone Number',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: addressController,
                  decoration: const InputDecoration(
                    labelText: 'Address',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 16),
                
                // Blood Group Dropdown
                DropdownButtonFormField<String>(
                  value: selectedBloodGroup,
                  decoration: const InputDecoration(
                    labelText: 'Blood Group',
                    border: OutlineInputBorder(),
                  ),
                  items: ['A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-']
                      .map((group) => DropdownMenuItem(
                            value: group, 
                            child: Text(group)
                          ))
                      .toList(),
                  onChanged: (value) => selectedBloodGroup = value!,
                ),
                const SizedBox(height: 16),
                
                // Emergency Contact
                TextField(
                  controller: emergencyContactController,
                  decoration: const InputDecoration(
                    labelText: 'Emergency Contact Name',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: emergencyPhoneController,
                  decoration: const InputDecoration(
                    labelText: 'Emergency Contact Phone',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 16),
                
                // Insurance Information
                TextField(
                  controller: insuranceProviderController,
                  decoration: const InputDecoration(
                    labelText: 'Insurance Provider',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: insuranceNumberController,
                  decoration: const InputDecoration(
                    labelText: 'Insurance Number',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              // Dispose controllers
              firstNameController.dispose();
              lastNameController.dispose();
              phoneController.dispose();
              addressController.dispose();
              emergencyContactController.dispose();
              emergencyPhoneController.dispose();
              insuranceNumberController.dispose();
              insuranceProviderController.dispose();
              Navigator.of(context).pop();
            },
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final success = await patientProvider.updatePatientProfile(
                patientId: patient.id,
                firstName: firstNameController.text.trim(),
                lastName: lastNameController.text.trim(),
                phoneNumber: phoneController.text.trim(),
                address: addressController.text.trim(),
                emergencyContactName: emergencyContactController.text.trim(),
                emergencyContactPhone: emergencyPhoneController.text.trim(),
              );
              
              if (success) {
                await patientProvider.updatePatientMedicalInfo(
                  patientId: patient.id,
                  bloodGroup: selectedBloodGroup,
                  insuranceNumber: insuranceNumberController.text.trim().isEmpty ? null : insuranceNumberController.text.trim(),
                  insuranceProvider: insuranceProviderController.text.trim().isEmpty ? null : insuranceProviderController.text.trim(),
                );
              }
              
              // Dispose controllers
              firstNameController.dispose();
              lastNameController.dispose();
              phoneController.dispose();
              addressController.dispose();
              emergencyContactController.dispose();
              emergencyPhoneController.dispose();
              insuranceNumberController.dispose();
              insuranceProviderController.dispose();
              
              if (mounted) {
                Navigator.of(context).pop();
                if (success) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Patient updated successfully'),
                      backgroundColor: AppTheme.successColor,
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Failed to update patient'),
                      backgroundColor: AppTheme.errorColor,
                    ),
                  );
                }
              }
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }

  void _showEditDoctorDialog(doctor, DoctorProvider doctorProvider) {
    final firstNameController = TextEditingController(text: doctor.firstName);
    final lastNameController = TextEditingController(text: doctor.lastName);
    final phoneController = TextEditingController(text: doctor.phoneNumber);
    final biographyController = TextEditingController(text: doctor.biography);
    final feeController = TextEditingController(text: doctor.consultationFee.toString());
    final experienceController = TextEditingController(text: doctor.experienceYears.toString());
    final startTimeController = TextEditingController(text: doctor.startTime);
    final endTimeController = TextEditingController(text: doctor.endTime);
    
    List<String> selectedDays = List.from(doctor.availableDays);
    List<String> allDays = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Edit Doctor - Dr. ${doctor.fullName}'),
        content: SingleChildScrollView(
          child: StatefulBuilder(
            builder: (context, setState) => Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Basic Information
                TextField(
                  controller: firstNameController,
                  decoration: const InputDecoration(labelText: 'First Name'),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: lastNameController,
                  decoration: const InputDecoration(labelText: 'Last Name'),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: phoneController,
                  decoration: const InputDecoration(labelText: 'Phone Number'),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: biographyController,
                  decoration: const InputDecoration(labelText: 'Biography'),
                  maxLines: 3,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: feeController,
                  decoration: const InputDecoration(labelText: 'Consultation Fee (KSh)'),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: experienceController,
                  decoration: const InputDecoration(labelText: 'Experience (Years)'),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 16),
                
                // Working Hours
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: startTimeController,
                        decoration: const InputDecoration(labelText: 'Start Time'),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextField(
                        controller: endTimeController,
                        decoration: const InputDecoration(labelText: 'End Time'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                
                // Available Days
                const Text('Available Days:', style: TextStyle(fontWeight: FontWeight.bold)),
                ...allDays.map((day) => CheckboxListTile(
                  title: Text(day),
                  value: selectedDays.contains(day),
                  onChanged: (checked) {
                    setState(() {
                      if (checked == true) {
                        selectedDays.add(day);
                      } else {
                        selectedDays.remove(day);
                      }
                    });
                  },
                )).toList(),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final profileSuccess = await doctorProvider.updateDoctorProfile(
                doctorId: doctor.id,
                firstName: firstNameController.text.trim(),
                lastName: lastNameController.text.trim(),
                phoneNumber: phoneController.text.trim(),
                biography: biographyController.text.trim(),
                consultationFee: double.tryParse(feeController.text) ?? doctor.consultationFee,
              );
              
              final scheduleSuccess = await doctorProvider.updateDoctorSchedule(
                doctorId: doctor.id,
                availableDays: selectedDays,
                startTime: startTimeController.text.trim(),
                endTime: endTimeController.text.trim(),
                consultationDuration: doctor.consultationDuration,
              );
              
              if (mounted) {
                Navigator.of(context).pop();
                if (profileSuccess && scheduleSuccess) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Doctor updated successfully'),
                      backgroundColor: AppTheme.successColor,
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Failed to update doctor'),
                      backgroundColor: AppTheme.errorColor,
                    ),
                  );
                }
              }
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }

  void _showChangeRoleDialog(String userId, String userName, String currentRole) {
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          String selectedRole = currentRole;
          
          return AlertDialog(
            title: Text('Change Role - $userName'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Current Role: ${currentRole.toUpperCase()}'),
                const SizedBox(height: 16),
                const Text('Select New Role:'),
                const SizedBox(height: 8),
                RadioListTile<String>(
                  title: const Text('Patient'),
                  value: 'patient',
                  groupValue: selectedRole,
                  onChanged: (value) => setState(() => selectedRole = value!),
                ),
                RadioListTile<String>(
                  title: const Text('Doctor'),
                  value: 'doctor',
                  groupValue: selectedRole,
                  onChanged: (value) => setState(() => selectedRole = value!),
                ),
                RadioListTile<String>(
                  title: const Text('Admin'),
                  value: 'admin',
                  groupValue: selectedRole,
                  onChanged: (value) => setState(() => selectedRole = value!),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: selectedRole == currentRole ? null : () async {
                  try {
                    final doctorProvider = Provider.of<DoctorProvider>(context, listen: false);
                    await doctorProvider.updateUserRole(userId, selectedRole);
                    
                    if (mounted) {
                      Navigator.of(context).pop();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Role changed to ${selectedRole.toUpperCase()} successfully'),
                          backgroundColor: AppTheme.successColor,
                        ),
                      );
                      
                      // Refresh both providers to reflect changes
                      Provider.of<PatientProvider>(context, listen: false).refreshPatients();
                      Provider.of<DoctorProvider>(context, listen: false).refreshDoctors();
                    }
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Failed to change role'),
                          backgroundColor: AppTheme.errorColor,
                        ),
                      );
                    }
                  }
                },
                child: const Text('Change Role'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showDeactivateDialog(String userType, String userName, VoidCallback onConfirm) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Deactivate $userType'),
        content: Text('Are you sure you want to deactivate $userName?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              onConfirm();
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.errorColor),
            child: const Text('Deactivate'),
          ),
        ],
      ),
    );
  }

  void _showDeleteDialog(String userType, String userName, VoidCallback onConfirm) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete $userType'),
        content: Text('Are you sure you want to delete $userName? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              onConfirm();
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.errorColor),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Future<void> _toggleDoctorAvailability(doctor, DoctorProvider doctorProvider) async {
    final success = await doctorProvider.updateDoctorAvailability(
      doctor.id,
      !doctor.isAvailable,
    );

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Doctor ${doctor.isAvailable ? 'deactivated' : 'activated'} successfully',
          ),
          backgroundColor: AppTheme.successColor,
        ),
      );
    }
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  void _performSearch(String query) {
    if (_tabController.index == 0) {
      // Search patients
      Provider.of<PatientProvider>(context, listen: false).searchPatients(query);
    } else {
      // Search doctors
      Provider.of<DoctorProvider>(context, listen: false).searchDoctors(query);
    }
  }

  void _clearSearch() {
    Provider.of<PatientProvider>(context, listen: false).clearFilters();
    Provider.of<DoctorProvider>(context, listen: false).clearFilters();
  }
}