import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:hospital_management_system/providers/appointment_provider.dart';
import 'package:hospital_management_system/providers/auth_provider.dart';
import 'package:hospital_management_system/models/appointment_model.dart';


class DoctorAppointmentsScreen extends StatefulWidget {
  const DoctorAppointmentsScreen({super.key});

  @override
  State<DoctorAppointmentsScreen> createState() => _DoctorAppointmentsScreenState();
}

class _DoctorAppointmentsScreenState extends State<DoctorAppointmentsScreen> {
  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadAppointments());
  }

  void _loadAppointments() {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final apptProvider = Provider.of<AppointmentProvider>(context, listen: false);
    if (auth.currentUserId != null) {
      apptProvider.loadDoctorAppointments(auth.currentUserId!, date: _selectedDate);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppointmentProvider>(
      builder: (context, apptProvider, _) {
        if (apptProvider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }
        final appointments = apptProvider.doctorAppointments;
        return Column(
          children: [
            _buildDateSelector(),
            Expanded(
              child: appointments.isEmpty
                  ? _buildEmptyState()
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: appointments.length,
                      itemBuilder: (_, i) => _buildAppointmentCard(appointments[i]),
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
      child: Row(
        children: [
          Expanded(
            child: Text(
              'Appointments for ${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
          ),
          IconButton(onPressed: _selectDate, icon: const Icon(Icons.calendar_today)),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.calendar_today, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text('No Appointments', style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 8),
          const Text('No appointments scheduled for this date'),
        ],
      ),
    );
  }

  Widget _buildAppointmentCard(Appointment appt) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Text('Reason: ${appt.reasonForVisit}'),
      ),
    );
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime.now().add(const Duration(days: 30)),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() => _selectedDate = picked);
      _loadAppointments();
    }
  }
}
