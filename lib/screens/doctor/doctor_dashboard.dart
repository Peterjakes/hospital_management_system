import 'package:flutter/material.dart';
import 'package:hospital_management_system/const/app_theme.dart';
import 'package:hospital_management_system/screens/doctor/doctor_appointments_screen.dart';
import 'package:hospital_management_system/screens/doctor/doctor_patients_screen.dart';
import 'package:hospital_management_system/screens/doctor/doctor_profile_screen.dart';
import 'package:provider/provider.dart';
import 'package:hospital_management_system/providers/auth_provider.dart';
import 'package:hospital_management_system/providers/appointment_provider.dart';
import 'package:hospital_management_system/providers/patient_provider.dart';
import 'package:hospital_management_system/providers/doctor_provider.dart';
import 'package:hospital_management_system/screens/auth/login_screen.dart';
import 'package:hospital_management_system/models/appointment_model.dart';
import 'package:hospital_management_system/services/pdf_service.dart';
import 'package:url_launcher/url_launcher.dart';

// Doctor dashboard screen with prescription management
class DoctorDashboard extends StatefulWidget {
  const DoctorDashboard({super.key});

  @override
  State<DoctorDashboard> createState() => _DoctorDashboardState();
}

class _DoctorDashboardState extends State<DoctorDashboard> {
  int _selectedIndex = 0;
  final PDFService _pdfService = PDFService();

  @override
  void initState() {
    super.initState();
    // Load doctor's appointments when dashboard loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadDoctorData();
    });
  }

  // Load doctor's appointments and patient data
  void _loadDoctorData() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final appointmentProvider = Provider.of<AppointmentProvider>(context, listen: false);
    final patientProvider = Provider.of<PatientProvider>(context, listen: false);
    final doctorProvider = Provider.of<DoctorProvider>(context, listen: false);

    if (authProvider.currentUserId != null) {
      // Load today's appointments for this doctor
      appointmentProvider.loadDoctorAppointments(
        authProvider.currentUserId!,
        date: DateTime.now(),
      );
      
      // Load patient data for displaying patient names
      patientProvider.loadPatients();
      
      // Load current doctor's data for prescription generation
      doctorProvider.getDoctor(authProvider.currentUserId!);
    }
  }

  // logout functionality
  Future<void> _handleLogout() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    await authProvider.signOut();
    
    if (!mounted) return;
    
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => const LoginScreen()),
    );
  }

  // Show prescription management dialog with full workflow
  void _showPrintPrescriptionDemo([Appointment? appointment]) {
    if (appointment == null) {
      // Show message if no appointment selected
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select an appointment to manage prescription'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Get required data for prescription generation
    final patientProvider = Provider.of<PatientProvider>(context, listen: false);
    final doctorProvider = Provider.of<DoctorProvider>(context, listen: false);
    final patient = patientProvider.patients.where((p) => p.id == appointment.patientId).firstOrNull;
    final doctor = doctorProvider.selectedDoctor;

    // Check if all required data is available
    if (patient == null || doctor == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Patient or doctor information not available. Please try again.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Show prescription management options dialog
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.medical_services, color: AppTheme.doctorColor),
            const SizedBox(width: 8),
            const Text('Prescription Management'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Manage prescription for patient:',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.patientColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppTheme.patientColor.withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Patient: ${patient.fullName}', style: const TextStyle(fontWeight: FontWeight.w500)),
                  Text('Appointment: Today ${appointment.appointmentTime}'),
                  Text('Diagnosis: ${appointment.diagnosis ?? appointment.reasonForVisit}'),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const Text('Available Options:'),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.print, size: 16, color: AppTheme.primaryColor),
                const SizedBox(width: 4),
                const Text('Print prescription directly'),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.cloud_upload, size: 16, color: AppTheme.secondaryColor),
                const SizedBox(width: 4),
                const Text('Save to cloud & download PDF'),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.share, size: 16, color: AppTheme.doctorColor),
                const SizedBox(width: 4),
                const Text('Share with patient'),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.of(context).pop();
              _handlePrintPrescription(patient, doctor, appointment);
            },
            icon: const Icon(Icons.print),
            label: const Text('Print'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
            ),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.of(context).pop();
              _handleDownloadPrescription(patient, doctor, appointment);
            },
            icon: const Icon(Icons.download),
            label: const Text('Save & Download'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.secondaryColor,
            ),
          ),
        ],
      ),
    );
  }

  // Handle print prescription functionality
  Future<void> _handlePrintPrescription(patient, doctor, appointment) async {
    try {
      // Show loading dialog
      _showLoadingDialog('Preparing prescription for printing...');
      
      // Use PDF service to print prescription
      await _pdfService.printPrescription(
        patient: patient,
        doctor: doctor,
        appointment: appointment,
      );
      
      // Close loading dialog
      Navigator.of(context).pop();
      
      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Prescription sent to printer successfully!'),
          backgroundColor: AppTheme.successColor,
          duration: Duration(seconds: 3),
        ),
      );
    } catch (e) {
      // Close loading dialog if open
      Navigator.of(context).pop();
      
      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Failed to print prescription: ${e.toString()}'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  // Handle download prescription functionality
  Future<void> _handleDownloadPrescription(patient, doctor, appointment) async {
    try {
      // Show loading dialog
      _showLoadingDialog('Generating and saving prescription PDF...');
      
      // Use PDF service to save prescription to Firebase
      final downloadUrl = await _pdfService.savePrescriptionToFirestore(
        patient: patient,
        doctor: doctor,
        appointment: appointment,
      );
      
      // Close loading dialog
      Navigator.of(context).pop();
      
      if (downloadUrl != null) {
        // Show success dialog with download option
        _showDownloadSuccessDialog(downloadUrl, patient.fullName);
      } else {
        throw Exception('Failed to generate download URL');
      }
    } catch (e) {
      // Close loading dialog if open
      Navigator.of(context).pop();
      
      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Failed to save prescription: ${e.toString()}'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  // Show loading dialog helper
  void _showLoadingDialog(String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
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
  }

  // Show download success dialog with options
  void _showDownloadSuccessDialog(String downloadUrl, String patientName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.check_circle, color: AppTheme.successColor),
            const SizedBox(width: 8),
            const Text('Prescription Saved Successfully'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Prescription has been saved to cloud storage and linked to the appointment.'),
            const SizedBox(height: 12),
            Text('Patient: $patientName'),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.successColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppTheme.successColor.withOpacity(0.3)),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Icon(Icons.cloud_done, color: AppTheme.successColor, size: 16),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          'Saved to Firebase Storage',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.link, color: AppTheme.successColor, size: 16),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          'Linked to appointment record',
                          style: TextStyle(fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
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
              _launchPdfUrl(downloadUrl);
            },
            icon: const Icon(Icons.open_in_browser),
            label: const Text('Open PDF'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
            ),
          ),
        ],
      ),
    );
  }

  // Launch PDF URL for viewing/downloading
  Future<void> _launchPdfUrl(String url) async {
    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        throw Exception('Cannot launch URL');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not open PDF: ${e.toString()}'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Doctor Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.medical_services),
            onPressed: () => _showPrintPrescriptionDemo(),
            tooltip: 'Manage Prescriptions',
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _handleLogout,
            tooltip: 'Logout',
          ),
        ],
      ),
      body: _buildBody(),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  //main body content
  Widget _buildBody() {
    switch (_selectedIndex) {
      case 0:
        return _buildDashboardContent();
      case 1:
        return const DoctorAppointmentsScreen();
      case 2:
        return const DoctorPatientsScreen();
      case 3:
        return const DoctorProfileScreen();
      default:
        return _buildDashboardContent();
    }
  }

  // Build doctor dashboard content
  Widget _buildDashboardContent() {
    return Consumer4<AuthProvider, AppointmentProvider, PatientProvider, DoctorProvider>(
      builder: (context, authProvider, appointmentProvider, patientProvider, doctorProvider, child) {
        // Get all appointments for this doctor
        final doctorAppointments = appointmentProvider.doctorAppointments.toList();

        // Sort appointments by time (keeps your previous behavior)
        doctorAppointments.sort((a, b) => a.appointmentTime.compareTo(b.appointmentTime));

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Welcome card for doctor
              Card(
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [AppTheme.doctorColor, AppTheme.primaryColorDark],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Good morning,',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: Colors.white70,
                        ),
                      ),
                      Text(
                        // use currentUserData which you already have in your code
                        'Dr. ${authProvider.currentUserData?['firstName'] ?? authProvider.currentUserData?['name'] ?? 'Doctor'}',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'You have ${doctorAppointments.length} appointment${doctorAppointments.length == 1 ? '' : 's'} scheduled',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Appointments header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Today\'s Appointments',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (doctorAppointments.isNotEmpty)
                    TextButton.icon(
                      onPressed: () => _showBulkPrescriptionOptions(doctorAppointments),
                      icon: const Icon(Icons.medical_services, size: 16),
                      label: const Text('Bulk Actions'),
                    ),
                ],
              ),
              const SizedBox(height: 12),

              // Loading / error states (same logic as before)
              if (appointmentProvider.isLoading)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(20),
                    child: CircularProgressIndicator(),
                  ),
                )
              else if (appointmentProvider.errorMessage != null)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        const Icon(Icons.error, color: Colors.red),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            appointmentProvider.errorMessage!,
                            style: const TextStyle(color: Colors.red),
                          ),
                        ),
                        TextButton(
                          onPressed: _loadDoctorData,
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                )
              // Show appointments if available
              else if (doctorAppointments.isNotEmpty)
                // reuse your existing appointment card builder which already resolves patient name
                ...doctorAppointments.map((appointment) => _buildAppointmentCard(appointment, patientProvider))
              // Empty state
              else
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        Icon(
                          Icons.calendar_today,
                          size: 48,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'No appointments found',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'You have no scheduled appointments at the moment.',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

              const SizedBox(height: 20),

              // Quick actions
              Text(
                'Quick Actions',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(
                    child: _buildActionCard(
                      'Manage Prescriptions',
                      Icons.medical_services,
                      AppTheme.doctorColor,
                      () => _showPrintPrescriptionDemo(),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildActionCard(
                      'Patient Records',
                      Icons.folder_shared,
                      AppTheme.secondaryColor,
                      () {
                        setState(() {
                          _selectedIndex = 2;
                        });
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildActionCard(
                      'View All Prescriptions',
                      Icons.history,
                      AppTheme.primaryColor,
                      () => _showPrescriptionHistory(),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildActionCard(
                      'Settings',
                      Icons.settings,
                      Colors.grey[600]!,
                      () {
                        setState(() {
                          _selectedIndex = 3;
                        });
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  // Show bulk prescription options for multiple appointments
  void _showBulkPrescriptionOptions(List<Appointment> appointments) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.medical_services, color: AppTheme.doctorColor),
            const SizedBox(width: 8),
            const Text('Bulk Prescription Actions'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('You have ${appointments.length} appointments today.'),
            const SizedBox(height: 16),
            const Text('Available bulk actions:'),
            const SizedBox(height: 8),
            ListTile(
              leading: Icon(Icons.print_outlined, color: AppTheme.primaryColor),
              title: const Text('Print all prescriptions'),
              subtitle: const Text('Generate and print all at once'),
              onTap: () {
                Navigator.of(context).pop();
                _handleBulkPrint(appointments);
              },
            ),
            ListTile(
              leading: Icon(Icons.download_outlined, color: AppTheme.secondaryColor),
              title: const Text('Save all to cloud'),
              subtitle: const Text('Batch save all prescriptions'),
              onTap: () {
                Navigator.of(context).pop();
                _handleBulkSave(appointments);
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  // Handle bulk print functionality
  Future<void> _handleBulkPrint(List<Appointment> appointments) async {
    try {
      _showLoadingDialog('Bulk printing ${appointments.length} prescriptions...');
      
      final patientProvider = Provider.of<PatientProvider>(context, listen: false);
      final doctorProvider = Provider.of<DoctorProvider>(context, listen: false);
      final doctor = doctorProvider.selectedDoctor;
      
      if (doctor == null) {
        throw Exception('Doctor information not available');
      }

      for (final appointment in appointments) {
        final patient = patientProvider.patients.where((p) => p.id == appointment.patientId).firstOrNull;
        if (patient != null) {
          await _pdfService.printPrescription(
            patient: patient,
            doctor: doctor,
            appointment: appointment,
          );
        }
      }
      
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✅ Successfully printed ${appointments.length} prescriptions!'),
          backgroundColor: AppTheme.successColor,
        ),
      );
    } catch (e) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Error during bulk printing: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Handle bulk save functionality
  Future<void> _handleBulkSave(List<Appointment> appointments) async {
    try {
      _showLoadingDialog('Bulk saving ${appointments.length} prescriptions...');
      
      final patientProvider = Provider.of<PatientProvider>(context, listen: false);
      final doctorProvider = Provider.of<DoctorProvider>(context, listen: false);
      final doctor = doctorProvider.selectedDoctor;
      
      if (doctor == null) {
        throw Exception('Doctor information not available');
      }

      int successCount = 0;
      for (final appointment in appointments) {
        final patient = patientProvider.patients.where((p) => p.id == appointment.patientId).firstOrNull;
        if (patient != null) {
          final downloadUrl = await _pdfService.savePrescriptionToFirestore(
            patient: patient,
            doctor: doctor,
            appointment: appointment,
          );
          if (downloadUrl != null) {
            successCount++;
          }
        }
      }
      
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✅ Successfully saved $successCount/${appointments.length} prescriptions to cloud!'),
          backgroundColor: AppTheme.successColor,
        ),
      );
    } catch (e) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Error during bulk save: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Show prescription history
  void _showPrescriptionHistory() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final doctorId = authProvider.currentUserId;
    
    if (doctorId == null) return;

    _showLoadingDialog('Loading prescription history...');
    
    try {
      final prescriptions = await _pdfService.getDoctorPrescriptions(doctorId);
      Navigator.of(context).pop(); // Close loading dialog
      
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Prescription History'),
          content: SizedBox(
            width: double.maxFinite,
            child: prescriptions.isEmpty
                ? const Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.history, size: 48, color: Colors.grey),
                      SizedBox(height: 12),
                      Text('No prescription history found'),
                    ],
                  )
                : ListView.builder(
                    shrinkWrap: true,
                    itemCount: prescriptions.length,
                    itemBuilder: (context, index) {
                      final prescription = prescriptions[index];
                      return ListTile(
                        leading: const Icon(Icons.picture_as_pdf),
                        title: Text(prescription['patientName'] ?? 'Unknown Patient'),
                        subtitle: Text(prescription['fileName'] ?? 'Unknown File'),
                        trailing: IconButton(
                          icon: const Icon(Icons.open_in_browser),
                          onPressed: () {
                            _launchPdfUrl(prescription['fileUrl']);
                          },
                        ),
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
    } catch (e) {
      Navigator.of(context).pop(); // Close loading dialog
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading prescription history: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Build appointment card for real appointment data
  Widget _buildAppointmentCard(Appointment appointment, PatientProvider patientProvider) {
    // Get patient name from the patient provider
    final patient = patientProvider.patients.where((p) => p.id == appointment.patientId).firstOrNull;
    
    final patientName = patient?.fullName ?? 'Unknown Patient';
    final appointmentTime = appointment.appointmentTime;
    final reason = appointment.reasonForVisit;

    // Get status color
    Color statusColor = AppTheme.primaryColor;
    IconData statusIcon = Icons.schedule;
    
    switch (appointment.status) {
      case AppointmentStatus.scheduled:
        statusColor = Colors.orange;
        statusIcon = Icons.schedule;
        break;
      case AppointmentStatus.confirmed:
        statusColor = Colors.blue;
        statusIcon = Icons.check_circle_outline;
        break;
      case AppointmentStatus.inProgress:
        statusColor = Colors.green;
        statusIcon = Icons.medical_services;
        break;
      case AppointmentStatus.completed:
        statusColor = Colors.green[700]!;
        statusIcon = Icons.check_circle;
        break;
      case AppointmentStatus.cancelled:
        statusColor = Colors.red;
        statusIcon = Icons.cancel;
        break;
      case AppointmentStatus.noShow:
        statusColor = Colors.grey;
        statusIcon = Icons.person_off;
        break;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: AppTheme.patientColor,
          child: const Icon(Icons.person, color: Colors.white),
        ),
        title: Row(
          children: [
            Expanded(child: Text(patientName)),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: statusColor.withOpacity(0.3)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(statusIcon, size: 14, color: statusColor),
                  const SizedBox(width: 4),
                  Text(
                    appointment.status.displayName,
                    style: TextStyle(
                      fontSize: 12,
                      color: statusColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('$appointmentTime - $reason'),
            if (!appointment.isPaymentCompleted)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Row(
                  children: [
                    Icon(Icons.payment, size: 14, color: Colors.orange),
                    const SizedBox(width: 4),
                    Text(
                      'Payment ${appointment.paymentStatus.displayName}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.orange[700],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
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
            if (appointment.status == AppointmentStatus.scheduled || 
                appointment.status == AppointmentStatus.confirmed)
              const PopupMenuItem(
                value: 'start',
                child: Row(
                  children: [
                    Icon(Icons.play_arrow, size: 16),
                    SizedBox(width: 8),
                    Text('Start Consultation'),
                  ],
                ),
              ),
            if (appointment.status == AppointmentStatus.inProgress)
              const PopupMenuItem(
                value: 'complete',
                child: Row(
                  children: [
                    Icon(Icons.check_circle, size: 16),
                    SizedBox(width: 8),
                    Text('Mark Complete'),
                  ],
                ),
              ),
            const PopupMenuItem(
              value: 'print',
              child: Row(
                children: [
                  Icon(Icons.medical_services, size: 16),
                  SizedBox(width: 8),
                  Text('Manage Prescription'),
                ],
              ),
            ),
            if (appointment.canBeCancelled)
              const PopupMenuItem(
                value: 'cancel',
                child: Row(
                  children: [
                    Icon(Icons.cancel, size: 16, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Cancel', style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
          ],
          onSelected: (value) {
            _handleAppointmentAction(value, appointment);
          },
        ),
      ),
    );
  }

  // Handle appointment actions
  void _handleAppointmentAction(String action, Appointment appointment) {
    final appointmentProvider = Provider.of<AppointmentProvider>(context, listen: false);

    switch (action) {
      case 'view':
        // Navigate to appointment details or show details dialog
        _showAppointmentDetails(appointment);
        break;
      case 'start':
        appointmentProvider.updateAppointmentStatus(
          appointment.id,
          AppointmentStatus.inProgress,
        );
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Consultation started')),
        );
        break;
      case 'complete':
        appointmentProvider.updateAppointmentStatus(
          appointment.id,
          AppointmentStatus.completed,
        );
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Appointment marked as completed')),
        );
        break;
      case 'print':
        _showPrintPrescriptionDemo(appointment);
        break;
      case 'cancel':
        _showCancelDialog(appointment);
        break;
      default:
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$action action - Coming soon!')),
        );
    }
  }

  // Show appointment details dialog
  void _showAppointmentDetails(Appointment appointment) {
    final patientProvider = Provider.of<PatientProvider>(context, listen: false);
    final patient = patientProvider.patients.where((p) => p.id == appointment.patientId).firstOrNull;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Appointment Details'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Patient: ${patient?.fullName ?? 'Unknown Patient'}'),
            Text('Time: ${appointment.appointmentTime}'),
            Text('Reason: ${appointment.reasonForVisit}'),
            Text('Status: ${appointment.status.displayName}'),
            Text('Fee: ${appointment.formattedFee}'),
            Text('Payment: ${appointment.paymentStatus.displayName}'),
            if (appointment.notes?.isNotEmpty == true)
              Text('Notes: ${appointment.notes}'),
            if (appointment.diagnosis?.isNotEmpty == true)
              Text('Diagnosis: ${appointment.diagnosis}'),
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

  // Show cancel appointment dialog
  void _showCancelDialog(Appointment appointment) {
    final reasonController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Appointment'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Are you sure you want to cancel this appointment?'),
            const SizedBox(height: 16),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                labelText: 'Cancellation Reason',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('No'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              final appointmentProvider = Provider.of<AppointmentProvider>(context, listen: false);
              appointmentProvider.cancelAppointment(appointment.id, reasonController.text);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Appointment cancelled')),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Yes, Cancel'),
          ),
        ],
      ),
    );
  }

  /// Build action card widget
  Widget _buildActionCard(String title, IconData icon, Color color, VoidCallback onTap) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Icon(icon, color: color, size: 32),
              const SizedBox(height: 8),
              Text(
                title,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Build bottom navigation bar
  Widget _buildBottomNavigationBar() {
    return BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      currentIndex: _selectedIndex,
      onTap: (index) {
        setState(() {
          _selectedIndex = index;
        });
      },
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.dashboard),
          label: 'Dashboard',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.calendar_today),
          label: 'Appointments',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.people),
          label: 'Patients',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.person),
          label: 'Profile',
        ),
      ],
    );
  }
}