import 'package:flutter/material.dart';
import 'package:hospital_management_system/const/app_theme.dart';
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
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Text(
                'Reports & Analytics',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Comprehensive system reports and analytics',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.textSecondary,
                ),
              ),
              const SizedBox(height: 24),

              // Quick Actions
              _buildQuickActions(),
              const SizedBox(height: 24),

              // System Overview
              _buildSystemOverview(patientProvider, doctorProvider),
              const SizedBox(height: 24),

              // Patient Analytics
              if (!patientProvider.isLoading)
                _buildPatientAnalytics(patientProvider),
              const SizedBox(height: 24),

              // Doctor Analytics
              if (!doctorProvider.isLoading)
                _buildDoctorAnalytics(doctorProvider),
              const SizedBox(height: 24),

              // Report Generation
              _buildReportGeneration(),
            ],
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
            Text(
              'Quick Actions',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildActionButton(
                    'Generate Report',
                    Icons.assessment,
                    AppTheme.primaryColor,
                    _generateSystemReport,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildActionButton(
                    'Export Data',
                    Icons.download,
                    AppTheme.secondaryColor,
                    _exportData,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildActionButton(
                    'Print Reports',
                    Icons.print,
                    AppTheme.adminColor,
                    _printReports,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(String title, IconData icon, Color color, VoidCallback onPressed) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon),
      label: Text(title),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        padding: const EdgeInsets.symmetric(vertical: 12),
      ),
    );
  }

  Widget _buildSystemOverview(PatientProvider patientProvider, DoctorProvider doctorProvider) {
    final totalPatients = patientProvider.patients.length;
    final totalDoctors = doctorProvider.doctors.length;
    final availableDoctors = doctorProvider.availableDoctors.length;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'System Overview',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildOverviewCard(
                    'Total Patients',
                    totalPatients.toString(),
                    Icons.people,
                    AppTheme.patientColor,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildOverviewCard(
                    'Total Doctors',
                    totalDoctors.toString(),
                    Icons.medical_services,
                    AppTheme.doctorColor,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildOverviewCard(
                    'Available Doctors',
                    availableDoctors.toString(),
                    Icons.check_circle,
                    AppTheme.successColor,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildOverviewCard(
                    'Departments',
                    '12',
                    Icons.business,
                    AppTheme.primaryColor,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOverviewCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
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
    );
  }

  Widget _buildPatientAnalytics(PatientProvider patientProvider) {
    final stats = patientProvider.getPatientStatistics();
    
    if (stats.isEmpty) {
      return const SizedBox.shrink();
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Patient Analytics',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            // Gender Distribution
            Row(
              children: [
                Expanded(
                  child: _buildAnalyticsCard(
                    'Male Patients',
                    stats['male']?.toString() ?? '0',
                    Icons.male,
                    Colors.blue,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildAnalyticsCard(
                    'Female Patients',
                    stats['female']?.toString() ?? '0',
                    Icons.female,
                    Colors.pink,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            
            // Age Groups
            Row(
              children: [
                Expanded(
                  child: _buildAnalyticsCard(
                    'Children (<18)',
                    stats['children']?.toString() ?? '0',
                    Icons.child_care,
                    Colors.orange,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildAnalyticsCard(
                    'Adults (18-65)',
                    stats['adults']?.toString() ?? '0',
                    Icons.person,
                    Colors.green,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildAnalyticsCard(
                    'Seniors (65+)',
                    stats['seniors']?.toString() ?? '0',
                    Icons.elderly,
                    Colors.purple,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            
            // Blood Groups
            if (stats['bloodGroups'] != null) ...[
              Text(
                'Blood Group Distribution:',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: (stats['bloodGroups'] as Map<String, int>).entries.map((entry) {
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppTheme.errorColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppTheme.errorColor.withOpacity(0.3)),
                    ),
                    child: Text(
                      '${entry.key}: ${entry.value}',
                      style: TextStyle(
                        color: AppTheme.errorColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDoctorAnalytics(DoctorProvider doctorProvider) {
    final doctors = doctorProvider.doctors;
    final specializations = doctorProvider.specializations;
    final topRatedDoctors = doctorProvider.getTopRatedDoctors(limit: 5);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Doctor Analytics',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            // Specializations
            Text(
              'Specializations (${specializations.length}):',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: specializations.map((spec) {
                final count = doctors.where((d) => d.specialization == spec).length;
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppTheme.doctorColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppTheme.doctorColor.withOpacity(0.3)),
                  ),
                  child: Text(
                    '$spec: $count',
                    style: TextStyle(
                      color: AppTheme.doctorColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                );
              }).toList(),
            ),
            
            if (topRatedDoctors.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(
                'Top Rated Doctors:',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              ...topRatedDoctors.take(3).map((doctor) {
                return ListTile(
                  dense: true,
                  leading: CircleAvatar(
                    backgroundColor: AppTheme.doctorColor,
                    child: Text(
                      '${doctor.firstName[0]}${doctor.lastName[0]}',
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ),
                  title: Text('Dr. ${doctor.fullName}'),
                  subtitle: Text(doctor.specialization),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.star, color: Colors.amber, size: 16),
                      Text(' ${doctor.formattedRating}'),
                    ],
                  ),
                );
              }),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildAnalyticsCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 4),
          Text(
            value,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
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
    );
  }

  Widget _buildReportGeneration() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Report Generation',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            // Report Types
            _buildReportType(
              'Patient Demographics Report',
              'Detailed analysis of patient demographics, age groups, and medical conditions',
              Icons.people,
              () => _generateReport('demographics'),
            ),
            const SizedBox(height: 12),
            
            _buildReportType(
              'Doctor Performance Report',
              'Analysis of doctor ratings, appointments, and availability statistics',
              Icons.medical_services,
              () => _generateReport('performance'),
            ),
            const SizedBox(height: 12),
            
            _buildReportType(
              'Department Utilization Report',
              'Department-wise patient distribution and resource utilization',
              Icons.business,
              () => _generateReport('departments'),
            ),
            const SizedBox(height: 12),
            
            _buildReportType(
              'Financial Summary Report',
              'Revenue analysis, consultation fees, and payment statistics',
              Icons.attach_money,
              () => _generateReport('financial'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReportType(String title, String description, IconData icon, VoidCallback onGenerate) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.withOpacity(0.3)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppTheme.primaryColor),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  description,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: onGenerate,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            ),
            child: const Text('Generate'),
          ),
        ],
      ),
    );
  }

  void _generateSystemReport() {
    _showReportDialog('System Report', 'Generating comprehensive system report...');
  }

  void _exportData() {
    _showReportDialog('Data Export', 'Exporting system data to CSV format...');
  }

  void _printReports() {
    _showReportDialog('Print Reports', 'Preparing reports for printing...');
  }

  void _generateReport(String reportType) {
    String title = '';
    switch (reportType) {
      case 'demographics':
        title = 'Patient Demographics Report';
        break;
      case 'performance':
        title = 'Doctor Performance Report';
        break;
      case 'departments':
        title = 'Department Utilization Report';
        break;
      case 'financial':
        title = 'Financial Summary Report';
        break;
    }
    
    _showReportDialog(title, 'Generating $title...');
  }

  void _showReportDialog(String title, String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(message),
          ],
        ),
      ),
    );

    // Simulate report generation
    Future.delayed(const Duration(seconds: 3), () {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✅ $title generated successfully!'),
          backgroundColor: AppTheme.successColor,
        ),
      );
    });
  }
}