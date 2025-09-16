import 'package:cloud_firestore/cloud_firestore.dart';

// Firestore service handling all database operations
class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Collection references for better organization
  CollectionReference get _usersCollection => _firestore.collection('users');
  CollectionReference get _appointmentsCollection => _firestore.collection('appointments');
  CollectionReference get _departmentsCollection => _firestore.collection('departments');
}
