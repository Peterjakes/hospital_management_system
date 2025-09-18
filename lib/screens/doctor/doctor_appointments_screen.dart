import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:hospital_management_system/providers/appointment_provider.dart';
import 'package:hospital_management_system/providers/auth_provider.dart';

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
                  ? const Center(child: Text('No appointments'))
                  : ListView.builder(
                      itemCount: appointments.length,
                      itemBuilder: (_, i) => ListTile(
                        title: Text('Appt ${appointments[i].id}'),
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
      child: Row(
        children: [
          Expanded(
            child: Text(
              'Appointments for ${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
          ),
          IconButton(
            onPressed: _selectDate,
            icon: const Icon(Icons.calendar_today),
          ),
        ],
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
