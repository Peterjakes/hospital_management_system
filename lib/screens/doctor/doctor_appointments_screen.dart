import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:hospital_management_system/const/app_theme.dart';
import 'package:provider/provider.dart';
import 'package:hospital_management_system/providers/appointment_provider.dart';
import 'package:hospital_management_system/providers/auth_provider.dart';
import 'package:hospital_management_system/models/appointment_model.dart';


/// Doctor appointments screen showing all doctor appointments
class DoctorAppointmentsScreen extends StatefulWidget {
  const DoctorAppointmentsScreen({super.key});

  @override
  State<DoctorAppointmentsScreen> createState() => _DoctorAppointmentsScreenState();
}

class _DoctorAppointmentsScreenState extends State<DoctorAppointmentsScreen> {
  DateTime _selectedDate = DateTime.now();
  DateTime _focusedCalendarDay = DateTime.now();
  bool _showCalendarView = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadAppointments();
    });
  }

  void _loadAppointments() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final appointmentProvider = Provider.of<AppointmentProvider>(context, listen: false);
    
    if (authProvider.currentUserId != null) {
      appointmentProvider.loadDoctorAppointments(
        authProvider.currentUserId!,
        date: _selectedDate,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppointmentProvider>(
      builder: (context, appointmentProvider, child) {
        if (appointmentProvider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        final appointments = appointmentProvider.doctorAppointments;

        return Column(
          children: [
            // Date Selector
            _buildDateSelector(),
            
            // Appointments List
            Expanded(
              child: appointments.isEmpty
                  ? _buildEmptyState()
                  : RefreshIndicator(
                      onRefresh: _refreshAppointments,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: appointments.length,
                        itemBuilder: (context, index) {
                          return _buildAppointmentCard(appointments[index]);
                        },
                      ),
                    ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildDateSelector() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Appointments for ${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              // No calendar view existed anywhere in the app before — a
              // doctor could only jump to one date at a time via a picker
              // dialog, with no visual sense of their schedule across days.
              IconButton(
                onPressed: () {
                  setState(() => _showCalendarView = !_showCalendarView);
                },
                icon: Icon(_showCalendarView ? Icons.view_list : Icons.calendar_view_month),
                tooltip: _showCalendarView ? 'List view' : 'Calendar view',
              ),
              IconButton(
                onPressed: _selectDate,
                icon: const Icon(Icons.calendar_today),
                tooltip: 'Select Date',
              ),
            ],
          ),
          if (_showCalendarView) ...[
            const SizedBox(height: 8),
            TableCalendar(
              firstDay: DateTime.now().subtract(const Duration(days: 365)),
              lastDay: DateTime.now().add(const Duration(days: 365)),
              focusedDay: _focusedCalendarDay,
              calendarFormat: CalendarFormat.month,
              selectedDayPredicate: (day) => isSameDay(day, _selectedDate),
              onDaySelected: (selectedDay, focusedDay) {
                setState(() {
                  _selectedDate = selectedDay;
                  _focusedCalendarDay = focusedDay;
                });
                _loadAppointments();
              },
              onPageChanged: (focusedDay) {
                _focusedCalendarDay = focusedDay;
              },
              calendarStyle: CalendarStyle(
                selectedDecoration: BoxDecoration(
                  color: AppTheme.primaryColor,
                  shape: BoxShape.circle,
                ),
                todayDecoration: BoxDecoration(
                  color: AppTheme.primaryColor.withOpacity(0.3),
                  shape: BoxShape.circle,
                ),
              ),
              headerStyle: const HeaderStyle(
                formatButtonVisible: false,
                titleCentered: true,
              ),
            ),
          ],
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
            'No Appointments',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'No appointments scheduled for this date',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppointmentCard(Appointment appointment) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
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
                  itemBuilder: (context) => _buildMenuItemsForStatus(appointment.status),
                  onSelected: (value) {
                    _handleAppointmentAction(appointment, value.toString());
                  },
                ),
              ],
            ),
            const SizedBox(height: 12),
            
            // Time
            Row(
              children: [
                Icon(Icons.access_time, size: 16, color: AppTheme.textSecondary),
                const SizedBox(width: 8),
                Text(
                  appointment.appointmentTime,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            
            // Patient Name (placeholder - would need patient data)
            Text(
              'Patient ID: ${appointment.patientId}',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            
            // Reason
            Text(
              'Reason: ${appointment.reasonForVisit}',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            
            if (appointment.notes != null) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Notes:',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(appointment.notes!),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime.now().add(const Duration(days: 30)),
    );
    
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
      _loadAppointments();
    }
  }

  // Menu options are now conditional on the appointment's actual status.
  // Previously every option (Start, Complete, Vitals, Prescription) showed
  // for every appointment regardless of state — a doctor could tap "Mark
  // Complete" on something never started, or "Start" on something already
  // cancelled. This also adds the missing Accept/Decline step for a newly
  // booked appointment, which the roadmap calls "doctor acceptance/
  // rejection" — implemented using the existing scheduled/confirmed/
  // cancelled statuses rather than adding a new enum value.
  List<PopupMenuEntry<String>> _buildMenuItemsForStatus(AppointmentStatus status) {
    switch (status) {
      case AppointmentStatus.scheduled:
        return const [
          PopupMenuItem(
            value: 'accept',
            child: Row(
              children: [
                Icon(Icons.check_circle_outline, size: 16, color: Colors.green),
                SizedBox(width: 8),
                Text('Accept'),
              ],
            ),
          ),
          PopupMenuItem(
            value: 'decline',
            child: Row(
              children: [
                Icon(Icons.cancel_outlined, size: 16, color: Colors.red),
                SizedBox(width: 8),
                Text('Decline'),
              ],
            ),
          ),
        ];
      case AppointmentStatus.confirmed:
        return const [
          PopupMenuItem(
            value: 'start',
            child: Row(
              children: [
                Icon(Icons.play_arrow, size: 16),
                SizedBox(width: 8),
                Text('Start Consultation'),
              ],
            ),
          ),
          PopupMenuItem(
            value: 'decline',
            child: Row(
              children: [
                Icon(Icons.cancel_outlined, size: 16, color: Colors.red),
                SizedBox(width: 8),
                Text('Cancel'),
              ],
            ),
          ),
        ];
      case AppointmentStatus.inProgress:
        return const [
          PopupMenuItem(
            value: 'vitals',
            child: Row(
              children: [
                Icon(Icons.monitor_heart_outlined, size: 16),
                SizedBox(width: 8),
                Text('Record Vitals'),
              ],
            ),
          ),
          PopupMenuItem(
            value: 'prescription',
            child: Row(
              children: [
                Icon(Icons.receipt, size: 16),
                SizedBox(width: 8),
                Text('Add Prescription'),
              ],
            ),
          ),
          PopupMenuItem(
            value: 'complete',
            child: Row(
              children: [
                Icon(Icons.check_circle, size: 16),
                SizedBox(width: 8),
                Text('Mark Complete'),
              ],
            ),
          ),
        ];
      case AppointmentStatus.completed:
        // A completed visit's vitals/prescription can still be reviewed or
        // corrected — the dialogs already pre-fill existing values.
        return const [
          PopupMenuItem(
            value: 'vitals',
            child: Row(
              children: [
                Icon(Icons.monitor_heart_outlined, size: 16),
                SizedBox(width: 8),
                Text('View/Edit Vitals'),
              ],
            ),
          ),
          PopupMenuItem(
            value: 'prescription',
            child: Row(
              children: [
                Icon(Icons.receipt, size: 16),
                SizedBox(width: 8),
                Text('View/Edit Prescription'),
              ],
            ),
          ),
        ];
      case AppointmentStatus.cancelled:
      case AppointmentStatus.noShow:
        return const [];
    }
  }

  void _handleAppointmentAction(Appointment appointment, String action) {
    switch (action) {
      case 'accept':
        _updateAppointmentStatus(appointment, AppointmentStatus.confirmed);
        break;
      case 'decline':
        _showDeclineDialog(appointment);
        break;
      case 'start':
        _updateAppointmentStatus(appointment, AppointmentStatus.inProgress);
        break;
      case 'complete':
        _updateAppointmentStatus(appointment, AppointmentStatus.completed);
        break;
      case 'vitals':
        _showVitalsDialog(appointment);
        break;
      case 'prescription':
        _showPrescriptionDialog(appointment);
        break;
    }
  }

  Future<void> _updateAppointmentStatus(Appointment appointment, AppointmentStatus status) async {
    final appointmentProvider = Provider.of<AppointmentProvider>(context, listen: false);
    
    final success = await appointmentProvider.updateAppointmentStatus(
      appointment.id,
      status,
    );
    
    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Appointment ${status.displayName.toLowerCase()}'),
          backgroundColor: AppTheme.successColor,
        ),
      );
      _refreshAppointments();
    }
  }

  void _showDeclineDialog(Appointment appointment) {
    final reasonController = TextEditingController();
    bool isSaving = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(
            appointment.status == AppointmentStatus.scheduled
                ? 'Decline Appointment'
                : 'Cancel Appointment',
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                appointment.status == AppointmentStatus.scheduled
                    ? 'This will let the patient know you are unable to take this appointment.'
                    : 'This will cancel a confirmed appointment. The patient will be notified.',
              ),
              const SizedBox(height: 16),
              TextField(
                controller: reasonController,
                decoration: const InputDecoration(
                  labelText: 'Reason',
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: isSaving ? null : () => Navigator.of(context).pop(),
              child: const Text('Back'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.errorColor),
              onPressed: isSaving
                  ? null
                  : () async {
                      final reason = reasonController.text.trim();
                      if (reason.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Please provide a reason'),
                            backgroundColor: AppTheme.errorColor,
                          ),
                        );
                        return;
                      }

                      setDialogState(() => isSaving = true);

                      final appointmentProvider =
                          Provider.of<AppointmentProvider>(context, listen: false);
                      final success = await appointmentProvider.cancelAppointment(
                        appointment.id,
                        reason,
                      );

                      if (!context.mounted) return;

                      if (success) {
                        Navigator.of(context).pop();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Appointment updated'),
                            backgroundColor: AppTheme.successColor,
                          ),
                        );
                        _refreshAppointments();
                      } else {
                        setDialogState(() => isSaving = false);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              appointmentProvider.errorMessage ?? 'Failed to update appointment',
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
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Text('Confirm'),
            ),
          ],
        ),
      ),
    );
  }

  void _showVitalsDialog(Appointment appointment) {
    final bpController = TextEditingController(text: appointment.bloodPressure ?? '');
    final tempController = TextEditingController(
      text: appointment.temperatureCelsius?.toString() ?? '',
    );
    final heartRateController = TextEditingController(
      text: appointment.heartRateBpm?.toString() ?? '',
    );
    final weightController = TextEditingController(
      text: appointment.weightKg?.toString() ?? '',
    );
    final heightController = TextEditingController(
      text: appointment.heightCm?.toString() ?? '',
    );
    bool isSaving = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Record Vitals'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: bpController,
                  decoration: const InputDecoration(
                    labelText: 'Blood Pressure',
                    hintText: 'e.g. 120/80',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: tempController,
                  decoration: const InputDecoration(
                    labelText: 'Temperature (°C)',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: heartRateController,
                  decoration: const InputDecoration(
                    labelText: 'Heart Rate (bpm)',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: weightController,
                  decoration: const InputDecoration(
                    labelText: 'Weight (kg)',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: heightController,
                  decoration: const InputDecoration(
                    labelText: 'Height (cm)',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
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
                      // All fields are optional — a doctor may only record
                      // what's relevant for this visit. Empty fields are
                      // simply not sent, not saved as invalid data.
                      final bp = bpController.text.trim();
                      final temp = double.tryParse(tempController.text.trim());
                      final hr = int.tryParse(heartRateController.text.trim());
                      final weight = double.tryParse(weightController.text.trim());
                      final height = double.tryParse(heightController.text.trim());

                      final nothingEntered = bp.isEmpty &&
                          temp == null &&
                          hr == null &&
                          weight == null &&
                          height == null;

                      if (nothingEntered) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Enter at least one vital before saving'),
                            backgroundColor: AppTheme.errorColor,
                          ),
                        );
                        return;
                      }

                      setDialogState(() => isSaving = true);

                      final appointmentProvider =
                          Provider.of<AppointmentProvider>(context, listen: false);
                      final success = await appointmentProvider.saveVitals(
                        appointmentId: appointment.id,
                        bloodPressure: bp.isEmpty ? null : bp,
                        temperatureCelsius: temp,
                        heartRateBpm: hr,
                        weightKg: weight,
                        heightCm: height,
                      );

                      if (!context.mounted) return;

                      if (success) {
                        Navigator.of(context).pop();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Vitals saved successfully!'),
                            backgroundColor: AppTheme.successColor,
                          ),
                        );
                        _refreshAppointments();
                      } else {
                        setDialogState(() => isSaving = false);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              appointmentProvider.errorMessage ?? 'Failed to save vitals',
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
                  : const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  void _showPrescriptionDialog(Appointment appointment) {
    final prescriptionController = TextEditingController(text: appointment.prescription ?? '');
    final diagnosisController = TextEditingController(text: appointment.diagnosis ?? '');
    bool isSaving = false;
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
        title: const Text('Add Prescription'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: diagnosisController,
              decoration: const InputDecoration(
                labelText: 'Diagnosis',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: prescriptionController,
              decoration: const InputDecoration(
                labelText: 'Prescription',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
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
                    final diagnosis = diagnosisController.text.trim();
                    final prescription = prescriptionController.text.trim();

                    if (diagnosis.isEmpty || prescription.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Please fill in both diagnosis and prescription'),
                          backgroundColor: AppTheme.errorColor,
                        ),
                      );
                      return;
                    }

                    setDialogState(() => isSaving = true);

                    final appointmentProvider =
                        Provider.of<AppointmentProvider>(context, listen: false);
                    final success = await appointmentProvider.saveDiagnosisAndPrescription(
                      appointmentId: appointment.id,
                      diagnosis: diagnosis,
                      prescription: prescription,
                    );

                    if (!context.mounted) return;

                    if (success) {
                      Navigator.of(context).pop();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Prescription saved successfully!'),
                          backgroundColor: AppTheme.successColor,
                        ),
                      );
                      _refreshAppointments();
                    } else {
                      setDialogState(() => isSaving = false);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            appointmentProvider.errorMessage ?? 'Failed to save prescription',
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
                : const Text('Save'),
          ),
        ],
        ),
      ),
    );
  }

  Future<void> _refreshAppointments() async {
    _loadAppointments();
  }
}