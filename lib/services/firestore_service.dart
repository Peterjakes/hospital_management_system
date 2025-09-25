import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:hospital_management_system/models/appointment_model.dart';
import 'package:hospital_management_system/models/doctor_model.dart';
import 'package:hospital_management_system/models/patient_model.dart';
import 'package:hospital_management_system/models/department_model.dart';

// Firestore service handling all database operations
class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Collection references for better organization
  CollectionReference get _usersCollection => _firestore.collection('users');
  CollectionReference get _appointmentsCollection => _firestore.collection('appointments');
  CollectionReference get _departmentsCollection => _firestore.collection('departments');

  /// USER ROLE OPERATIONS ///

  // Update user role (Admin function)
  Future<void> updateUserRole(String userId, String newRole) async {
    try {
      await _usersCollection.doc(userId).update({
        'role': newRole,
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });
    } catch (e) {
      throw Exception('Failed to update user role: ${e.toString()}');
    }
  }

  // Get user by ID (for role verification)
  Future<Map<String, dynamic>?> getUserById(String userId) async {
    try {
      final doc = await _usersCollection.doc(userId).get();
      if (doc.exists) {
        return doc.data() as Map<String, dynamic>;
      }
    } catch (e) {
      throw Exception('Failed to get user: ${e.toString()}');
    }
    return null;
  }

  // Deactivate user (Admin function)
  Future<void> deactivateUser(String userId) async {
    try {
      await _usersCollection.doc(userId).update({
        'isActive': false,
        'deactivatedAt': Timestamp.fromDate(DateTime.now()),
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });
    } catch (e) {
      throw Exception('Failed to deactivate user: ${e.toString()}');
    }
  }

  // Reactivate user (Admin function)
  Future<void> reactivateUser(String userId) async {
    try {
      await _usersCollection.doc(userId).update({
        'isActive': true,
        'reactivatedAt': Timestamp.fromDate(DateTime.now()),
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });
    } catch (e) {
      throw Exception('Failed to reactivate user: ${e.toString()}');
    }
  }

  /// PATIENT OPERATIONS ///

  // Get patient by ID
  Future<Patient?> getPatient(String patientId) async {
    try {
      final doc = await _usersCollection.doc(patientId).get();
      if (doc.exists) {
        return Patient.fromDocument(doc);
      }
    } catch (e) {
      throw Exception('Failed to get patient: ${e.toString()}');
    }
    return null;
  }

  // Get all patients (Admin function)
  Future<List<Patient>> getAllPatients({int? limit}) async {
    try {
      Query query = _usersCollection.where('role', isEqualTo: 'patient');
      
      if (limit != null) {
        query = query.limit(limit);
      }
      
      final querySnapshot = await query.get();
      return querySnapshot.docs.map((doc) => Patient.fromDocument(doc)).toList();
    } catch (e) {
      throw Exception('Failed to get patients: ${e.toString()}');
    }
  }

  // Update patient information
  Future<void> updatePatient(String patientId, Map<String, dynamic> data) async {
    try {
      data['updatedAt'] = Timestamp.fromDate(DateTime.now());
      await _usersCollection.doc(patientId).update(data);
    } catch (e) {
      throw Exception('Failed to update patient: ${e.toString()}');
    }
  }

  // Create new patient
  Future<String> createPatient(Patient patient) async {
    try {
      final docRef = await _usersCollection.add(patient.toMap());
      return docRef.id;
    } catch (e) {
      throw Exception('Failed to create patient: ${e.toString()}');
    }
  }

  /// DOCTOR OPERATIONS ///

  // Get doctor by ID
  Future<Doctor?> getDoctor(String doctorId) async {
    try {
      final doc = await _usersCollection.doc(doctorId).get();
      if (doc.exists) {
        return Doctor.fromDocument(doc);
      }
    } catch (e) {
      throw Exception('Failed to get doctor: ${e.toString()}');
    }
    return null;
  }

  // Get all doctors
  Future<List<Doctor>> getAllDoctors() async {
    try {
      final querySnapshot = await _usersCollection
          .where('role', isEqualTo: 'doctor')
          .where('isActive', isEqualTo: true)
          .get();
      
      return querySnapshot.docs.map((doc) => Doctor.fromDocument(doc)).toList();
    } catch (e) {
      throw Exception('Failed to get doctors: ${e.toString()}');
    }
  }

  // Get doctors by department
  Future<List<Doctor>> getDoctorsByDepartment(String departmentId) async {
    try {
      final querySnapshot = await _usersCollection
          .where('role', isEqualTo: 'doctor')
          .where('departmentId', isEqualTo: departmentId)
          .where('isActive', isEqualTo: true)
          .get();
      
      return querySnapshot.docs.map((doc) => Doctor.fromDocument(doc)).toList();
    } catch (e) {
      throw Exception('Failed to get doctors by department: ${e.toString()}');
    }
  }

  // Update doctor information
  Future<void> updateDoctor(String doctorId, Map<String, dynamic> data) async {
    try {
      data['updatedAt'] = Timestamp.fromDate(DateTime.now());
      await _usersCollection.doc(doctorId).update(data);
    } catch (e) {
      throw Exception('Failed to update doctor: ${e.toString()}');
    }
  }

  // Create new doctor
  Future<String> createDoctor(Doctor doctor) async {
    try {
      final docRef = await _usersCollection.add(doctor.toMap());
      return docRef.id;
    } catch (e) {
      throw Exception('Failed to create doctor: ${e.toString()}');
    }
  }

  // Delete doctor (Admin function)
  Future<void> deleteDoctor(String doctorId) async {
    try {
      await _usersCollection.doc(doctorId).update({
        'isActive': false,
        'deletedAt': Timestamp.fromDate(DateTime.now()),
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });
    } catch (e) {
      throw Exception('Failed to delete doctor: ${e.toString()}');
    }
  }

  /// APPOINTMENT OPERATIONS ///

  // Create new appointment with comprehensive debugging
  Future<String> createAppointment(Appointment appointment) async {
    try {
      debugPrint('=== CREATING APPOINTMENT IN FIRESTORE ===');
      final appointmentMap = appointment.toMap();
      debugPrint('Appointment data to save: $appointmentMap');
      
      // Validate required fields
      final requiredFields = ['patientId', 'doctorId', 'appointmentDate', 'appointmentTime'];
      for (final field in requiredFields) {
        if (appointmentMap[field] == null) {
          throw Exception('Missing required field: $field');
        }
      }
      
      final docRef = await _appointmentsCollection.add(appointmentMap);
      debugPrint('✅ Appointment created with ID: ${docRef.id}');
      
      // Verify the appointment was saved correctly
      final savedDoc = await docRef.get();
      if (savedDoc.exists) {
        debugPrint('✅ Verification: Appointment saved successfully');
        final savedData = savedDoc.data() as Map<String, dynamic>;
        debugPrint('Saved data verification - Patient ID: ${savedData['patientId']}');
      } else {
        debugPrint('❌ Verification failed: Document not found after creation');
      }
      
      return docRef.id;
    } catch (e, stackTrace) {
      debugPrint('❌ Error creating appointment: $e');
      debugPrint('Stack trace: $stackTrace');
      throw Exception('Failed to create appointment: ${e.toString()}');
    }
  }

  // Get appointments for a patient with comprehensive debugging
  Future<List<Appointment>> getPatientAppointments(
    String patientId, {
    AppointmentStatus? status,
    int? limit,
  }) async {
    try {
      debugPrint('=== FIRESTORE: Getting patient appointments ===');
      debugPrint('Patient ID: $patientId');
      debugPrint('Status filter: $status');
      debugPrint('Limit: $limit');

      Query query = _appointmentsCollection
          .where('patientId', isEqualTo: patientId);
      
      // Add status filter if provided
      if (status != null) {
        query = query.where('status', isEqualTo: status.value);
        debugPrint('Added status filter: ${status.value}');
      }
      
      // Order by appointment date (most recent first)
      query = query.orderBy('appointmentDate', descending: true);
      
      if (limit != null) {
        query = query.limit(limit);
      }
      
      debugPrint('Executing Firestore query...');
      final querySnapshot = await query.get();
      debugPrint('✅ Query returned ${querySnapshot.docs.length} documents');
      
      if (querySnapshot.docs.isEmpty) {
        debugPrint('No documents found. Checking if any appointments exist...');
        
        // Check if there are any appointments at all for debugging
        final allAppointments = await _appointmentsCollection.limit(5).get();
        debugPrint('Total appointments in database (sample): ${allAppointments.docs.length}');
        
        if (allAppointments.docs.isNotEmpty) {
          debugPrint('Sample patient IDs in database:');
          for (var doc in allAppointments.docs) {
            final data = doc.data() as Map<String, dynamic>;
            debugPrint('  - ${data['patientId']} (looking for: $patientId)');
          }
        }
      }
      
      final appointments = <Appointment>[];
      
      for (var doc in querySnapshot.docs) {
        try {
          debugPrint('Processing document ${doc.id}');
          final data = doc.data() as Map<String, dynamic>;
          
          // Log essential fields
          debugPrint('  Patient ID: ${data['patientId']}');
          debugPrint('  Doctor ID: ${data['doctorId']}');
          debugPrint('  Date: ${data['appointmentDate']}');
          debugPrint('  Time: ${data['appointmentTime']}');
          debugPrint('  Reason: ${data['reasonForVisit']}');
          
          // Create appointment from the document
          final appointment = Appointment.fromDocument(doc);
          appointments.add(appointment);
          
          debugPrint('✅ Successfully created appointment: ${appointment.id}');
          
        } catch (e, stackTrace) {
          debugPrint('❌ Error processing document ${doc.id}: $e');
          debugPrint('Stack trace: $stackTrace');
          debugPrint('Document data: ${doc.data()}');
          // Continue processing other documents instead of failing completely
        }
      }
      
      debugPrint('✅ Successfully processed ${appointments.length} appointments');
      return appointments;
      
    } catch (e, stackTrace) {
      debugPrint('❌ Error in getPatientAppointments: $e');
      debugPrint('Stack trace: $stackTrace');
      throw Exception('Failed to get patient appointments: ${e.toString()}');
    }
  }

  // Debug method to get patient appointments with even more detailed logging
  Future<List<Appointment>> getPatientAppointmentsDebug(String patientId) async {
    try {
      debugPrint('=== DETAILED FIRESTORE DEBUG ===');
      
      // First, let's see if there are ANY appointments for this patient
      final allAppointments = await _appointmentsCollection
          .where('patientId', isEqualTo: patientId)
          .get();
      
      debugPrint('Total appointments found for patient $patientId: ${allAppointments.docs.length}');
      
      if (allAppointments.docs.isEmpty) {
        debugPrint('No appointments found. Checking if patient ID is correct...');
        
        // Let's also check what patient IDs exist in appointments
        final allPatientIds = await _appointmentsCollection
            .limit(10)
            .get();
        
        debugPrint('Sample of existing patient IDs in appointments:');
        for (var doc in allPatientIds.docs) {
          final data = doc.data() as Map<String, dynamic>;
          debugPrint('  - ${data['patientId']}');
        }
        
        return [];
      }
      
      // If appointments exist, let's examine their structure
      for (var doc in allAppointments.docs) {
        final data = doc.data() as Map<String, dynamic>;
        debugPrint('Document ${doc.id} fields:');
        data.forEach((key, value) {
          debugPrint('  $key: $value (${value.runtimeType})');
        });
        break; // Just examine the first one
      }
      
      // Now try to convert them
      final appointments = <Appointment>[];
      for (var doc in allAppointments.docs) {
        try {
          final appointment = Appointment.fromDocument(doc);
          appointments.add(appointment);
        } catch (e) {
          debugPrint('Failed to convert document ${doc.id}: $e');
          final data = doc.data() as Map<String, dynamic>;
          debugPrint('Problematic document data: $data');
        }
      }
      
      debugPrint('Successfully converted ${appointments.length} appointments');
      return appointments;
      
    } catch (e, stackTrace) {
      debugPrint('Error in getPatientAppointmentsDebug: $e');
      debugPrint('Stack trace: $stackTrace');
      rethrow;
    }
  }

  // Get appointments for a doctor
  Future<List<Appointment>> getDoctorAppointments(
    String doctorId, {
    DateTime? date,
    AppointmentStatus? status,
  }) async {
    try {
      Query query = _appointmentsCollection
          .where('doctorId', isEqualTo: doctorId);
      
      if (date != null) {
        final startOfDay = DateTime(date.year, date.month, date.day);
        final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59);
        
        query = query
            .where('appointmentDate', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
            .where('appointmentDate', isLessThanOrEqualTo: Timestamp.fromDate(endOfDay));
      }
      
      if (status != null) {
        query = query.where('status', isEqualTo: status.value);
      }
      
      query = query.orderBy('appointmentDate').orderBy('appointmentTime');
      
      final querySnapshot = await query.get();
      return querySnapshot.docs.map((doc) => Appointment.fromDocument(doc)).toList();
    } catch (e) {
      throw Exception('Failed to get doctor appointments: ${e.toString()}');
    }
  }

  /// Update appointment
  Future<void> updateAppointment(String appointmentId, Map<String, dynamic> data) async {
    try {
      debugPrint('=== UPDATING APPOINTMENT ===');
      debugPrint('Appointment ID: $appointmentId');
      debugPrint('Update data: $data');
      
      data['updatedAt'] = Timestamp.fromDate(DateTime.now());
      await _appointmentsCollection.doc(appointmentId).update(data);
      
      debugPrint('✅ Appointment updated successfully');
    } catch (e) {
      debugPrint('❌ Error updating appointment: $e');
      throw Exception('Failed to update appointment: ${e.toString()}');
    }
  }

  /// Cancel appointment
  Future<void> cancelAppointment(String appointmentId, String reason) async {
    try {
      debugPrint('=== CANCELLING APPOINTMENT ===');
      debugPrint('Appointment ID: $appointmentId');
      debugPrint('Reason: $reason');
      
      await _appointmentsCollection.doc(appointmentId).update({
        'status': AppointmentStatus.cancelled.value,
        'cancelReason': reason,
        'cancelledAt': Timestamp.fromDate(DateTime.now()),
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });
      
      debugPrint('✅ Appointment cancelled successfully');
    } catch (e) {
      debugPrint('❌ Error cancelling appointment: $e');
      throw Exception('Failed to cancel appointment: ${e.toString()}');
    }
  }

  /// Check doctor availability
  Future<bool> checkDoctorAvailability({
    required String doctorId,
    required DateTime date,
    required String time,
  }) async {
    try {
      debugPrint('=== CHECKING DOCTOR AVAILABILITY ===');
      debugPrint('Doctor ID: $doctorId');
      debugPrint('Date: $date');
      debugPrint('Time: $time');
      
      final querySnapshot = await _appointmentsCollection
          .where('doctorId', isEqualTo: doctorId)
          .where('appointmentDate', isEqualTo: Timestamp.fromDate(date))
          .where('appointmentTime', isEqualTo: time)
          .where('status', whereIn: [
            AppointmentStatus.scheduled.value,
            AppointmentStatus.confirmed.value,
            AppointmentStatus.inProgress.value,
          ])
          .get();
      
      final isAvailable = querySnapshot.docs.isEmpty;
      debugPrint('Doctor available: $isAvailable (${querySnapshot.docs.length} conflicting appointments)');
      
      return isAvailable;
    } catch (e) {
      debugPrint('❌ Error checking availability: $e');
      throw Exception('Failed to check availability: ${e.toString()}');
    }
  }

  /// ADMIN ANALYTICS AND REPORTING ///

  // Get user statistics
  Future<Map<String, int>> getUserStatistics() async {
    try {
      final patientsQuery = await _usersCollection
          .where('role', isEqualTo: 'patient')
          .where('isActive', isEqualTo: true)
          .get();
      
      final doctorsQuery = await _usersCollection
          .where('role', isEqualTo: 'doctor')
          .where('isActive', isEqualTo: true)
          .get();
      
      final adminsQuery = await _usersCollection
          .where('role', isEqualTo: 'admin')
          .where('isActive', isEqualTo: true)
          .get();

      return {
        'patients': patientsQuery.docs.length,
        'doctors': doctorsQuery.docs.length,
        'admins': adminsQuery.docs.length,
        'total': patientsQuery.docs.length + doctorsQuery.docs.length + adminsQuery.docs.length,
      };
    } catch (e) {
      throw Exception('Failed to get user statistics: ${e.toString()}');
    }
  }

  // Get all users (Admin function with pagination)
  Future<List<Map<String, dynamic>>> getAllUsers({
    int? limit,
    DocumentSnapshot? startAfter,
    String? role,
    bool? isActive,
  }) async {
    try {
      Query query = _usersCollection;
      
      if (role != null) {
        query = query.where('role', isEqualTo: role);
      }
      
      if (isActive != null) {
        query = query.where('isActive', isEqualTo: isActive);
      }
      
      query = query.orderBy('createdAt', descending: true);
      
      if (startAfter != null) {
        query = query.startAfterDocument(startAfter);
      }
      
      if (limit != null) {
        query = query.limit(limit);
      }
      
      final querySnapshot = await query.get();
      return querySnapshot.docs.map((doc) => {
        'id': doc.id,
        ...doc.data() as Map<String, dynamic>,
      }).toList();
    } catch (e) {
      throw Exception('Failed to get all users: ${e.toString()}');
    }
  }

  // Batch update users (Admin function)
  Future<void> batchUpdateUsers(List<String> userIds, Map<String, dynamic> updates) async {
    try {
      final batch = _firestore.batch();
      updates['updatedAt'] = Timestamp.fromDate(DateTime.now());
      
      for (final userId in userIds) {
        final docRef = _usersCollection.doc(userId);
        batch.update(docRef, updates);
      }
      
      await batch.commit();
    } catch (e) {
      throw Exception('Failed to batch update users: ${e.toString()}');
    }
  }

  /// ADDITIONAL DEBUG METHODS ///

  // Quick method to get all appointments (for debugging)
  Future<List<Map<String, dynamic>>> getAllAppointments({int limit = 20}) async {
    try {
      final querySnapshot = await _appointmentsCollection
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .get();
      
      return querySnapshot.docs.map((doc) => {
        'id': doc.id,
        ...doc.data() as Map<String, dynamic>,
      }).toList();
    } catch (e) {
      debugPrint('Error getting all appointments: $e');
      return [];
    }
  }

  // Method to verify appointment exists
  Future<bool> appointmentExists(String appointmentId) async {
    try {
      final doc = await _appointmentsCollection.doc(appointmentId).get();
      return doc.exists;
    } catch (e) {
      debugPrint('Error checking appointment existence: $e');
      return false;
    }
  }

  // Method to get raw appointment data
  Future<Map<String, dynamic>?> getRawAppointmentData(String appointmentId) async {
    try {
      final doc = await _appointmentsCollection.doc(appointmentId).get();
      if (doc.exists) {
        return {
          'id': doc.id,
          ...doc.data() as Map<String, dynamic>,
        };
      }
    } catch (e) {
      debugPrint('Error getting raw appointment data: $e');
    }
    return null;
  }
}