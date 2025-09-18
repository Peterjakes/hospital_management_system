import 'package:flutter/material.dart';
import 'package:hospital_management_system/const/app_theme.dart';
import 'package:provider/provider.dart';
import 'package:hospital_management_system/providers/auth_provider.dart';
import 'package:hospital_management_system/providers/appointment_provider.dart';
import 'package:hospital_management_system/screens/auth/login_screen.dart';
import 'package:hospital_management_system/screens/patient/book_appointment_screen.dart';
import 'package:hospital_management_system/screens/patient/appointments_screen.dart';

// Patient dashboard screen with appointment management
class PatientDashboard extends StatefulWidget {
  const PatientDashboard({super.key});

  @override
  State<PatientDashboard> createState() => _PatientDashboardState();
}

class _PatientDashboardState extends State<PatientDashboard> {
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    // Load patient appointments when dashboard initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final appointmentProvider = Provider.of<AppointmentProvider>(context, listen: false);
      
      if (authProvider.currentUserId != null) {
        appointmentProvider.loadPatientAppointments(authProvider.currentUserId!);
      }
    });
  }

  // Handle logout functionality
  Future<void> _handleLogout() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    await authProvider.signOut();
    
    if (!mounted) return;
    
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => const LoginScreen()),
    );
  }

  // Show print demo for patient documents
  void _showPrintDemo() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Print Patient Documents'),
        content: const Text(
          'This demonstrates the printing functionality for patients. '
          'You can print:\n\n'
          '• Appointment receipts\n'
          '• Prescription documents\n'
          '• Medical history reports\n'
          '• Insurance forms',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Patient documents printed successfully!'),
                  backgroundColor: AppTheme.successColor,
                ),
              );
            },
            child: const Text('Print'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Patient Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.print),
            onPressed: _showPrintDemo,
            tooltip: 'Print Documents',
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _handleLogout,
            tooltip: 'Logout',
          ),
        ],
      ),
      body: _buildBody(),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  // Built main body content based on selected tab
  Widget _buildBody() {
    switch (_selectedIndex) {
      case 0:
        return _buildDashboardContent();
      case 1:
        return const AppointmentsScreen();
      case 2:
        return _buildRecordsContent();
      case 3:
        return _buildProfileContent();
      default:
        return _buildDashboardContent();
    }
  }

  //Build dashboard overview content
  Widget _buildDashboardContent() {
    return Consumer2<AuthProvider, AppointmentProvider>(
      builder: (context, authProvider, appointmentProvider, child) {
        final upcomingAppointments = appointmentProvider.upcomingAppointments;
        final totalAppointments = appointmentProvider.patientAppointments.length;
        
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Welcome card
              Card(
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [AppTheme.patientColor, AppTheme.secondaryColorDark],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Welcome back,',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: Colors.white70,
                        ),
                      ),
                      Text(
                        '${authProvider.currentUserData?['firstName'] ?? 'Patient'}',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'How are you feeling today?',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 20),
              
              // Quick stats
              Text(
                'Quick Overview',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      'Next Appointment', 
                      upcomingAppointments.isNotEmpty 
                          ? upcomingAppointments.first.formattedDateTime
                          : 'No upcoming appointments', 
                      Icons.schedule, 
                      AppTheme.primaryColor
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatCard(
                      'Total Appointments', 
                      totalAppointments.toString(), 
                      Icons.history, 
                      AppTheme.secondaryColor
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 20),
              
              // Quick actions
              Text(
                'Quick Actions',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              
              Row(
                children: [
                  Expanded(
                    child: _buildActionCard(
                      'Book Appointment',
                      Icons.add,
                      AppTheme.primaryColor,
                      () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => const BookAppointmentScreen(),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildActionCard(
                      'View Records',
                      Icons.folder,
                      AppTheme.secondaryColor,
                      () {
                        setState(() {
                          _selectedIndex = 2;
                        });
                      },
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 20),
              
              // Recent Appointments
              if (appointmentProvider.patientAppointments.isNotEmpty) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Recent Appointments',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        setState(() {
                          _selectedIndex = 1;
                        });
                      },
                      child: const Text('View All'),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ...appointmentProvider.patientAppointments
                    .take(3)
                    .map((appointment) => _buildAppointmentPreviewCard(appointment)),
              ],
            ],
          ),
        );
      },
    );
  }

  /// Build appointment preview card for dashboard
  Widget _buildAppointmentPreviewCard(appointment) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppTheme.getStatusColor(appointment.status.value).withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            Icons.calendar_today,
            color: AppTheme.getStatusColor(appointment.status.value),
          ),
        ),
        title: Text(appointment.formattedDateTime),
        subtitle: Text(appointment.reasonForVisit),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: AppTheme.getStatusColor(appointment.status.value),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            appointment.status.displayName,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        onTap: () {
          setState(() {
            _selectedIndex = 1;
          });
        },
      ),
    );
  }

  /// Build stat card widget
  /// Learning: Reusable widget creation
  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              value,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              title,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppTheme.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  // Build action card widget
  Widget _buildActionCard(String title, IconData icon, Color color, VoidCallback onTap) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Icon(icon, color: color, size: 32),
              const SizedBox(height: 8),
              Text(
                title,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Placeholder content for other tabs
  Widget _buildRecordsContent() {
    return const Center(
      child: Text('Medical Records screen '),
    );
  }

  Widget _buildProfileContent() {
    return const Center(
      child: Text('Profile screen '),
    );
  }

  // Build bottom navigation bar
  Widget _buildBottomNavigationBar() {
    return BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      currentIndex: _selectedIndex,
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
    );
  }
}