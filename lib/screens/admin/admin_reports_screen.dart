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
        return const Scaffold(
          body: Center(child: Text('Reports & Analytics')),
        );
      },
    );
  }
}
