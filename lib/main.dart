import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:hospital_management_system/providers/auth_provider.dart';
import 'package:hospital_management_system/screens/auth/login_screen.dart';

void main() async {
  // Ensure Flutter widgets are initialized
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase
  await Firebase.initializeApp();
  
  runApp(const HospitalManagementApp());
}

/// Root widget of the application
class HospitalManagementApp extends StatelessWidget {
  const HospitalManagementApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AuthProvider(),
      child: MaterialApp(
        title: 'Hospital Management System',
        debugShowCheckedModeBanner: false,
        
        // Basic theme 
        theme: ThemeData(
          primarySwatch: Colors.blue,
          useMaterial3: true,
        ),
        
        
        home: const LoginScreen(),
      ),
    );
  }
}
