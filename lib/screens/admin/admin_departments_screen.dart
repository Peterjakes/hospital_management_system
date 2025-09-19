import 'package:flutter/material.dart';
import 'package:hospital_management_system/const/app_theme.dart';

/// Admin departments management screen
class AdminDepartmentsScreen extends StatefulWidget {
  const AdminDepartmentsScreen({super.key});

  @override
  State<AdminDepartmentsScreen> createState() => _AdminDepartmentsScreenState();
}

class _AdminDepartmentsScreenState extends State<AdminDepartmentsScreen> {
  final List<Map<String, dynamic>> _departments = [
    {
      'name': 'Cardiology',
      'head': 'Dr. Sarah Johnson',
      'doctors': 5,
      'location': 'Floor 2, Wing A',
      'phone': '+1 (555) 123-4567',
      'services': ['Heart Surgery', 'ECG', 'Cardiac Catheterization'],
      'isActive': true,
    },
    {
      'name': 'Neurology',
      'head': 'Dr. Michael Chen',
      'doctors': 3,
      'location': 'Floor 3, Wing B',
      'phone': '+1 (555) 234-5678',
      'services': ['Brain Surgery', 'EEG', 'Neurological Consultation'],
      'isActive': true,
    },
    {
      'name': 'Pediatrics',
      'head': 'Dr. Emily Davis',
      'doctors': 4,
      'location': 'Floor 1, Wing C',
      'phone': '+1 (555) 345-6789',
      'services': ['Child Care', 'Vaccination', 'Growth Monitoring'],
      'isActive': true,
    },
    {
      'name': 'Orthopedics',
      'head': 'Dr. Robert Wilson',
      'doctors': 6,
      'location': 'Floor 2, Wing C',
      'phone': '+1 (555) 456-7890',
      'services': ['Bone Surgery', 'Joint Replacement', 'Sports Medicine'],
      'isActive': true,
    },
    {
      'name': 'Emergency Medicine',
      'head': 'Dr. Lisa Anderson',
      'doctors': 8,
      'location': 'Ground Floor',
      'phone': '+1 (555) 567-8901',
      'services': ['Emergency Care', 'Trauma Treatment', '24/7 Service'],
      'isActive': true,
    },
  ];

  @override
  Widget build(BuildContext context) {
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

          // Department Statistics
          _buildDepartmentStats(),
          const SizedBox(height: 24),

          // Departments Grid
          _buildDepartmentsGrid(),
        ],
      ),
    );
  }

  Widget _buildDepartmentStats() {
    final totalDepartments = _departments.length;
    final activeDepartments = _departments.where((d) => d['isActive']).length;
    final totalDoctors = _departments.fold<int>(0, (sum, d) => sum + (d['doctors'] as int));

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
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            'Total Doctors',
            totalDoctors.toString(),
            Icons.medical_services,
            AppTheme.doctorColor,
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
        return _buildDepartmentCard(_departments[index], index);
      },
    );
  }

  Widget _buildDepartmentCard(Map<String, dynamic> department, int index) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with status
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    department['name'],
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
                      value: department['isActive'] ? 'deactivate' : 'activate',
                      child: Row(
                        children: [
                          Icon(
                            department['isActive'] ? Icons.block : Icons.check_circle,
                            size: 16,
                            color: department['isActive'] ? Colors.red : Colors.green,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            department['isActive'] ? 'Deactivate' : 'Activate',
                            style: TextStyle(
                              color: department['isActive'] ? Colors.red : Colors.green,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  onSelected: (value) {
                    _handleDepartmentAction(department, value.toString(), index);
                  },
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Status indicator
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: department['isActive'] ? AppTheme.successColor : AppTheme.errorColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                department['isActive'] ? 'Active' : 'Inactive',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Department info
            _buildInfoRow(Icons.person, 'Head: ${department['head']}'),
            _buildInfoRow(Icons.people, '${department['doctors']} Doctors'),
            _buildInfoRow(Icons.location_on, department['location']),
            _buildInfoRow(Icons.phone, department['phone']),
            
            const SizedBox(height: 8),
            
            // Services
            Text(
              'Services:',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Wrap(
              spacing: 4,
              runSpacing: 4,
              children: (department['services'] as List<String>).map((service) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    service,
                    style: TextStyle(
                      fontSize: 10,
                      color: AppTheme.primaryColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                );
              }).toList(),
            ),
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

  void _handleDepartmentAction(Map<String, dynamic> department, String action, int index) {
    switch (action) {
      case 'edit':
        _showEditDepartmentDialog(department, index);
        break;
      case 'doctors':
        _showDepartmentDoctors(department);
        break;
      case 'activate':
      case 'deactivate':
        _toggleDepartmentStatus(department, index);
        break;
    }
  }

  void _showAddDepartmentDialog() {
    final nameController = TextEditingController();
    final headController = TextEditingController();
    final locationController = TextEditingController();
    final phoneController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
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
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (nameController.text.isNotEmpty) {
                setState(() {
                  _departments.add({
                    'name': nameController.text,
                    'head': headController.text,
                    'doctors': 0,
                    'location': locationController.text,
                    'phone': phoneController.text,
                    'services': <String>[],
                    'isActive': true,
                  });
                });
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Department added successfully!'),
                    backgroundColor: AppTheme.successColor,
                  ),
                );
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _showEditDepartmentDialog(Map<String, dynamic> department, int index) {
    final nameController = TextEditingController(text: department['name']);
    final headController = TextEditingController(text: department['head']);
    final locationController = TextEditingController(text: department['location']);
    final phoneController = TextEditingController(text: department['phone']);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
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
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _departments[index] = {
                  ..._departments[index],
                  'name': nameController.text,
                  'head': headController.text,
                  'location': locationController.text,
                  'phone': phoneController.text,
                };
              });
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Department updated successfully!'),
                  backgroundColor: AppTheme.successColor,
                ),
              );
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showDepartmentDoctors(Map<String, dynamic> department) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${department['name']} - Doctors'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Total Doctors: ${department['doctors']}'),
            const SizedBox(height: 16),
            const Text('Doctor management feature coming soon!'),
          ],
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

  void _toggleDepartmentStatus(Map<String, dynamic> department, int index) {
    setState(() {
      _departments[index]['isActive'] = !_departments[index]['isActive'];
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Department ${_departments[index]['isActive'] ? 'activated' : 'deactivated'} successfully!',
        ),
        backgroundColor: AppTheme.successColor,
      ),
    );
  }
}