import 'package:flutter/material.dart';
import 'package:hospital_management_system/const/app_theme.dart';
import 'package:provider/provider.dart';
import 'package:hospital_management_system/providers/patient_provider.dart';

class DoctorPatientsScreen extends StatefulWidget {
  const DoctorPatientsScreen({super.key});

  @override
  State<DoctorPatientsScreen> createState() => _DoctorPatientsScreenState();
}

class _DoctorPatientsScreenState extends State<DoctorPatientsScreen> {
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<PatientProvider>(context, listen: false).loadPatients(limit: 50);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<PatientProvider>(
      builder: (context, provider, _) {
        if (provider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }
        final patients = provider.filteredPatients;
        return Column(
          children: [
            _buildSearchBar(provider),
            Expanded(
              child: patients.isEmpty
                  ? _buildEmptyState()
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: patients.length,
                      itemBuilder: (_, i) => _buildPatientCard(patients[i]),
                    ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSearchBar(PatientProvider provider) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Search patients...',
          prefixIcon: const Icon(Icons.search),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
        onChanged: provider.searchPatients,
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.people_outline, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 16),
          const Text('No Patients Found'),
        ],
      ),
    );
  }

  Widget _buildPatientCard(patient) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: AppTheme.patientColor,
          child: Text(patient.firstName[0]),
        ),
        title: Text(patient.fullName, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text('Age: ${patient.age} • ${patient.gender}'),
      ),
    );
  }
}
