import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:hospital_management_system/const/app_theme.dart';
import 'package:hospital_management_system/providers/doctor_provider.dart';
import 'package:hospital_management_system/providers/patient_provider.dart';
import 'package:provider/provider.dart';
import 'package:hospital_management_system/providers/auth_provider.dart';
import 'package:hospital_management_system/providers/appointment_provider.dart';
import 'package:hospital_management_system/screens/auth/splash_screen.dart';
import 'package:hospital_management_system/services/notification_service.dart';
import 'firebase_options.dart';

// FCM requires this to be a TOP-LEVEL (or static) function — it runs in a
// separate isolate when a notification arrives while the app is fully
// terminated. It can't access app state, so it just needs to exist for
// FCM's background message handling to work at all.
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
}

/// Main entry point of the Hospital Management System
void main() async {
  // Ensure Flutter widgets are initialized
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase with options for web and other platforms
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  await NotificationService.instance.initialize();

  runApp(const HospitalManagementApp());
}

// root widget of the application
class HospitalManagementApp extends StatelessWidget {
  const HospitalManagementApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => AppointmentProvider()),
        ChangeNotifierProvider(create: (_) => DoctorProvider()),
        ChangeNotifierProvider(create: (_) => PatientProvider()),
      ],
      child: MaterialApp(
        title: 'Hospital Management System',
        debugShowCheckedModeBanner: false,

        // Professional theme system
        theme: AppTheme.lightTheme,
    
        themeMode: ThemeMode.system,

        // Start with splash screen for proper initialization
        home: const SplashScreen(),
        
      ),
    );
  }
}