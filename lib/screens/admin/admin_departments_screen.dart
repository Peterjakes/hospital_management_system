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
      itemBuilder: (context, index) => _buildDepartmentCard(_departments[index], index),
    );
  }

  Widget _buildDepartmentCard(Map<String, dynamic> department, int index) {
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
                    department['name'],
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ),
                PopupMenuButton(
                  itemBuilder: (context) => [
                    const PopupMenuItem(value: 'edit', child: Text('Edit')),
                    const PopupMenuItem(value: 'doctors', child: Text('Manage Doctors')),
                    PopupMenuItem(
                      value: department['isActive'] ? 'deactivate' : 'activate',
                      child: Text(department['isActive'] ? 'Deactivate' : 'Activate'),
                    ),
                  ],
                  onSelected: (value) {
                    _handleDepartmentAction(department, value.toString(), index);
                  },
                ),
              ],
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: department['isActive'] ? AppTheme.successColor : AppTheme.errorColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                department['isActive'] ? 'Active' : 'Inactive',
                style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 12),
            _buildInfoRow(Icons.person, 'Head: ${department['head']}'),
            _buildInfoRow(Icons.people, '${department['doctors']} Doctors'),
            _buildInfoRow(Icons.location_on, department['location']),
            _buildInfoRow(Icons.phone, department['phone']),
            const SizedBox(height: 8),
            Text('Services:', style: Theme.of(context).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.bold)),
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
                    style: TextStyle(fontSize: 10, color: AppTheme.primaryColor, fontWeight: FontWeight.w500),
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
            child: Text(text, style: Theme.of(context).textTheme.bodySmall, overflow: TextOverflow.ellipsis),
          ),
        ],
      ),
    );
  }

  
  void _handleDepartmentAction(Map<String, dynamic> department, String action, int index) {
    switch (action) {
      case 'edit':
        // Handle edit department
        break;
      case 'doctors':
        // Handle manage doctors
        break;
      case 'activate':
      case 'deactivate':
        setState(() {
          _departments[index]['isActive'] = !department['isActive'];
        });
        break;
    }
  }
}