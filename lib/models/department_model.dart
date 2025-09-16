import 'package:cloud_firestore/cloud_firestore.dart';

// Department model representing hospital departments
//used for organizing doctors and managing hospital structure
class Department {
  final String id;
  final String name;
  final String description;
  final String headDoctorId;
  final List<String> services; // Services offered by the department
  final String location; // Floor or wing location
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

  //Create Department instance from Firestore document
  // handles data conversion and provides default values
  factory Department.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    return Department(
      id: doc.id,
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      headDoctorId: data['headDoctorId'] ?? '',
      services: List<String>.from(data['services'] ?? []),
      location: data['location'] ?? '',
      contactNumber: data['contactNumber'] ?? '',
      email: data['email'] ?? '',
      isActive: data['isActive'] ?? true,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      imageUrl: data['imageUrl'],
    );
  }

  // Convert Department instance to Map for Firestore storage
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'description': description,
      'headDoctorId': headDoctorId,
      'services': services,
      'location': location,
      'contactNumber': contactNumber,
      'email': email,
      'isActive': isActive,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'imageUrl': imageUrl,
    };
  }

  // Create a copy of Department with updated fields
  // maintains immutability while allowing updates
  Department copyWith({
    String? name,
    String? description,
    String? headDoctorId,
    List<String>? services,
    String? location,
    String? contactNumber,
    String? email,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? imageUrl,
  }) {
    return Department(
      id: id,
      name: name ?? this.name,
      description: description ?? this.description,
      headDoctorId: headDoctorId ?? this.headDoctorId,
      services: services ?? this.services,
      location: location ?? this.location,
      contactNumber: contactNumber ?? this.contactNumber,
      email: email ?? this.email,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      imageUrl: imageUrl ?? this.imageUrl,
    );
  }
}