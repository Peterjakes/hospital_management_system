import 'package:flutter/material.dart';
import 'package:hospital_management_system/const/app_theme.dart';
import 'package:hospital_management_system/providers/doctor_provider.dart'; 
import 'package:hospital_management_system/widgets/custom_text_field.dart'; 
import 'package:provider/provider.dart';

class BookAppointmentScreen extends StatefulWidget {
  const BookAppointmentScreen({super.key});

  @override
  State<BookAppointmentScreen> createState() => _BookAppointmentScreenState();
}

class _BookAppointmentScreenState extends State<BookAppointmentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _reasonController = TextEditingController();

  String? _selectedDoctorId;
  String? _selectedSpecialization;
  DateTime? _selectedDate;
  String? _selectedTime;
  Doctor? _selectedDoctor;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<DoctorProvider>(context, listen: false).loadDoctors();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Book Appointment'),
        backgroundColor: AppTheme.primaryColor,
      ),
      body: Consumer<DoctorProvider>(
        builder: (context, doctorProvider, child) {
          if (doctorProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          return Form(
            key: _formKey,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Select Specialization',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  _buildSpecializationFilter(doctorProvider),
                  const SizedBox(height: 20),
                  if (_selectedDoctor != null) ...[
                    Text(
                      'Select Date',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    _buildDateSelection(),
                    const SizedBox(height: 20),
                    if (_selectedDate != null) ...[
                      Text(
                        'Select Time',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      _buildTimeSelection(),
                      const SizedBox(height: 20),
                      Text(
                        'Reason for Visit',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      CustomTextField(
                        labelText: 'Enter reason for visit',
                        controller: _reasonController,
                        maxLines: 3,
                      ),
                    ],
                  ],
                  Text(
                    'Select Doctor',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: ListView.builder(
                      itemCount: doctorProvider.filteredDoctors.length,
                      itemBuilder: (context, index) {
                        return _buildDoctorCard(doctorProvider.filteredDoctors[index]);
                      },
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSpecializationFilter(DoctorProvider doctorProvider) {
    return DropdownButtonFormField<String>(
      value: _selectedSpecialization,
      items: [
        const DropdownMenuItem<String>(
          value: null,
          child: Text('All Specializations'),
        ),
        ...doctorProvider.specializations.map(
          (spec) => DropdownMenuItem(value: spec, child: Text(spec)),
        ),
      ],
      onChanged: (value) {
        setState(() {
          _selectedSpecialization = value;
          _selectedDoctorId = null;
        });
        value != null
            ? doctorProvider.filterBySpecialization(value)
            : doctorProvider.clearFilters();
      },
    );
  }

  Widget _buildDoctorCard(Doctor doctor) {
    final isSelected = _selectedDoctorId == doctor.id;
    return Card(
      child: ListTile(
        title: Text('Dr. ${doctor.fullName}'),
        subtitle: Text(doctor.specialization),
        trailing: isSelected ? const Icon(Icons.check_circle) : null,
        onTap: () {
          setState(() {
            _selectedDoctorId = doctor.id;
            _selectedDoctor = doctor;
          });
        },
      ),
    );
  }

  Widget _buildDateSelection() {
    return CustomTextField(
      labelText: 'Appointment Date',
      prefixIcon: Icons.calendar_today,
      readOnly: true,
      controller: TextEditingController(
        text: _selectedDate != null
            ? '${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}'
            : '',
      ),
      onTap: _selectDate,
    );
  }

  Widget _buildTimeSelection() {
    final slots = _selectedDoctor!.getAvailableTimeSlots();
    return Wrap(
      spacing: 8,
      children: slots.map((time) {
        final isSelected = _selectedTime == time;
        return GestureDetector(
          onTap: () => setState(() => _selectedTime = time),
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isSelected ? AppTheme.primaryColor : Colors.transparent,
              border: Border.all(color: AppTheme.primaryColor),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(time),
          ),
        );
      }).toList(),
    );
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now().add(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 30)),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        _selectedTime = null; // Reset time selection when date changes
      });
    }
  }

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }
}