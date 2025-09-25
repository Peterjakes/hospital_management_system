import 'package:flutter/material.dart';
import 'package:hospital_management_system/const/app_theme.dart';
import 'package:hospital_management_system/screens/patient/appointments_screen.dart';
import 'package:provider/provider.dart';
import 'package:hospital_management_system/providers/appointment_provider.dart';
import 'package:hospital_management_system/providers/doctor_provider.dart';
import 'package:hospital_management_system/providers/auth_provider.dart';
import 'package:hospital_management_system/models/doctor_model.dart';
import 'package:hospital_management_system/widgets/custom_text_field.dart';
import 'package:hospital_management_system/widgets/custom_button.dart';
import 'package:hospital_management_system/services/mpesa_service.dart';

class BookAppointmentScreen extends StatefulWidget {
  const BookAppointmentScreen({super.key});

  @override
  State<BookAppointmentScreen> createState() => _BookAppointmentScreenState();
}

class _BookAppointmentScreenState extends State<BookAppointmentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _reasonController = TextEditingController();
  final _phoneController = TextEditingController();
  
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
  void dispose() {
    _reasonController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Book Appointment'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
      ),
      body: Consumer3<DoctorProvider, AppointmentProvider, AuthProvider>(
        builder: (context, doctorProvider, appointmentProvider, authProvider, child) {
          // Show success modal when payment is successful
          if (appointmentProvider.paymentStatus == 'Payment successful! Appointment booked.') {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _showSuccessModal(context);
              appointmentProvider.stopPaymentPolling(); // Clear status
            });
          }

          if (doctorProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Book New Appointment',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Select a doctor and preferred time for your appointment',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 24),

                  _buildSpecializationFilter(doctorProvider),
                  const SizedBox(height: 16),
                  _buildDoctorSelection(doctorProvider),
                  const SizedBox(height: 16),

                  if (_selectedDoctor != null) ...[
                    _buildDateSelection(),
                    const SizedBox(height: 16),
                  ],

                  if (_selectedDate != null && _selectedDoctor != null) ...[
                    _buildTimeSelection(),
                    const SizedBox(height: 16),
                  ],

                  if (_selectedTime != null) ...[
                    CustomTextField(
                      controller: _reasonController,
                      labelText: 'Reason for Visit',
                      hintText: 'Describe your symptoms or reason for consultation',
                      prefixIcon: Icons.medical_services,
                      maxLines: 3,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please provide a reason for your visit';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    CustomTextField(
                      controller: _phoneController,
                      labelText: 'M-Pesa Phone Number',
                      hintText: '0712345678',
                      prefixIcon: Icons.phone,
                      keyboardType: TextInputType.phone,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter your M-Pesa phone number';
                        }
                        if (!MpesaService.isValidKenyanPhoneNumber(value.trim())) {
                          return 'Please enter a valid Kenyan phone number';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),

                    _buildAppointmentSummary(),
                    const SizedBox(height: 24),

                    // Payment status card
                    if (appointmentProvider.isPaymentPolling)
                      _buildPaymentStatusCard(appointmentProvider),

                    const SizedBox(height: 16),

                    // Book button
                    CustomButton(
                      text: appointmentProvider.isPaymentPolling 
                          ? 'Processing Payment...' 
                          : 'Pay & Book Appointment',
                      isLoading: appointmentProvider.isLoading || appointmentProvider.isPaymentPolling,
                      onPressed: appointmentProvider.isPaymentPolling 
                          ? null 
                          : () => _bookAppointment(appointmentProvider, authProvider),
                      width: double.infinity,
                      icon: Icons.payment,
                    ),

                    if (appointmentProvider.errorMessage != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 16),
                        child: Card(
                          color: AppTheme.errorColor.withOpacity(0.1),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Text(
                              appointmentProvider.errorMessage!,
                              style: TextStyle(color: AppTheme.errorColor),
                            ),
                          ),
                        ),
                      ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildPaymentStatusCard(AppointmentProvider provider) {
    return Card(
      color: Colors.orange.withOpacity(0.1),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const CircularProgressIndicator(color: Colors.orange),
            const SizedBox(height: 12),
            const Text(
              'Processing Payment',
              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.orange),
            ),
            const SizedBox(height: 8),
            Text(
              provider.paymentStatus ?? 'Please check your phone for M-Pesa prompt',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _bookAppointment(AppointmentProvider appointmentProvider, AuthProvider authProvider) async {
    if (!_formKey.currentState!.validate()) return;

    final phoneNumber = MpesaService.formatPhoneNumberForMpesa(_phoneController.text.trim());
    
    final result = await appointmentProvider.bookAppointmentWithPayment(
      patientId: authProvider.currentUserId!,
      doctorId: _selectedDoctorId!,
      departmentId: _selectedDoctor!.departmentId,
      appointmentDate: _selectedDate!,
      appointmentTime: _selectedTime!,
      reasonForVisit: _reasonController.text.trim(),
      consultationFee: _selectedDoctor!.consultationFee,
      phoneNumber: phoneNumber,
    );

    if (!mounted) return;

    if (!result['success']) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['error'] ?? 'Failed to book appointment'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    }
  }

  void _showSuccessModal(BuildContext context) {
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: const BoxDecoration(
              color: Colors.green,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check,
              color: Colors.white,
              size: 40,
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Appointment Booked!',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            'Your appointment with Dr. ${_selectedDoctor!.fullName} has been successfully booked.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey[600]),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () async {
                    Navigator.of(context).pop(); // Close dialog

                    final appointmentProvider = Provider.of<AppointmentProvider>(
                      context,
                      listen: false,
                    );
                    final authProvider = Provider.of<AuthProvider>(
                      context,
                      listen: false,
                    );

                    if (authProvider.currentUserId != null) {
                      await appointmentProvider.loadPatientAppointments(authProvider.currentUserId!);
                    }

                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const AppointmentsScreen(),
                      ),
                    );
                  },
                  child: const Text('My Appointments'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop(); // Close dialog
                    Navigator.of(context).pop(); // Go back to previous screen
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                  ),
                  child: const Text('Done', style: TextStyle(color: Colors.white)),
                ),
              ),
            ],
          ),
        ],
      ),
    ),
  );
}

  Widget _buildSpecializationFilter(DoctorProvider doctorProvider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Filter by Specialization',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: _selectedSpecialization,
          decoration: InputDecoration(
            labelText: 'Select Specialization',
            prefixIcon: const Icon(Icons.medical_services),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          ),
          items: [
            const DropdownMenuItem<String>(
              value: null,
              child: Text('All Specializations'),
            ),
            ...doctorProvider.specializations.map((spec) {
              return DropdownMenuItem<String>(
                value: spec,
                child: Text(spec),
              );
            }),
          ],
          onChanged: (value) {
            setState(() {
              _selectedSpecialization = value;
              _selectedDoctorId = null;
              _selectedDoctor = null;
              _selectedDate = null;
              _selectedTime = null;
            });
            if (value != null) {
              doctorProvider.filterBySpecialization(value);
            } else {
              doctorProvider.clearFilters();
            }
          },
        ),
      ],
    );
  }

  Widget _buildDoctorSelection(DoctorProvider doctorProvider) {
    final doctors = doctorProvider.filteredDoctors;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Select Doctor',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        if (doctors.isEmpty)
          const Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Text('No doctors available for the selected specialization'),
            ),
          )
        else
          ...doctors.map((doctor) => _buildDoctorCard(doctor)),
      ],
    );
  }

  Widget _buildDoctorCard(Doctor doctor) {
    final isSelected = _selectedDoctorId == doctor.id;
    
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: () {
          setState(() {
            _selectedDoctorId = doctor.id;
            _selectedDoctor = doctor;
            _selectedDate = null;
            _selectedTime = null;
          });
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: isSelected 
                ? Border.all(color: AppTheme.primaryColor, width: 2)
                : null,
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 30,
                backgroundColor: AppTheme.doctorColor,
                child: Text(
                  doctor.firstName[0] + doctor.lastName[0],
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Dr. ${doctor.fullName}',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      doctor.specialization,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppTheme.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.star, size: 16, color: Colors.amber),
                        const SizedBox(width: 4),
                        Text(doctor.formattedRating),
                        const SizedBox(width: 16),
                        Text(
                          doctor.formattedFee,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: AppTheme.primaryColor,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (isSelected)
                const Icon(Icons.check_circle, color: AppTheme.primaryColor),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDateSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Select Date',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        CustomTextField(
          labelText: 'Appointment Date',
          prefixIcon: Icons.calendar_today,
          readOnly: true,
          onTap: _selectDate,
          controller: TextEditingController(
            text: _selectedDate != null 
                ? '${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}'
                : '',
          ),
          validator: (value) {
            if (_selectedDate == null) {
              return 'Please select an appointment date';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildTimeSelection() {
    final dayOfWeek = _getDayOfWeek(_selectedDate!);
    final availableSlots = _selectedDoctor!.getAvailableTimeSlots();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Select Time',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        if (!_selectedDoctor!.isAvailableOnDay(dayOfWeek))
          Card(
            color: AppTheme.errorColor.withOpacity(0.1),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Doctor is not available on $dayOfWeek. Please select another date.',
                style: TextStyle(color: AppTheme.errorColor),
              ),
            ),
          )
        else
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: availableSlots.map((time) {
              final isSelected = _selectedTime == time;
              return GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedTime = time;
                  });
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected ? AppTheme.primaryColor : Colors.transparent,
                    border: Border.all(color: AppTheme.primaryColor),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    time,
                    style: TextStyle(
                      color: isSelected ? Colors.white : AppTheme.primaryColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
      ],
    );
  }

  Widget _buildAppointmentSummary() {
    return Card(
      color: AppTheme.primaryColor.withOpacity(0.1),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Appointment Summary',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            _buildSummaryRow('Doctor', 'Dr. ${_selectedDoctor!.fullName}'),
            _buildSummaryRow('Date', '${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}'),
            _buildSummaryRow('Time', _selectedTime!),
            const Divider(),
            _buildSummaryRow(
              'Total Amount', 
              _selectedDoctor!.formattedFee,
              isTotal: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: isTotal ? AppTheme.primaryColor : null,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 30)),
    );
    
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
        _selectedTime = null;
      });
    }
  }

  String _getDayOfWeek(DateTime date) {
    const days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    return days[date.weekday - 1];
  }
}