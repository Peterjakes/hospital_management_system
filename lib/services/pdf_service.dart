import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import 'package:hospital_management_system/models/patient_model.dart';
import 'package:hospital_management_system/models/doctor_model.dart';
import 'package:hospital_management_system/models/appointment_model.dart';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Enhanced PDF service for generating, printing, and saving prescriptions
class PDFService {
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Generate a comprehensive prescription PDF as a byte array
  Future<Uint8List> generatePrescriptionPDF({
    required Patient patient,
    required Doctor doctor,
    required Appointment appointment,
  }) async {
    final pdf = pw.Document();

    // Add prescription page
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(20),
        build: (pw.Context context) => [
          // Header with hospital/clinic info
          _buildHeader(),
          pw.SizedBox(height: 20),

          // Doctor information section
          _buildDoctorSection(doctor),
          pw.SizedBox(height: 15),

          // Patient information section  
          _buildPatientSection(patient),
          pw.SizedBox(height: 15),

          // Appointment details section
          _buildAppointmentSection(appointment),
          pw.SizedBox(height: 20),

          // Main prescription content
          _buildPrescriptionContent(appointment),
          pw.SizedBox(height: 30),

          // Footer with signature and instructions
          _buildFooter(doctor),
        ],
      ),
    );

    return pdf.save();
  }

  /// Build header section
  pw.Widget _buildHeader() {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.all(15),
      decoration: pw.BoxDecoration(
        color: PdfColors.blue50,
        border: pw.Border.all(color: PdfColors.blue200),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        children: [
          pw.Text(
            'MEDICAL PRESCRIPTION',
            style: pw.TextStyle(
              fontSize: 24,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.blue800,
            ),
          ),
          pw.SizedBox(height: 5),
          pw.Text(
            'Hospital Management System',
            style: pw.TextStyle(
              fontSize: 14,
              color: PdfColors.blue600,
            ),
          ),
          pw.Text(
            'Generated on: ${DateTime.now().toString().split('.')[0]}',
            style: const pw.TextStyle(
              fontSize: 10,
              color: PdfColors.grey600,
            ),
          ),
        ],
      ),
    );
  }

  /// Build doctor information section
  pw.Widget _buildDoctorSection(Doctor doctor) {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: pw.BorderRadius.circular(6),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'PRESCRIBING PHYSICIAN',
            style: pw.TextStyle(
              fontSize: 12,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.blue800,
            ),
          ),
          pw.SizedBox(height: 8),
          pw.Row(
            children: [
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'Dr. ${doctor.firstName} ${doctor.lastName}',
                      style: pw.TextStyle(
                        fontSize: 14,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.Text('Specialization: ${doctor.specialization}'),
                    pw.Text('Qualification: ${doctor.qualification}'),
                  ],
                ),
              ),
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('License No: ${doctor.licenseNumber}'),
                    pw.Text('Phone: ${doctor.phoneNumber}'),
                    pw.Text('Experience: ${doctor.experienceYears} years'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Build patient information section
  pw.Widget _buildPatientSection(Patient patient) {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: pw.BorderRadius.circular(6),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'PATIENT INFORMATION',
            style: pw.TextStyle(
              fontSize: 12,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.green800,
            ),
          ),
          pw.SizedBox(height: 8),
          pw.Row(
            children: [
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      '${patient.firstName} ${patient.lastName}',
                      style: pw.TextStyle(
                        fontSize: 14,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.Text('Age: ${patient.age} years'),
                    pw.Text('Gender: ${patient.gender}'),
                    pw.Text('Blood Group: ${patient.bloodGroup}'),
                  ],
                ),
              ),
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('Phone: ${patient.phoneNumber}'),
                    pw.Text('Date of Birth: ${patient.formattedDateOfBirth}'),
                    if (patient.hasAllergies)
                      pw.Text(
                        'Allergies: ${patient.allergies.join(", ")}',
                        style: const pw.TextStyle(color: PdfColors.red),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Build appointment details section
  pw.Widget _buildAppointmentSection(Appointment appointment) {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey50,
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: pw.BorderRadius.circular(6),
      ),
      child: pw.Row(
        children: [
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'APPOINTMENT DETAILS',
                  style: pw.TextStyle(
                    fontSize: 12,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.orange800,
                  ),
                ),
                pw.SizedBox(height: 5),
                pw.Text('Date: ${appointment.appointmentDate.toString().split(" ")[0]}'),
                pw.Text('Time: ${appointment.appointmentTime}'),
              ],
            ),
          ),
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('Reason: ${appointment.reasonForVisit}'),
                pw.Text('Status: ${appointment.status.displayName}'),
                pw.Text('Fee: ${appointment.formattedFee}'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Build main prescription content
  pw.Widget _buildPrescriptionContent(Appointment appointment) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        // Diagnosis section
        _buildContentSection(
          'DIAGNOSIS',
          appointment.diagnosis ?? 'No diagnosis provided',
          PdfColors.red800,
          PdfColors.red50,
        ),
        pw.SizedBox(height: 15),

        // Prescription section
        _buildContentSection(
          'PRESCRIPTION / MEDICATION',
          appointment.prescription ?? 'No prescription provided',
          PdfColors.blue800,
          PdfColors.blue50,
        ),
        pw.SizedBox(height: 15),

        // Additional notes section
        if (appointment.notes?.isNotEmpty == true)
          _buildContentSection(
            'ADDITIONAL NOTES / INSTRUCTIONS',
            appointment.notes!,
            PdfColors.green800,
            PdfColors.green50,
          ),
      ],
    );
  }

  /// Build a content section with title and content
  pw.Widget _buildContentSection(
    String title, 
    String content, 
    PdfColor titleColor, 
    PdfColor backgroundColor
  ) {
    return pw.Container(
      width: double.infinity,
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Container(
            width: double.infinity,
            padding: const pw.EdgeInsets.symmetric(vertical: 8, horizontal: 12),
            decoration: pw.BoxDecoration(
              color: backgroundColor,
              border: pw.Border.all(color: titleColor.shade(0.3)),
              borderRadius: const pw.BorderRadius.only(
                topLeft: pw.Radius.circular(6),
                topRight: pw.Radius.circular(6),
              ),
            ),
            child: pw.Text(
              title,
              style: pw.TextStyle(
                fontSize: 12,
                fontWeight: pw.FontWeight.bold,
                color: titleColor,
              ),
            ),
          ),
          pw.Container(
            width: double.infinity,
            padding: const pw.EdgeInsets.all(12),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: titleColor.shade(0.3)),
              borderRadius: const pw.BorderRadius.only(
                bottomLeft: pw.Radius.circular(6),
                bottomRight: pw.Radius.circular(6),
              ),
            ),
            child: pw.Text(
              content,
              style: const pw.TextStyle(fontSize: 11),
            ),
          ),
        ],
      ),
    );
  }

  /// Build footer with signature and instructions
  pw.Widget _buildFooter(Doctor doctor) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        // Instructions
        pw.Container(
          width: double.infinity,
          padding: const pw.EdgeInsets.all(10),
          decoration: pw.BoxDecoration(
            color: PdfColors.orange50,
            border: pw.Border.all(color: PdfColors.orange200),
            borderRadius: pw.BorderRadius.circular(6),
          ),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'IMPORTANT INSTRUCTIONS:',
                style: pw.TextStyle(
                  fontSize: 10,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.orange800,
                ),
              ),
              pw.SizedBox(height: 4),
              pw.Text(
                '• Take medications as prescribed\n'
                '• Complete the full course of treatment\n'
                '• Follow up if symptoms persist or worsen\n'
                '• Contact doctor for any adverse reactions',
                style: const pw.TextStyle(fontSize: 9),
              ),
            ],
          ),
        ),
        pw.SizedBox(height: 20),

        // Signature section
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'Doctor\'s Signature:',
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                ),
                pw.SizedBox(height: 30),
                pw.Container(
                  width: 200,
                  height: 1,
                  color: PdfColors.black,
                ),
                pw.SizedBox(height: 5),
                pw.Text(
                  'Dr. ${doctor.firstName} ${doctor.lastName}',
                  style: const pw.TextStyle(fontSize: 10),
                ),
                pw.Text(
                  doctor.specialization,
                  style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600),
                ),
              ],
            ),
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: [
                pw.Text(
                  'Date: ${DateTime.now().toString().split(' ')[0]}',
                  style: const pw.TextStyle(fontSize: 10),
                ),
                pw.SizedBox(height: 10),
                pw.Text(
                  'License: ${doctor.licenseNumber}',
                  style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600),
                ),
              ],
            ),
          ],
        ),

        pw.SizedBox(height: 20),

        // Footer note
        pw.Center(
          child: pw.Container(
            padding: const pw.EdgeInsets.all(8),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.grey400),
              borderRadius: pw.BorderRadius.circular(4),
            ),
            child: pw.Text(
              'This prescription is computer generated and valid only with doctor\'s signature.',
              style: const pw.TextStyle(
                fontSize: 8,
                color: PdfColors.grey600,
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// Print the generated prescription PDF
  Future<void> printPrescription({
    required Patient patient,
    required Doctor doctor,
    required Appointment appointment,
  }) async {
    try {
      final pdfData = await generatePrescriptionPDF(
        patient: patient,
        doctor: doctor,
        appointment: appointment,
      );

      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => pdfData,
        name: 'Prescription_${patient.lastName}_${DateTime.now().millisecondsSinceEpoch}',
      );
    } catch (e) {
      print("❌ Error printing prescription: $e");
      rethrow; // Re-throw to let the UI handle the error
    }
  }

  /// Save the generated PDF to Firebase Storage and update Firestore
  Future<String?> savePrescriptionToFirestore({
    required Patient patient,
    required Doctor doctor,
    required Appointment appointment,
  }) async {
    try {
      // Generate PDF
      final pdfData = await generatePrescriptionPDF(
        patient: patient,
        doctor: doctor,
        appointment: appointment,
      );

      // Create a unique filename
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = 'prescription_${appointment.id}_$timestamp.pdf';

      // Define storage path: prescriptions/{patientId}/{fileName}
      final ref = _storage.ref().child("prescriptions/${patient.id}/$fileName");

      // Upload file with metadata
      await ref.putData(
        pdfData,
        SettableMetadata(
          contentType: "application/pdf",
          customMetadata: {
            'patientId': patient.id,
            'doctorId': doctor.id,
            'appointmentId': appointment.id,
            'patientName': patient.fullName,
            'doctorName': doctor.fullName,
            'generatedAt': DateTime.now().toIso8601String(),
          },
        ),
      );

      // Get download URL
      final downloadUrl = await ref.getDownloadURL();

      // Update Firestore appointment document
      await _firestore.collection("appointments").doc(appointment.id).update({
        "prescriptionFileUrl": downloadUrl,
        "prescriptionFileName": fileName,
        "prescriptionGeneratedAt": FieldValue.serverTimestamp(),
        "prescriptionGeneratedBy": doctor.id,
      });

      // Also create a prescription record in a dedicated collection
      await _firestore.collection("prescriptions").add({
        "appointmentId": appointment.id,
        "patientId": patient.id,
        "doctorId": doctor.id,
        "fileUrl": downloadUrl,
        "fileName": fileName,
        "diagnosis": appointment.diagnosis,
        "prescription": appointment.prescription,
        "notes": appointment.notes,
        "createdAt": FieldValue.serverTimestamp(),
        "patientName": patient.fullName,
        "doctorName": doctor.fullName,
      });

      print("✅ Prescription saved to Firebase Storage and Firestore updated.");
      return downloadUrl;
    } catch (e) {
      print("❌ Error saving prescription: $e");
      rethrow; // Re-throw to let the UI handle the error
    }
  }

  /// Get all prescriptions for a patient
  Future<List<Map<String, dynamic>>> getPatientPrescriptions(String patientId) async {
    try {
      final querySnapshot = await _firestore
          .collection("prescriptions")
          .where("patientId", isEqualTo: patientId)
          .orderBy("createdAt", descending: true)
          .get();

      return querySnapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      print("❌ Error fetching patient prescriptions: $e");
      return [];
    }
  }

  /// Get all prescriptions by a doctor
  Future<List<Map<String, dynamic>>> getDoctorPrescriptions(String doctorId) async {
    try {
      final querySnapshot = await _firestore
          .collection("prescriptions")
          .where("doctorId", isEqualTo: doctorId)
          .orderBy("createdAt", descending: true)
          .get();

      return querySnapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      print("❌ Error fetching doctor prescriptions: $e");
      return [];
    }
  }

  /// Delete prescription (admin function)
  Future<bool> deletePrescription(String prescriptionId, String fileUrl) async {
    try {
      // Delete from Firestore
      await _firestore.collection("prescriptions").doc(prescriptionId).delete();

      // Delete from Storage
      final ref = FirebaseStorage.instance.refFromURL(fileUrl);
      await ref.delete();

      print("✅ Prescription deleted successfully.");
      return true;
    } catch (e) {
      print("❌ Error deleting prescription: $e");
      return false;
    }
  }
}