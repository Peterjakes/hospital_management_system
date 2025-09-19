import 'package:flutter/material.dart';
import 'package:hospital_management_system/const/app_theme.dart';
import 'package:provider/provider.dart';
import 'package:hospital_management_system/providers/patient_provider.dart';
import 'package:hospital_management_system/providers/doctor_provider.dart';


class AdminUsersScreen extends StatefulWidget {
  const AdminUsersScreen({super.key});

  @override
  State<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends State<AdminUsersScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<PatientProvider>(context, listen: false).loadPatients();
      Provider.of<DoctorProvider>(context, listen: false).loadDoctors();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildHeader(),
        TabBar(
          controller: _tabController,
          labelColor: AppTheme.adminColor,
          indicatorColor: AppTheme.adminColor,
          tabs: const [
            Tab(text: 'Patients', icon: Icon(Icons.people)),
            Tab(text: 'Doctors', icon: Icon(Icons.medical_services)),
          ],
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              Container(), // patients tab placeholder
              Container(), // doctors tab placeholder
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('User Management',
              style: Theme.of(context)
                  .textTheme
                  .headlineSmall
                  ?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text('Manage patients and doctors in the system',
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: AppTheme.textSecondary)),
          const SizedBox(height: 16),
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search users...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
