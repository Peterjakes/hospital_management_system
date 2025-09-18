import 'package:flutter/material.dart';
import 'package:hospital_management_system/const/app_theme.dart';
import 'package:provider/provider.dart';
import 'package:hospital_management_system/providers/patient_provider.dart';

/// Doctor patients screen showing all patients
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
            // Search Bar
            _buildSearchBar(patientProvider),
            
            // Patients List
            Expanded(
              child: patients.isEmpty
                  ? _buildEmptyState()
                  : RefreshIndicator(
                      onRefresh: () => patientProvider.refreshPatients(),
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: patients.length,
                        itemBuilder: (context, index) {
                          return _buildPatientCard(patients[index]);
                        },
                      ),
                    ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSearchBar(PatientProvider patientProvider) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Search patients by name, email, or phone...',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  onPressed: () {
                    _searchController.clear();
                    patientProvider.searchPatients('');
                  },
                  icon: const Icon(Icons.clear),
                )
              : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        onChanged: (value) {
          patientProvider.searchPatients(value);
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.people_outline,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No Patients Found',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'No patients match your search criteria',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey[500],
            ),
          ),
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
          backgroundImage: patient.profileImageUrl != null 
              ? NetworkImage(patient.profileImageUrl!)
              : null,
          child: patient.profileImageUrl == null
              ? Text(
                  '${patient.firstName[0]}${patient.lastName[0]}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                )
              : null,
        ),
        title: Text(
          patient.fullName,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Age: ${patient.age} • ${patient.gender}'),
            Text('Blood Group: ${patient.bloodGroup}'),
            if (patient.hasAllergies)
              Text(
                'Allergies: ${patient.allergies.join(', ')}',
                style: TextStyle(
                  color: AppTheme.errorColor,
                  fontSize: 12,
                ),
              ),
          ],
        ),
        trailing: PopupMenuButton(
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'view',
              child: Row(
                children: [
                  Icon(Icons.visibility, size: 16),
                  SizedBox(width: 8),
                  Text('View Details'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'history',
              child: Row(
                children: [
                  Icon(Icons.history, size: 16),
                  SizedBox(width: 8),
                  Text('Medical History'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'appointments',
              child: Row(
                children: [
                  Icon(Icons.calendar_today, size: 16),
                  SizedBox(width: 8),
                  Text('Appointments'),
                ],
              ),
            ),
          ],
          onSelected: (value) {
            _handlePatientAction(patient, value.toString());
          },
        ),
        onTap: () => _showPatientDetails(patient),
      ),
    );
  }

  void _handlePatientAction(patient, String action) {
    switch (action) {
      case 'view':
        _showPatientDetails(patient);
        break;
      case 'history':
        _showMedicalHistory(patient);
        break;
      case 'appointments':
        _showPatientAppointments(patient);
        break;
    }
  }

  void _showPatientDetails(patient) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Patient Details - ${patient.fullName}'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow('Age', '${patient.age} years'),
              _buildDetailRow('Gender', patient.gender),
              _buildDetailRow('Blood Group', patient.bloodGroup),
              _buildDetailRow('Phone', patient.phoneNumber),
              _buildDetailRow('Email', patient.email),
              _buildDetailRow('Address', patient.address),
              if (patient.hasAllergies) ...[
                const SizedBox(height: 8),
                const Text('Allergies:', style: TextStyle(fontWeight: FontWeight.bold)),
                ...patient.allergies.map((allergy) => Text('• $allergy')),
              ],
              if (patient.hasMedicalHistory) ...[
                const SizedBox(height: 8),
                const Text('Medical History:', style: TextStyle(fontWeight: FontWeight.bold)),
                ...patient.medicalHistory.map((history) => Text('• $history')),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showMedicalHistory(patient) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Medical History - ${patient.fullName}'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (patient.hasMedicalHistory)
                ...patient.medicalHistory.map((history) => 
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text('• $history'),
                  ),
                )
              else
                const Text('No medical history recorded'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showPatientAppointments(patient) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Patient appointments view coming soon!'),
        backgroundColor: AppTheme.warningColor,
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}