import 'package:flutter/material.dart';

/// Application theme configuration
class AppTheme {
  // Primary color palette - Medical blue theme
  static const Color primaryColor = Color(0xFF2196F3); // Blue
  static const Color primaryColorDark = Color(0xFF1976D2);
  static const Color primaryColorLight = Color(0xFFBBDEFB);
  
  // Secondary color palette - Health green
  static const Color secondaryColor = Color(0xFF4CAF50); // Green
  static const Color secondaryColorDark = Color(0xFF388E3C);
  static const Color secondaryColorLight = Color(0xFFC8E6C9);

  // Role-based colors for better UX
  static const Color doctorColor = Color(0xFF1976D2); // Blue
  static const Color patientColor = Color(0xFF4CAF50); // Green
  static const Color adminColor = Color(0xFF9C27B0); // Purple

  // Status colors for appointments
  static const Color scheduledColor = Color(0xFF2196F3); // Blue
  static const Color confirmedColor = Color(0xFF4CAF50); // Green
  static const Color completedColor = Color(0xFF8BC34A); // Light Green
  static const Color cancelledColor = Color(0xFFF44336); // Red
  static const Color appointmentColor = Color(0xFFFF9800); // Orange
  
  // Utility colors
  static const Color errorColor = Color(0xFFF44336);
  static const Color warningColor = Color(0xFFFF9800);
  static const Color successColor = Color(0xFF4CAF50);

}
