import 'package:flutter/material.dart';
import 'package:hospital_management_system/const/app_theme.dart';
import 'package:hospital_management_system/const/constants.dart';

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
  ];

  @override
  Widget build(BuildContext context) {
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
                onPressed: () {},
                icon: const Icon(Icons.add),
                label: const Text('Add Department'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.adminColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildDepartmentStats(),
          const SizedBox(height: 24),
          _buildDepartmentsGrid(),
        ],
      ),
    );
  }

  Widget _buildDepartmentStats() {
    final total = _departments.length;
    final active = _departments.where((d) => d['isActive']).length;
    final doctors = _departments.fold<int>(0, (sum, d) => sum + (d['doctors'] as int));

    return Row(
      children: [
        Expanded(child: _buildStatCard('Total Departments', '$total', Icons.business, AppTheme.primaryColor)),
        const SizedBox(width: 12),
        Expanded(child: _buildStatCard('Active Departments', '$active', Icons.check_circle, AppTheme.successColor)),
        const SizedBox(width: 12),
        Expanded(child: _buildStatCard('Total Doctors', '$doctors', Icons.medical_services, AppTheme.doctorColor)),
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
            Text(value,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: color,
                    )),
            Text(title,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppTheme.textSecondary)),
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
      itemBuilder: (context, index) => Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(_departments[index]['name']),
        ),
      ),
    );
  }
}
