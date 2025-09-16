import 'package:cloud_firestore/cloud_firestore.dart';

/// Department model representing hospital departments
class Department {
  final String id;
  final String name;
  final String description;
  final String headDoctorId;
  final List<String> services;
  final String location;
  final String contactNumber;
  final String email;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? imageUrl;

  Department({
    required this.id,
    required this.name,
    required this.description,
    required this.headDoctorId,
    this.services = const [],
    required this.location,
    required this.contactNumber,
    required this.email,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
    this.imageUrl,
  });
}