import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:hospital_management_system/providers/patient_provider.dart';
import 'package:hospital_management_system/providers/doctor_provider.dart';

/// Admin reports and analytics screen
class AdminReportsScreen extends StatefulWidget {
  const AdminReportsScreen({super.key});
  
  @override
  State<AdminReportsScreen> createState() => _AdminReportsScreenState();
}

class _AdminReportsScreenState extends State<AdminReportsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<PatientProvider>(context, listen: false).loadPatients();
      Provider.of<DoctorProvider>(context, listen: false).loadDoctors();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<PatientProvider, DoctorProvider>(
      builder: (context, patientProvider, doctorProvider, child) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Reports & Analytics'),
            backgroundColor: Theme.of(context).primaryColor,
            foregroundColor: Colors.white,
          ),
          body: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _buildSystemOverview(patientProvider, doctorProvider),
                const SizedBox(height: 16),
                _buildQuickActions(),
                const SizedBox(height: 16),
                const Expanded(
                  child: Center(
                    child: Text(
                      'Additional analytics and reports will be displayed here',
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildQuickActions() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Quick Actions', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(child: _buildActionButton('Generate Report', Icons.assessment, Colors.blue, _generateSystemReport)),
                const SizedBox(width: 12),
                Expanded(child: _buildActionButton('Export Data', Icons.download, Colors.green, _exportData)),
                const SizedBox(width: 12),
                Expanded(child: _buildActionButton('Print', Icons.print, Colors.orange, _printReports)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSystemOverview(PatientProvider patientProvider, DoctorProvider doctorProvider) {
    final totalPatients = patientProvider.patients.length;
    final totalDoctors = doctorProvider.doctors.length;
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('System Overview', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(child: _buildOverviewCard('Patients', '$totalPatients', Icons.people, Colors.blue)),
                const SizedBox(width: 12),
                Expanded(child: _buildOverviewCard('Doctors', '$totalDoctors', Icons.medical_services, Colors.green)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOverviewCard(String title, String count, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, size: 32, color: color),
          const SizedBox(height: 8),
          Text(
            count,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(String title, IconData icon, Color color, VoidCallback onPressed) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, color: Colors.white),
      label: Text(
        title,
        style: const TextStyle(color: Colors.white),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  void _generateSystemReport() {
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Generating system report...')),
    );
  }

  void _exportData() {
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Exporting data...')),
    );
  }

  void _printReports() {
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Preparing to print reports...')),
    );
  }
}