import 'package:flutter/material.dart';
import 'package:hospital_management_system/const/app_theme.dart';
import 'package:provider/provider.dart';
import 'package:hospital_management_system/providers/auth_provider.dart';
import 'package:hospital_management_system/screens/auth/login_screen.dart';
import 'package:hospital_management_system/screens/patient/patient_dashboard.dart';
import 'package:hospital_management_system/screens/patient/appointments_screen.dart';
import 'package:hospital_management_system/screens/patient/medical_records_screen.dart';
import 'package:hospital_management_system/screens/patient/patient_profile_screen.dart';

/// Root screen for patient with bottom navigation
class PatientRootScreen extends StatefulWidget {
  const PatientRootScreen({super.key});

  @override
  State<PatientRootScreen> createState() => _PatientRootScreenState();
}

class _PatientRootScreenState extends State<PatientRootScreen> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    const PatientDashboard(),
    const AppointmentsScreen(),
    const MedicalRecordsScreen(),
    const PatientProfileScreen(),
  ];

  // Handle logout functionality
  Future<void> _handleLogout() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    await authProvider.signOut();
    
    if (!mounted) return;
    
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => const LoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Patient Portal'),
        backgroundColor: AppTheme.patientColor,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _handleLogout,
            tooltip: 'Logout',
          ),
        ],
      ),
      body: IndexedStack(
        index: _selectedIndex,
        children: _screens,
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _selectedIndex,
        selectedItemColor: AppTheme.patientColor,
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
            icon: Icon(Icons.folder),
            label: 'Records',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}