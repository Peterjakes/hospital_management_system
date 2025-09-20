import 'package:flutter/material.dart';
import 'package:hospital_management_system/const/app_theme.dart';
import 'package:provider/provider.dart';
import 'package:hospital_management_system/providers/auth_provider.dart';
import 'package:hospital_management_system/screens/auth/login_screen.dart';
import 'package:hospital_management_system/screens/doctor/doctor_dashboard.dart';
import 'package:hospital_management_system/screens/doctor/doctor_appointments_screen.dart';
import 'package:hospital_management_system/screens/doctor/doctor_patients_screen.dart';
import 'package:hospital_management_system/screens/doctor/doctor_profile_screen.dart';

/// Root screen for doctor with bottom navigation
class DoctorRootScreen extends StatefulWidget {
  const DoctorRootScreen({super.key});

  @override
  State<DoctorRootScreen> createState() => _DoctorRootScreenState();
}

class _DoctorRootScreenState extends State<DoctorRootScreen> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    const DoctorDashboard(),
    const DoctorAppointmentsScreen(),
    const DoctorPatientsScreen(),
    const DoctorProfileScreen(),
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
        title: const Text('Doctor Portal'),
        backgroundColor: AppTheme.doctorColor,
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
        selectedItemColor: AppTheme.doctorColor,
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
      ),
    );
  }
}