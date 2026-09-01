import 'package:flutter/material.dart';
import 'package:hospital_management_system/const/app_theme.dart';
import 'package:provider/provider.dart';
import 'package:hospital_management_system/providers/appointment_provider.dart';
import 'package:hospital_management_system/providers/auth_provider.dart';
import 'package:hospital_management_system/providers/patient_provider.dart';
import 'package:hospital_management_system/providers/doctor_provider.dart';
import 'package:hospital_management_system/models/appointment_model.dart';
import 'package:hospital_management_system/screens/patient/book_appointment_screen.dart';
import 'package:hospital_management_system/services/pdf_service.dart';
import 'package:hospital_management_system/services/firestore_service.dart';
import 'package:flutter/foundation.dart' show kDebugMode;

/// Patient appointments screen showing all appointments
class AppointmentsScreen extends StatefulWidget {
  const AppointmentsScreen({super.key});

  @override
  State<AppointmentsScreen> createState() => _AppointmentsScreenState();
}

class _AppointmentsScreenState extends State<AppointmentsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final appointmentProvider = Provider.of<AppointmentProvider>(context, listen: false);
      
      debugPrint('=== APPOINTMENTS SCREEN INIT ===');
      debugPrint('User ID: ${authProvider.currentUserId}');
      debugPrint('Current patient appointments count: ${appointmentProvider.patientAppointments.length}');
      
      if (authProvider.currentUserId != null) {
        // Add debug test to see what's in Firestore
        appointmentProvider.testAppointmentCreation(authProvider.currentUserId!);
        appointmentProvider.loadPatientAppointments(authProvider.currentUserId!);
      } else {
        debugPrint('❌ No current user ID found');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Appointments'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        actions: [
          // Add debug button for testing
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () async {
              debugPrint('=== MANUAL REFRESH TRIGGERED ===');
              await _refreshAppointments();
            },
          ),
        ],
      ),
      body: Consumer<AppointmentProvider>(
        builder: (context, appointmentProvider, child) {
          debugPrint('=== APPOINTMENTS SCREEN BUILD ===');
          debugPrint('Is Loading: ${appointmentProvider.isLoading}');
          debugPrint('Patient appointments count: ${appointmentProvider.patientAppointments.length}');
          debugPrint('Error: ${appointmentProvider.errorMessage}');
          
          // Print each appointment for debugging
          for (int i = 0; i < appointmentProvider.patientAppointments.length; i++) {
            final appointment = appointmentProvider.patientAppointments[i];
            debugPrint('Appointment $i: ${appointment.id} - ${appointment.formattedDateTime} - ${appointment.reasonForVisit}');
          }

          if (appointmentProvider.isLoading) {
            debugPrint('Showing loading indicator');
            return const Center(child: CircularProgressIndicator());
          }

          // Show error message if there is one
          if (appointmentProvider.errorMessage != null) {
            debugPrint('Showing error: ${appointmentProvider.errorMessage}');
            return _buildErrorState(appointmentProvider.errorMessage!);
          }

          final appointments = appointmentProvider.patientAppointments;

          if (appointments.isEmpty) {
            debugPrint('No appointments found - showing empty state');
            return _buildEmptyState();
          }

          debugPrint('Showing ${appointments.length} appointments');
          return RefreshIndicator(
            onRefresh: _refreshAppointments,
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: appointments.length,
              itemBuilder: (context, index) {
                debugPrint('Building card for appointment ${index}: ${appointments[index].id}');
                return _buildAppointmentCard(appointments[index]);
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => const BookAppointmentScreen(),
            ),
          ).then((_) {
            // Refresh appointments when returning from booking screen
            debugPrint('Returned from booking screen - refreshing appointments');
            _refreshAppointments();
          });
        },
        icon: const Icon(Icons.add),
        label: const Text('Book Appointment'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 80,
            color: AppTheme.errorColor,
          ),
          const SizedBox(height: 16),
          Text(
            'Error Loading Appointments',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: AppTheme.errorColor,
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              error,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _refreshAppointments,
            icon: const Icon(Icons.refresh),
            label: const Text('Try Again'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.calendar_today,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No Appointments Yet',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Book your first appointment with our doctors',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey[500],
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const BookAppointmentScreen(),
                ),
              ).then((_) {
                // Refresh appointments when returning from booking screen
                _refreshAppointments();
              });
            },
            icon: const Icon(Icons.add),
            label: const Text('Book Appointment'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          // Debug button for testing
          if (kDebugMode)
            TextButton(
              onPressed: () async {
                final authProvider = Provider.of<AuthProvider>(context, listen: false);
                final appointmentProvider = Provider.of<AppointmentProvider>(context, listen: false);
                
                if (authProvider.currentUserId != null) {
                  debugPrint('=== DEBUG: Testing appointment retrieval ===');
                  await appointmentProvider.testAppointmentCreation(authProvider.currentUserId!);
                }
              },
              child: const Text('Debug: Test Data Retrieval'),
            ),
        ],
      ),
    );
  }

  Widget _buildAppointmentCard(Appointment appointment) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.getStatusColor(appointment.status.value),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    appointment.status.displayName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const Spacer(),
                PopupMenuButton(
                  itemBuilder: (context) => [
                    if (appointment.canBeCancelled)
                      const PopupMenuItem(
                        value: 'reschedule',
                        child: Row(
                          children: [
                            Icon(Icons.calendar_today, size: 16),
                            SizedBox(width: 8),
                            Text('Reschedule'),
                          ],
                        ),
                      ),
                    if (appointment.canBeCancelled)
                      const PopupMenuItem(
                        value: 'cancel',
                        child: Row(
                          children: [
                            Icon(Icons.cancel, size: 16),
                            SizedBox(width: 8),
                            Text('Cancel'),
                          ],
                        ),
                      ),
                    const PopupMenuItem(
                      value: 'details',
                      child: Row(
                        children: [
                          Icon(Icons.info, size: 16),
                          SizedBox(width: 8),
                          Text('View Details'),
                        ],
                      ),
                    ),
                    // Debug menu item
                    if (kDebugMode)
                      const PopupMenuItem(
                        value: 'debug',
                        child: Row(
                          children: [
                            Icon(Icons.bug_report, size: 16),
                            SizedBox(width: 8),
                            Text('Debug Info'),
                          ],
                        ),
                      ),
                  ],
                  onSelected: (value) {
                    if (value == 'reschedule') {
                      _showRescheduleDialog(appointment);
                    } else if (value == 'cancel') {
                      _showCancelDialog(appointment);
                    } else if (value == 'details') {
                      _showAppointmentDetails(appointment);
                    } else if (value == 'debug') {
                      _showDebugInfo(appointment);
                    }
                  },
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              appointment.formattedDateTime,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Reason: ${appointment.reasonForVisit}',
              style: Theme.of(context).textTheme.bodyMedium,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  Icons.attach_money,
                  size: 16,
                  color: AppTheme.textSecondary,
                ),
                Text(
                  appointment.formattedFee,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                if (appointment.isPaid)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppTheme.successColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'PAID',
                      style: TextStyle(
                        color: AppTheme.successColor,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  )
                else
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppTheme.warningColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'PENDING',
                      style: TextStyle(
                        color: AppTheme.warningColor,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showAppointmentDetails(Appointment appointment) {
    bool isGeneratingPdf = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
        title: const Text('Appointment Details'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow('ID', appointment.id),
              _buildDetailRow('Date & Time', appointment.formattedDateTime),
              _buildDetailRow('Reason', appointment.reasonForVisit),
              _buildDetailRow('Status', appointment.status.displayName),
              _buildDetailRow('Fee', appointment.formattedFee),
              _buildDetailRow('Payment Status', appointment.isPaid ? 'Paid' : 'Pending'),
              if (appointment.paymentReference != null)
                _buildDetailRow('Payment Reference', appointment.paymentReference!),
              if (appointment.mpesaReceiptNumber != null)
                _buildDetailRow('M-Pesa Receipt', appointment.mpesaReceiptNumber!),

              // Vitals, diagnosis, and prescription only appear once a
              // doctor has actually recorded them — previously this dialog
              // stopped at payment info, so a patient had no way to see
              // their own visit outcome anywhere in the app.
              if (appointment.hasVitals) ...[
                const Divider(height: 24),
                Text(
                  'Vitals',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                if (appointment.bloodPressure != null)
                  _buildDetailRow('Blood Pressure', appointment.bloodPressure!),
                if (appointment.temperatureCelsius != null)
                  _buildDetailRow('Temperature', '${appointment.temperatureCelsius}°C'),
                if (appointment.heartRateBpm != null)
                  _buildDetailRow('Heart Rate', '${appointment.heartRateBpm} bpm'),
                if (appointment.weightKg != null)
                  _buildDetailRow('Weight', '${appointment.weightKg} kg'),
                if (appointment.heightCm != null)
                  _buildDetailRow('Height', '${appointment.heightCm} cm'),
              ],

              if (appointment.diagnosis != null && appointment.diagnosis!.isNotEmpty) ...[
                const Divider(height: 24),
                Text(
                  'Diagnosis',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(appointment.diagnosis!),
              ],

              if (appointment.hasPrescription) ...[
                const Divider(height: 24),
                Text(
                  'Prescription',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(appointment.prescription!),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
          if (appointment.hasPrescription)
            ElevatedButton.icon(
              onPressed: isGeneratingPdf
                  ? null
                  : () => _downloadPrescription(
                        appointment,
                        setDialogState,
                        (value) => isGeneratingPdf = value,
                      ),
              icon: isGeneratingPdf
                  ? const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.download, size: 16),
              label: Text(isGeneratingPdf ? 'Preparing...' : 'Download Prescription'),
            ),
        ],
        ),
      ),
    );
  }

  // Generates and opens the prescription PDF for a patient's own completed
  // appointment. Previously PDF generation only existed on the doctor side
  // (doctor_dashboard.dart) — a patient had no way to get their own
  // prescription. Reuses the exact same PDFService.printPrescription() the
  // doctor side already calls, which opens the native print/share/save
  // sheet, so no new file-handling code was needed.
  Future<void> _downloadPrescription(
    Appointment appointment,
    void Function(void Function()) setDialogState,
    void Function(bool) setGenerating,
  ) async {
    setDialogState(() => setGenerating(true));

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final patientProvider = Provider.of<PatientProvider>(context, listen: false);
      final doctorProvider = Provider.of<DoctorProvider>(context, listen: false);

      final patient = patientProvider.selectedPatient;
      if (patient == null) {
        await patientProvider.getPatient(authProvider.currentUserId!);
      }
      final resolvedPatient = patientProvider.selectedPatient;
      final doctor = await doctorProvider.getDoctor(appointment.doctorId);

      if (resolvedPatient == null || doctor == null) {
        throw Exception('Unable to load patient or doctor details');
      }

      final pdfService = PDFService();
      await pdfService.printPrescription(
        patient: resolvedPatient,
        doctor: doctor,
        appointment: appointment,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to generate prescription: ${e.toString()}'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    } finally {
      setDialogState(() => setGenerating(false));
    }
  }

  void _showDebugInfo(Appointment appointment) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Debug Information'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Raw Appointment Data:', style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: 8),
              Text(
                appointment.toMap().toString(),
                style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
              ),
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

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }

  void _showRescheduleDialog(Appointment appointment) async {
    // Load the doctor's info first, since the new time picker needs their
    // working hours and availableDays to generate valid slots — same data
    // the original booking screen uses.
    final doctorProvider = Provider.of<DoctorProvider>(context, listen: false);
    final doctor = await doctorProvider.getDoctor(appointment.doctorId);

    if (!mounted) return;
    if (doctor == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Unable to load doctor details for rescheduling'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
      return;
    }

    DateTime? newDate;
    String? newTime;
    Set<String> bookedSlots = {};
    bool isLoadingSlots = false;
    bool isSaving = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          Future<void> loadSlotsForDate(DateTime date) async {
            setDialogState(() {
              isLoadingSlots = true;
              newTime = null;
            });
            try {
              final firestoreService = FirestoreService();
              final slots = await firestoreService.getBookedTimeSlots(
                doctorId: appointment.doctorId,
                date: date,
              );
              setDialogState(() {
                bookedSlots = slots;
                isLoadingSlots = false;
              });
            } catch (_) {
              setDialogState(() => isLoadingSlots = false);
            }
          }

          final dayOfWeek = newDate == null
              ? null
              : const [
                  'Monday', 'Tuesday', 'Wednesday', 'Thursday',
                  'Friday', 'Saturday', 'Sunday',
                ][newDate!.weekday - 1];
          final doctorWorksThatDay = dayOfWeek == null || doctor.isAvailableOnDay(dayOfWeek);

          return AlertDialog(
            title: const Text('Reschedule Appointment'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Currently: ${appointment.formattedDateTime}'),
                  const SizedBox(height: 16),
                  OutlinedButton.icon(
                    onPressed: isSaving
                        ? null
                        : () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: DateTime.now().add(const Duration(days: 1)),
                              firstDate: DateTime.now(),
                              lastDate: DateTime.now().add(const Duration(days: 30)),
                            );
                            if (picked != null) {
                              setDialogState(() => newDate = picked);
                              await loadSlotsForDate(picked);
                            }
                          },
                    icon: const Icon(Icons.calendar_today, size: 16),
                    label: Text(
                      newDate == null
                          ? 'Pick a new date'
                          : '${newDate!.day}/${newDate!.month}/${newDate!.year}',
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (newDate != null && !doctorWorksThatDay)
                    Text(
                      'Doctor is not available on $dayOfWeek.',
                      style: const TextStyle(color: AppTheme.errorColor),
                    )
                  else if (newDate != null && isLoadingSlots)
                    const Center(child: CircularProgressIndicator())
                  else if (newDate != null)
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: doctor.getAvailableTimeSlots().map((time) {
                        final isBooked = bookedSlots.contains(time);
                        final isSelected = newTime == time;
                        return GestureDetector(
                          onTap: isBooked
                              ? null
                              : () => setDialogState(() => newTime = time),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: isBooked
                                  ? Colors.grey.shade200
                                  : (isSelected ? AppTheme.primaryColor : Colors.transparent),
                              border: Border.all(
                                color: isBooked ? Colors.grey.shade400 : AppTheme.primaryColor,
                              ),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Text(
                              isBooked ? '$time (Booked)' : time,
                              style: TextStyle(
                                fontSize: 13,
                                color: isBooked
                                    ? Colors.grey.shade500
                                    : (isSelected ? Colors.white : AppTheme.primaryColor),
                                decoration: isBooked ? TextDecoration.lineThrough : null,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: isSaving ? null : () => Navigator.of(context).pop(),
                child: const Text('Back'),
              ),
              ElevatedButton(
                onPressed: (isSaving || newDate == null || newTime == null)
                    ? null
                    : () async {
                        setDialogState(() => isSaving = true);

                        final appointmentProvider =
                            Provider.of<AppointmentProvider>(context, listen: false);
                        final success = await appointmentProvider.rescheduleAppointment(
                          appointmentId: appointment.id,
                          doctorId: appointment.doctorId,
                          newDate: newDate!,
                          newTime: newTime!,
                        );

                        if (!context.mounted) return;

                        if (success) {
                          Navigator.of(context).pop();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Appointment rescheduled successfully!'),
                              backgroundColor: AppTheme.successColor,
                            ),
                          );
                        } else {
                          setDialogState(() => isSaving = false);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                appointmentProvider.errorMessage ?? 'Failed to reschedule',
                              ),
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
                    : const Text('Confirm Reschedule'),
              ),
            ],
          );
        },
      ),
    );
  }

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
                labelText: 'Reason for cancellation',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Keep Appointment'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              
              debugPrint('Cancelling appointment: ${appointment.id}');
              final appointmentProvider = Provider.of<AppointmentProvider>(context, listen: false);
              
              final success = await appointmentProvider.cancelAppointment(
                appointment.id,
                reasonController.text.trim().isEmpty 
                    ? 'Cancelled by patient' 
                    : reasonController.text.trim(),
              );
              
              if (success && mounted) {
                debugPrint('Appointment cancelled successfully');
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Appointment cancelled successfully'),
                    backgroundColor: AppTheme.successColor,
                  ),
                );
                _refreshAppointments();
              } else {
                debugPrint('Failed to cancel appointment');
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(appointmentProvider.errorMessage ?? 'Failed to cancel appointment'),
                      backgroundColor: AppTheme.errorColor,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.errorColor,
              foregroundColor: Colors.white,
            ),
            child: const Text('Cancel Appointment'),
          ),
        ],
      ),
    );
  }

  Future<void> _refreshAppointments() async {
    debugPrint('=== REFRESHING APPOINTMENTS ===');
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final appointmentProvider = Provider.of<AppointmentProvider>(context, listen: false);
    
    if (authProvider.currentUserId != null) {
      debugPrint('Refreshing appointments for user: ${authProvider.currentUserId}');
      await appointmentProvider.loadPatientAppointments(authProvider.currentUserId!);
      debugPrint('Refresh complete. New count: ${appointmentProvider.patientAppointments.length}');
    } else {
      debugPrint('❌ Cannot refresh - no current user ID');
    }
  }
}