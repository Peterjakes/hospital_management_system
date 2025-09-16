import 'package:cloud_firestore/cloud_firestore.dart';

// Department model representing hospital departments
class Department {
  final String id;
  final String name;
  final String description;
  final String headDoctorId;

  Department({
    required this.id,
    required this.name,
    required this.description,
    required this.headDoctorId,
  });
}
