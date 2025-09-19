import 'package:flutter/material.dart';
import 'package:hospital_management_system/const/app_theme.dart';
import 'package:provider/provider.dart';
import 'package:hospital_management_system/providers/auth_provider.dart';
import 'package:hospital_management_system/providers/patient_provider.dart';


/// Medical records screen for patients
class MedicalRecordsScreen extends StatefulWidget {
  const MedicalRecordsScreen({super.key});

  @override
  State<MedicalRecordsScreen> createState() => _MedicalRecordsScreenState();
}

class _MedicalRecordsScreenState extends State<MedicalRecordsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final patientProvider = Provider.of<PatientProvider>(context, listen: false);
      
      if (authProvider.currentUserId != null) {
        patientProvider.getPatient(authProvider.currentUserId!);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<AuthProvider, PatientProvider>(
      builder: (context, authProvider, patientProvider, child) {
        if (patientProvider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        final patient = patientProvider.selectedPatient;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Text(
                'Medical Records',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Your complete medical history and information',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.textSecondary,
                ),
              ),
              const SizedBox(height: 24),

              // Basic Information Card
              _buildBasicInfoCard(patient),
              const SizedBox(height: 16),

              // Medical Information Card
              _buildMedicalInfoCard(patient),
              const SizedBox(height: 16),

              // Emergency Contact Card
              _buildEmergencyContactCard(patient),
              const SizedBox(height: 16),

              // Insurance Information Card
              if (patient?.hasInsurance == true)
                _buildInsuranceCard(patient!),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBasicInfoCard(patient) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.person, color: AppTheme.patientColor),
                const SizedBox(width: 8),
                Text(
                  'Basic Information',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (patient != null) ...[
              _buildInfoRow('Full Name', patient.fullName),
              _buildInfoRow('Age', '${patient.age} years'),
              _buildInfoRow('Gender', patient.gender),
              _buildInfoRow('Date of Birth', patient.formattedDateOfBirth),
              _buildInfoRow('Phone', patient.phoneNumber),
              _buildInfoRow('Email', patient.email),
              _buildInfoRow('Address', patient.address),
            ] else
              const Text('Loading patient information...'),
          ],
        ),
      ),
    );
  }

  Widget _buildMedicalInfoCard(patient) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.medical_services, color: AppTheme.errorColor),
                const SizedBox(width: 8),
                Text(
                  'Medical Information',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (patient != null) ...[
              _buildInfoRow('Blood Group', patient.bloodGroup),
              if (patient.hasAllergies) ...[
                const SizedBox(height: 8),
                Text(
                  'Allergies:',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Wrap(
                  spacing: 8,
                  children: patient.allergies.map<Widget>((allergy) {
                    return Chip(
                      label: Text(allergy),
                      backgroundColor: AppTheme.errorColor.withOpacity(0.1),
                      side: BorderSide(color: AppTheme.errorColor),
                    );
                  }).toList(),
                ),
              ] else
                _buildInfoRow('Allergies', 'None recorded'),
              
              if (patient.hasMedicalHistory) ...[
                const SizedBox(height: 16),
                Text(
                  'Medical History:',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                ...patient.medicalHistory.map((history) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('• '),
                        Expanded(child: Text(history)),
                      ],
                    ),
                  );
                }),
              ] else
                _buildInfoRow('Medical History', 'None recorded'),
            ] else
              const Text('Loading medical information...'),
          ],
        ),
      ),
    );
  }

  Widget _buildEmergencyContactCard(patient) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.contact_emergency, color: AppTheme.warningColor),
                const SizedBox(width: 8),
                Text(
                  'Emergency Contact',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (patient != null) ...[
              _buildInfoRow('Contact Name', patient.emergencyContactName),
              _buildInfoRow('Contact Phone', patient.emergencyContactPhone),
            ] else
              const Text('Loading emergency contact...'),
          ],
        ),
      ),
    );
  }

  Widget _buildInsuranceCard(patient) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.security, color: AppTheme.primaryColor),
                const SizedBox(width: 8),
                Text(
                  'Insurance Information',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildInfoRow('Insurance Provider', patient.insuranceProvider ?? 'N/A'),
            _buildInfoRow('Policy Number', patient.insuranceNumber ?? 'N/A'),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: AppTheme.textSecondary,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }
}