import 'package:flutter/material.dart';
import 'package:hospital_management_system/const/app_theme.dart';
import 'package:provider/provider.dart';
import 'package:hospital_management_system/providers/auth_provider.dart';
import 'package:hospital_management_system/screens/auth/login_screen.dart';

/// Admin dashboard screen for system administration
class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  int _selectedIndex = 0;

  // logout
  Future<void> _handleLogout() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    await authProvider.signOut();
    
    if (!mounted) return;
    
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => const LoginScreen()),
    );
  }

  // Show comprehensive system reports printing demo
  void _showPrintSystemReports() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.assessment, color: AppTheme.adminColor),
            const SizedBox(width: 8),
            const Text('System Reports'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Generate comprehensive system reports:',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            _buildReportOption('📊 Patient Statistics', 'Demographics, age groups, medical data'),
            _buildReportOption('📅 Appointment Reports', 'Daily, weekly, monthly summaries'),
            _buildReportOption('👨‍⚕️ Doctor Performance', 'Ratings, appointments, availability'),
            _buildReportOption('💰 Financial Summary', 'Revenue, payments, outstanding fees'),
            _buildReportOption('📈 System Analytics', 'Usage patterns, peak times'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.of(context).pop();
              _simulateReportGeneration();
            },
            icon: const Icon(Icons.print),
            label: const Text('Generate & Print'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.adminColor,
            ),
          ),
        ],
      ),
    );
  }

  // Build report option widget
  Widget _buildReportOption(String title, String description) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              description,
              style: TextStyle(
                fontSize: 12,
                color: AppTheme.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Simulate report generation process
  void _simulateReportGeneration() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(AppTheme.adminColor),
            ),
            const SizedBox(height: 16),
            const Text('Generating system reports...'),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              backgroundColor: AppTheme.adminColor.withOpacity(0.2),
              valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.adminColor),
            ),
          ],
        ),
      ),
    );

    Future.delayed(const Duration(seconds: 3), () {
      Navigator.of(context).pop();
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ System reports generated and sent to printer!'),
          backgroundColor: AppTheme.successColor,
          duration: Duration(seconds: 3),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        backgroundColor: AppTheme.adminColor,
        actions: [
          IconButton(
            icon: const Icon(Icons.print),
            onPressed: _showPrintSystemReports,
            tooltip: 'Print System Reports',
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

  // main body content based on selected tab
  Widget _buildBody() {
    switch (_selectedIndex) {
      case 0:
        return _buildDashboardContent();
      case 1:
        return _buildUsersContent();
      case 2:
        return _buildDepartmentsContent();
      case 3:
        return _buildReportsContent();
      default:
        return _buildDashboardContent();
    }
  }

  // admin dashboard overview
  Widget _buildDashboardContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Admin welcome card
          _buildAdminWelcomeCard(),
          
          const SizedBox(height: 20),
          
          // System statistics
          _buildSystemStats(),
          
          const SizedBox(height: 20),
          
          // Quick admin actions
          _buildQuickActions(),
          
          const SizedBox(height: 20),
          
          // Recent system activities
          _buildRecentActivities(),
        ],
      ),
    );
  }

  // admin welcome card
  Widget _buildAdminWelcomeCard() {
    return Card(
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [AppTheme.adminColor, AppTheme.adminColor.withOpacity(0.8)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'System Administrator',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Colors.white70,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Hospital Management System',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  Icons.circle,
                  color: AppTheme.successColor,
                  size: 12,
                ),
                const SizedBox(width: 8),
                Text(
                  'System Status: Online',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // system statistics section
  Widget _buildSystemStats() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'System Overview',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'Total Patients',
                '1,234',
                Icons.people,
                AppTheme.patientColor,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                'Active Doctors',
                '45',
                Icons.medical_services,
                AppTheme.doctorColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'Appointments Today',
                '89',
                Icons.calendar_today,
                AppTheme.appointmentColor,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                'Departments',
                '12',
                Icons.business,
                AppTheme.primaryColor,
              ),
            ),
          ],
        ),
      ],
    );
  }

  // individual stat card
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
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
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

  // quick actions section
  Widget _buildQuickActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
                'Print Reports',
                Icons.print,
                AppTheme.adminColor,
                _showPrintSystemReports,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildActionCard(
                'Manage Users',
                Icons.admin_panel_settings,
                AppTheme.primaryColor,
                () {
                  setState(() {
                    _selectedIndex = 1;
                  });
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  // action card widget
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

  // recent activities section
  Widget _buildRecentActivities() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Recent Activities',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Card(
          child: Column(
            children: [
              _buildActivityItem(
                'New patient registered',
                'John Doe joined the system',
                Icons.person_add,
                AppTheme.successColor,
                '2 minutes ago',
              ),
              const Divider(height: 1),
              _buildActivityItem(
                'Doctor updated schedule',
                'Dr. Smith modified availability',
                Icons.schedule,
                AppTheme.warningColor,
                '15 minutes ago',
              ),
              const Divider(height: 1),
              _buildActivityItem(
                'System report generated',
                'Monthly analytics completed',
                Icons.assessment,
                AppTheme.adminColor,
                '1 hour ago',
              ),
            ],
          ),
        ),
      ],
    );
  }

  // individual activity item
  Widget _buildActivityItem(
    String title,
    String subtitle,
    IconData icon,
    Color color,
    String time,
  ) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: color.withOpacity(0.1),
        child: Icon(icon, color: color, size: 20),
      ),
      title: Text(
        title,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: Text(subtitle),
      trailing: Text(
        time,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: AppTheme.textSecondary,
        ),
      ),
    );
  }

  // Placeholder content for other admin sections
  Widget _buildUsersContent() {
    return const Center(
      child: Text('User management screen '),
    );
  }

  Widget _buildDepartmentsContent() {
    return const Center(
      child: Text('Department management '),
    );
  }

  Widget _buildReportsContent() {
    return const Center(
      child: Text('Advanced reports '),
    );
  }

  // bottom navigation bar
  Widget _buildBottomNavigationBar() {
    return BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      currentIndex: _selectedIndex,
      selectedItemColor: AppTheme.adminColor,
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
          icon: Icon(Icons.people),
          label: 'Users',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.business),
          label: 'Departments',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.assessment),
          label: 'Reports',
        ),
      ],
    );
  }
}