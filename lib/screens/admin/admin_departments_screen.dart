import 'package:flutter/material.dart';
import 'package:hospital_management_system/const/app_theme.dart';
import 'package:hospital_management_system/models/department_model.dart';
import 'package:hospital_management_system/models/doctor_model.dart';
import 'package:hospital_management_system/services/firestore_service.dart';

/// Admin departments management screen
///
/// Previously this screen used a hardcoded, in-memory list of fake
/// departments (fake US phone numbers, fake doctor names not tied to any
/// real doctor in the app) — nothing here ever touched Firestore, so every
/// edit vanished on app restart and "Manage Doctors" was a dead-end dialog.
/// This version loads real departments from the `departments` collection,
/// persists edits/creates/activation-toggles back to Firestore, and shows
/// the department's actual doctors via getDoctorsByDepartment().
class AdminDepartmentsScreen extends StatefulWidget {
  const AdminDepartmentsScreen({super.key});

  @override
  State<AdminDepartmentsScreen> createState() => _AdminDepartmentsScreenState();
}

class _AdminDepartmentsScreenState extends State<AdminDepartmentsScreen> {
  final FirestoreService _firestoreService = FirestoreService();

  List<Department> _departments = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadDepartments();
  }

  Future<void> _loadDepartments() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final departments = await _firestoreService.getAllDepartments();
      setState(() {
        _departments = departments;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _loadDepartments,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
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
                    Text(
                      'Department Management',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Manage hospital departments and their information',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
                ElevatedButton.icon(
                  onPressed: _showAddDepartmentDialog,
                  icon: const Icon(Icons.add),
                  label: const Text('Add Department'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.adminColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            if (_isLoading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 48),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_errorMessage != null)
              _buildErrorState()
            else if (_departments.isEmpty)
              _buildEmptyState()
            else ...[
              _buildDepartmentStats(),
              const SizedBox(height: 24),
              _buildDepartmentsGrid(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48),
      child: Center(
        child: Column(
          children: [
            const Icon(Icons.error_outline, size: 48, color: AppTheme.errorColor),
            const SizedBox(height: 12),
            Text(
              'Unable to load departments.',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 4),
            Text(
              _errorMessage!,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppTheme.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadDepartments,
              child: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48),
      child: Center(
        child: Column(
          children: [
            Icon(Icons.business_outlined, size: 48, color: AppTheme.textSecondary),
            const SizedBox(height: 12),
            Text(
              'No departments yet',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 4),
            Text(
              'Add your first department to get started.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppTheme.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDepartmentStats() {
    final totalDepartments = _departments.length;
    final activeDepartments = _departments.where((d) => d.isActive).length;

    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            'Total Departments',
            totalDepartments.toString(),
            Icons.business,
            AppTheme.primaryColor,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            'Active Departments',
            activeDepartments.toString(),
            Icons.check_circle,
            AppTheme.successColor,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              title,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppTheme.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDepartmentsGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 0.8,
      ),
      itemCount: _departments.length,
      itemBuilder: (context, index) {
        return _buildDepartmentCard(_departments[index]);
      },
    );
  }

  Widget _buildDepartmentCard(Department department) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    department.name,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                PopupMenuButton(
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit, size: 16),
                          SizedBox(width: 8),
                          Text('Edit'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'doctors',
                      child: Row(
                        children: [
                          Icon(Icons.people, size: 16),
                          SizedBox(width: 8),
                          Text('Manage Doctors'),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: department.isActive ? 'deactivate' : 'activate',
                      child: Row(
                        children: [
                          Icon(
                            department.isActive ? Icons.block : Icons.check_circle,
                            size: 16,
                            color: department.isActive ? Colors.red : Colors.green,
                          ),
                          const SizedBox(width: 8),
                          Text(department.isActive ? 'Deactivate' : 'Activate'),
                        ],
                      ),
                    ),
                  ],
                  onSelected: (value) => _handleDepartmentAction(department, value),
                ),
              ],
            ),
            if (!department.isActive)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  'Inactive',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.errorColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            const SizedBox(height: 12),
            _buildInfoRow(Icons.location_on_outlined, department.location),
            if (department.contactNumber.isNotEmpty)
              _buildInfoRow(Icons.phone_outlined, department.contactNumber),
            if (department.headDoctorId.isNotEmpty)
              _buildInfoRow(Icons.person_outline, 'Head: ${department.headDoctorId}'),
            if (department.services.isNotEmpty) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: department.services.map((service) {
                  return Chip(
                    label: Text(
                      service,
                      style: const TextStyle(fontSize: 11),
                    ),
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    visualDensity: VisualDensity.compact,
                  );
                }).toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Icon(icon, size: 14, color: AppTheme.textSecondary),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              text,
              style: Theme.of(context).textTheme.bodySmall,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  void _handleDepartmentAction(Department department, String action) {
    switch (action) {
      case 'edit':
        _showEditDepartmentDialog(department);
        break;
      case 'doctors':
        _showDepartmentDoctors(department);
        break;
      case 'activate':
      case 'deactivate':
        _toggleDepartmentStatus(department);
        break;
    }
  }

  void _showAddDepartmentDialog() {
    final nameController = TextEditingController();
    final headController = TextEditingController();
    final locationController = TextEditingController();
    final phoneController = TextEditingController();
    bool isSaving = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Add New Department'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Department Name',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: headController,
                  decoration: const InputDecoration(
                    labelText: 'Department Head',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: locationController,
                  decoration: const InputDecoration(
                    labelText: 'Location',
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
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: isSaving ? null : () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: isSaving
                  ? null
                  : () async {
                      if (nameController.text.trim().isEmpty) return;

                      setDialogState(() => isSaving = true);

                      final now = DateTime.now();
                      final newDepartment = Department(
                        id: '',
                        name: nameController.text.trim(),
                        description: '',
                        headDoctorId: headController.text.trim(),
                        location: locationController.text.trim(),
                        contactNumber: phoneController.text.trim(),
                        email: '',
                        isActive: true,
                        createdAt: now,
                        updatedAt: now,
                      );

                      try {
                        await _firestoreService.createDepartment(newDepartment);
                        if (!context.mounted) return;
                        Navigator.of(context).pop();
                        await _loadDepartments();
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Department added successfully!'),
                            backgroundColor: AppTheme.successColor,
                          ),
                        );
                      } catch (e) {
                        setDialogState(() => isSaving = false);
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Failed to add department: ${e.toString()}'),
                            backgroundColor: AppTheme.errorColor,
                          ),
                        );
                      }
                    },
              child: isSaving
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Add'),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditDepartmentDialog(Department department) {
    final nameController = TextEditingController(text: department.name);
    final headController = TextEditingController(text: department.headDoctorId);
    final locationController = TextEditingController(text: department.location);
    final phoneController = TextEditingController(text: department.contactNumber);
    bool isSaving = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Edit Department'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Department Name',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: headController,
                  decoration: const InputDecoration(
                    labelText: 'Department Head',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: locationController,
                  decoration: const InputDecoration(
                    labelText: 'Location',
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
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: isSaving ? null : () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: isSaving
                  ? null
                  : () async {
                      setDialogState(() => isSaving = true);

                      try {
                        await _firestoreService.updateDepartment(department.id, {
                          'name': nameController.text.trim(),
                          'headDoctorId': headController.text.trim(),
                          'location': locationController.text.trim(),
                          'contactNumber': phoneController.text.trim(),
                        });
                        if (!context.mounted) return;
                        Navigator.of(context).pop();
                        await _loadDepartments();
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Department updated successfully!'),
                            backgroundColor: AppTheme.successColor,
                          ),
                        );
                      } catch (e) {
                        setDialogState(() => isSaving = false);
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Failed to update department: ${e.toString()}'),
                            backgroundColor: AppTheme.errorColor,
                          ),
                        );
                      }
                    },
              child: isSaving
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  void _showDepartmentDoctors(Department department) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${department.name} - Doctors'),
        content: SizedBox(
          width: double.maxFinite,
          child: FutureBuilder<List<Doctor>>(
            future: _firestoreService.getDoctorsByDepartment(department.id),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Center(child: CircularProgressIndicator()),
                );
              }

              if (snapshot.hasError) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: Text('Unable to load doctors: ${snapshot.error}'),
                );
              }

              final doctors = snapshot.data ?? [];

              if (doctors.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Text('No doctors are currently assigned to this department.'),
                );
              }

              return Column(
                mainAxisSize: MainAxisSize.min,
                children: doctors.map((doctor) {
                  return ListTile(
                    leading: const CircleAvatar(child: Icon(Icons.person)),
                    title: Text(doctor.fullName),
                    subtitle: Text(doctor.specialization),
                  );
                }).toList(),
              );
            },
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

  Future<void> _toggleDepartmentStatus(Department department) async {
    try {
      await _firestoreService.updateDepartment(department.id, {
        'isActive': !department.isActive,
      });
      await _loadDepartments();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Department ${!department.isActive ? 'activated' : 'deactivated'} successfully!',
          ),
          backgroundColor: AppTheme.successColor,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update department: ${e.toString()}'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    }
  }
}