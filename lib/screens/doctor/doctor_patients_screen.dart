import 'package:flutter/material.dart';
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
      builder: (context, patientProvider, child) {
        if (patientProvider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }
        final patients = patientProvider.filteredPatients;
        return Column(
          children: [
            _buildSearchBar(patientProvider),
            Expanded(
              child: patients.isEmpty
                  ? const Center(child: Text('No patients'))
                  : ListView.builder(
                      itemCount: patients.length,
                      itemBuilder: (context, i) => ListTile(
                        title: Text(patients[i].fullName),
                      ),
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
}
