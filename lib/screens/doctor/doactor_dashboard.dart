import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:hospital_management_system/providers/auth_provider.dart';
import 'package:hospital_management_system/screens/auth/login_screen.dart';

class DoctorDashboard extends StatefulWidget {
  const DoctorDashboard({super.key});

  @override
  State<DoctorDashboard> createState() => _DoctorDashboardState();
}

class _DoctorDashboardState extends State<DoctorDashboard> {
  int _selectedIndex = 0;

  Future<void> _handleLogout() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    await authProvider.signOut();
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Doctor Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _handleLogout,
            tooltip: 'Logout',
          )
        ],
      ),
      body: _buildBody(),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  Widget _buildBody() {
    switch (_selectedIndex) {
      case 0:
        return _buildDashboardContent();
      case 1:
        return const Center(child: Text('Appointments'));
      case 2:
        return const Center(child: Text('Patients'));
      case 3:
        return const Center(child: Text('Profile'));
      default:
        return const SizedBox();
    }
  }

  Widget _buildDashboardContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.teal, Colors.teal.shade700],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Good morning,', style: TextStyle(color: Colors.white70)),
                  Text('Dr. Smith',
                      style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 20)),
                  SizedBox(height: 8),
                  Text('You have 5 appointments today',
                      style: TextStyle(color: Colors.white70)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          const Text("Today's Appointments",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          const SizedBox(height: 12),
          _buildAppointmentCard('John Doe', '10:00 AM', 'General Checkup'),
          _buildAppointmentCard('Jane Smith', '11:30 AM', 'Follow-up'),
        ],
      ),
    );
  }

  Widget _buildAppointmentCard(String name, String time, String reason) {
    return Card(
      child: ListTile(
        leading: const CircleAvatar(child: Icon(Icons.person)),
        title: Text(name),
        subtitle: Text('$time - $reason'),
      ),
    );
  }

  void _showPrintPrescriptionDemo() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Print Prescription'),
        content: const Text('Generate and print prescription for patient'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              _simulatePrintingProcess();
            },
            icon: const Icon(Icons.print),
            label: const Text('Print'),
          )
        ],
      ),
    );
  }

  void _simulatePrintingProcess() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Generating prescription PDF...'),
          ],
        ),
      ),
    );
    Future.delayed(const Duration(seconds: 2), () {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✅ Prescription sent to printer!')),
      );
    });
  }

  Widget _buildBottomNavigationBar() {
    return BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      currentIndex: _selectedIndex,
      onTap: (index) => setState(() => _selectedIndex = index),
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: 'Dashboard'),
        BottomNavigationBarItem(icon: Icon(Icons.calendar_today), label: 'Appointments'),
        BottomNavigationBarItem(icon: Icon(Icons.people), label: 'Patients'),
        BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
      ],
    );
  }
}