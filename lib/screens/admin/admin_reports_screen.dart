import 'package:flutter/material.dart';
import 'package:hospital_management_system/const/app_theme.dart';
import 'package:provider/provider.dart';
import 'package:hospital_management_system/providers/patient_provider.dart';
import 'package:hospital_management_system/providers/doctor_provider.dart';
import 'package:hospital_management_system/services/system_reports_service.dart';

/// Admin reports and analytics screen with real PDF generation using SystemReportsService with provider data
class AdminReportsScreen extends StatefulWidget {
  const AdminReportsScreen({super.key});

  @override
  State<AdminReportsScreen> createState() => _AdminReportsScreenState();
}

class _AdminReportsScreenState extends State<AdminReportsScreen> {
  final SystemReportsService _reportsService = SystemReportsService();

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
                'Comprehensive system reports and analytics using real data',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.textSecondary,
                ),
              ),
              const SizedBox(height: 24),

              // Quick Actions
              _buildQuickActions(patientProvider, doctorProvider),
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
              _buildReportGeneration(patientProvider, doctorProvider),
            ],
          ),
        );
      },
    );
  }

  Widget _buildQuickActions(PatientProvider patientProvider, DoctorProvider doctorProvider) {
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
                    () => _generateSystemReport(patientProvider, doctorProvider),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildActionButton(
                    'Save to Storage',
                    Icons.cloud_upload,
                    AppTheme.secondaryColor,
                    () => _saveReportToStorage(patientProvider, doctorProvider),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildActionButton(
                    'Print Reports',
                    Icons.print,
                    AppTheme.adminColor,
                    () => _printReports(patientProvider, doctorProvider),
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
    final totalDepartments = doctorProvider.specializations.length;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'System Overview (Real Data)',
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
                    totalDepartments.toString(),
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
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Icon(Icons.info, color: AppTheme.warningColor, size: 48),
              const SizedBox(height: 16),
              Text(
                'No patient data available',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              Text(
                'Load patients to see analytics',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.textSecondary,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Patient Analytics (Real Data)',
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
                'Blood Group Distribution (From Real Data):',
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
              'Doctor Analytics (Real Data)',
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
                'Top Rated Doctors (From Real Data):',
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

  Widget _buildReportGeneration(PatientProvider patientProvider, DoctorProvider doctorProvider) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Report Generation (Using Real Provider Data)',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            // Report Types using your SystemReportsService with provider data
            _buildReportType(
              'Patient Statistics Report',
              'Detailed analysis of patient demographics from real provider data',
              Icons.people,
              () => _generateSpecificReport('patient', patientProvider, doctorProvider),
            ),
            const SizedBox(height: 12),
            
            _buildReportType(
              'Doctor Performance Report',
              'Analysis of doctor ratings and performance from real provider data',
              Icons.medical_services,
              () => _generateSpecificReport('doctor', patientProvider, doctorProvider),
            ),
            const SizedBox(height: 12),
            
            _buildReportType(
              'Appointment Analytics Report',
              'Monthly appointment statistics and Firebase appointment data',
              Icons.calendar_today,
              () => _generateSpecificReport('appointment', patientProvider, doctorProvider),
            ),
            const SizedBox(height: 12),
            
            _buildReportType(
              'System Analytics Report',
              'Complete system usage patterns with real provider data',
              Icons.analytics,
              () => _generateSpecificReport('system', patientProvider, doctorProvider),
            ),
            const SizedBox(height: 12),
            
            _buildReportType(
              'Complete System Report PDF',
              'Comprehensive PDF report with all real data from providers',
              Icons.picture_as_pdf,
              () => _generateCompletePDFReport(patientProvider, doctorProvider),
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

  // Updated methods using the new SystemReportsService with provider data

  Future<void> _generateSystemReport(PatientProvider patientProvider, DoctorProvider doctorProvider) async {
    _showLoadingDialog('System Report', 'Generating comprehensive system report with real provider data...');
    
    try {
      await _reportsService.printSystemReportsFromProviders(patientProvider, doctorProvider);
      
      Navigator.of(context).pop();
      _showSuccessSnackbar('System Report generated and sent to printer using real data!');
    } catch (e) {
      Navigator.of(context).pop();
      _showErrorSnackbar('Failed to generate system report: $e');
    }
  }

  Future<void> _saveReportToStorage(PatientProvider patientProvider, DoctorProvider doctorProvider) async {
    _showLoadingDialog('Save Report', 'Saving comprehensive system report with real data to Firebase Storage...');
    
    try {
      final downloadUrl = await _reportsService.saveSystemReportToStorageFromProviders(patientProvider, doctorProvider);
      
      Navigator.of(context).pop();
      
      if (downloadUrl != null) {
        _showSuccessSnackbar('Report saved to Firebase Storage successfully with real data!');
      } else {
        _showErrorSnackbar('Failed to save report to storage');
      }
    } catch (e) {
      Navigator.of(context).pop();
      _showErrorSnackbar('Failed to save report: $e');
    }
  }

  Future<void> _printReports(PatientProvider patientProvider, DoctorProvider doctorProvider) async {
    _showLoadingDialog('Print Reports', 'Preparing comprehensive system reports with real provider data...');
    
    try {
      await _reportsService.printSystemReportsFromProviders(patientProvider, doctorProvider);
      
      Navigator.of(context).pop();
      _showSuccessSnackbar('Reports sent to printer successfully using real data!');
    } catch (e) {
      Navigator.of(context).pop();
      _showErrorSnackbar('Failed to print reports: $e');
    }
  }

  Future<void> _generateSpecificReport(String reportType, PatientProvider patientProvider, DoctorProvider doctorProvider) async {
    String title = '';
    
    switch (reportType) {
      case 'patient':
        title = 'Patient Statistics Report';
        break;
      case 'doctor':
        title = 'Doctor Performance Report';
        break;
      case 'appointment':
        title = 'Appointment Analytics Report';
        break;
      case 'system':
        title = 'System Analytics Report';
        break;
    }
    
    _showLoadingDialog(title, 'Generating $title with real provider data...');
    
    try {
      // Use your SystemReportsService methods with provider data
      switch (reportType) {
        case 'patient':
          final stats = _reportsService.generatePatientStatisticsFromProvider(patientProvider);
          print('Patient Statistics Generated from Provider: $stats');
          _showReportSummary('Patient Statistics', stats);
          break;
        case 'doctor':
          final performance = _reportsService.generateDoctorPerformanceFromProvider(doctorProvider);
          print('Doctor Performance Generated from Provider: $performance');
          _showReportSummary('Doctor Performance', performance);
          break;
        case 'appointment':
          final appointments = await _reportsService.generateAppointmentReport();
          print('Appointment Report Generated: $appointments');
          _showReportSummary('Appointment Analytics', appointments);
          break;
        case 'system':
          final analytics = _reportsService.generateSystemAnalyticsFromProvider(patientProvider, doctorProvider);
          print('System Analytics Generated from Providers: $analytics');
          _showReportSummary('System Analytics', analytics);
          break;
      }
      
      Navigator.of(context).pop();
      _showSuccessSnackbar('$title generated successfully with real data!');
    } catch (e) {
      Navigator.of(context).pop();
      _showErrorSnackbar('Failed to generate $title: $e');
    }
  }

  Future<void> _generateCompletePDFReport(PatientProvider patientProvider, DoctorProvider doctorProvider) async {
    _showLoadingDialog('Complete PDF Report', 'Generating comprehensive PDF report with real provider data...');
    
    try {
      final pdfData = await _reportsService.generateSystemReportPDFFromProviders(patientProvider, doctorProvider);
      
      Navigator.of(context).pop();
      
      // Show success and offer to print
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('PDF Report Generated'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.check_circle, color: AppTheme.successColor, size: 64),
              const SizedBox(height: 16),
              const Text('Complete system PDF report generated successfully with real provider data!'),
              const SizedBox(height: 8),
              Text(
                'Size: ${(pdfData.length / 1024).toStringAsFixed(1)} KB',
                style: TextStyle(color: AppTheme.textSecondary),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.of(context).pop();
                _printReports(patientProvider, doctorProvider);
              },
              icon: const Icon(Icons.print),
              label: const Text('Print Now'),
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryColor),
            ),
          ],
        ),
      );
    } catch (e) {
      Navigator.of(context).pop();
      _showErrorSnackbar('Failed to generate PDF report: $e');
    }
  }

  void _showReportSummary(String title, Map<String, dynamic> data) {
    List<String> summaryLines = [];
    
    switch (title) {
      case 'Patient Statistics':
        summaryLines = [
          'Total Patients: ${data['totalPatients']}',
          'Gender Distribution:',
          '  - Male: ${data['genderDistribution']['Male']}',
          '  - Female: ${data['genderDistribution']['Female']}',
          'Age Groups:',
          '  - Children (0-18): ${data['ageGroups']['0-18']}',
          '  - Young Adults (19-35): ${data['ageGroups']['19-35']}',
          '  - Adults (36-50): ${data['ageGroups']['36-50']}',
          'Blood Groups: ${(data['bloodGroupDistribution'] as Map).length} types',
        ];
        break;
      case 'Doctor Performance':
        final doctors = data['doctorPerformance'] as List;
        summaryLines = [
          'Total Doctors: ${data['totalDoctors']}',
          'Doctors with Performance Data: ${doctors.length}',
        ];
        if (doctors.isNotEmpty) {
          final top = doctors.first;
          summaryLines.addAll([
            'Top Performer: ${top['doctorName']}',
            'Top Doctor Appointments: ${top['totalAppointments']}',
            'Top Doctor Revenue: \$${top['totalRevenue'].toStringAsFixed(2)}',
          ]);
        }
        break;
      case 'System Analytics':
        final totals = data['systemTotals'];
        summaryLines = [
          'System Totals:',
          '  - Patients: ${totals['totalPatients']}',
          '  - Doctors: ${totals['totalDoctors']}',
          '  - Appointments: ${totals['totalAppointments']}',
          'Peak Usage: ${data['usagePatterns']['peakHour']}',
          'Busiest Day: ${data['usagePatterns']['busiestDay']}',
        ];
        break;
      case 'Appointment Analytics':
        summaryLines = [
          'Total Appointments: ${data['totalAppointments']}',
          'Monthly Appointments: ${data['monthlyAppointments']}',
          'Completed: ${data['completedAppointments']}',
          'Total Revenue: \$${data['totalRevenue'].toStringAsFixed(2)}',
          'Report Period: ${data['reportPeriod']}',
        ];
        break;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('$title Summary'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Report generated with real provider data:'),
            const SizedBox(height: 12),
            ...summaryLines.map((line) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Text(line),
            )),
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

  void _showLoadingDialog(String title, String message) {
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
            const SizedBox(height: 8),
            Text(
              'Using real data from PatientProvider and DoctorProvider...',
              style: TextStyle(
                fontSize: 12,
                color: AppTheme.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showSuccessSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('✅ $message'),
        backgroundColor: AppTheme.successColor,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('❌ $message'),
        backgroundColor: AppTheme.errorColor,
        duration: const Duration(seconds: 4),
      ),
    );
  }
}