import 'package:cloud_firestore/cloud_firestore.dart';
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

  // Delete doctor (Admin function)
  Future<void> deleteDoctor(String doctorId) async {
    try {
      await _usersCollection.doc(doctorId).update({
        'isActive': false,
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });
    } catch (e) {
      throw Exception('Failed to delete doctor: ${e.toString()}');
    }
  }

  /// APPOINTMENT OPERATIONS ///

  // Create new appointment
  Future<String> createAppointment(Appointment appointment) async {
    try {
      final docRef = await _appointmentsCollection.add(appointment.toMap());
      return docRef.id;
    } catch (e) {
      throw Exception('Failed to create appointment: ${e.toString()}');
    }
  }

  // Get appointments for a patient
  Future<List<Appointment>> getPatientAppointments(
    String patientId, {
    AppointmentStatus? status,
    int? limit,
  }) async {
    try {
      Query query = _appointmentsCollection
          .where('patientId', isEqualTo: patientId)
          .orderBy('appointmentDate', descending: true);
      
      if (status != null) {
        query = query.where('status', isEqualTo: status.value);
      }
      
      if (limit != null) {
        query = query.limit(limit);
      }
      
      final querySnapshot = await query.get();
      return querySnapshot.docs.map((doc) => Appointment.fromDocument(doc)).toList();
    } catch (e) {
      throw Exception('Failed to get patient appointments: ${e.toString()}');
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
      data['updatedAt'] = Timestamp.fromDate(DateTime.now());
      await _appointmentsCollection.doc(appointmentId).update(data);
    } catch (e) {
      throw Exception('Failed to update appointment: ${e.toString()}');
    }
  }

  /// Cancel appointment
  Future<void> cancelAppointment(String appointmentId, String reason) async {
    try {
      await _appointmentsCollection.doc(appointmentId).update({
        'status': AppointmentStatus.cancelled.value,
        'cancelReason': reason,
        'cancelledAt': Timestamp.fromDate(DateTime.now()),
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });
    } catch (e) {
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
      
      return querySnapshot.docs.isEmpty;
    } catch (e) {
      throw Exception('Failed to check availability: ${e.toString()}');
    }
  }


  /// DEPARTMENT OPERATIONS ///
   
   // Get all departments
   Future<List<Department>> getAllDepartments() async {
     try {
       final querySnapshot = await _departmentsCollection.get();
       return querySnapshot.docs.map((doc) => Department.fromDocument(doc)).toList();
     } catch (e) {
       throw Exception('Failed to get departments: ${e.toString()}');
     }
   }
   
   // Get department by ID
   Future<Department?> getDepartment(String departmentId) async {
     try {
       final doc = await _departmentsCollection.doc(departmentId).get();
       if (doc.exists) {
         return Department.fromDocument(doc);
       }
     } catch (e) {
       throw Exception('Failed to get department: ${e.toString()}');
     }
     return null;
   }
}