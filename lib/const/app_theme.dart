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

  /// Light theme configuration
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: const ColorScheme.light(
        primary: primaryColor,
        onPrimary: Colors.white,
        secondary: secondaryColor,
        onSecondary: Colors.white,
        surface: Colors.white,
        onSurface: Colors.black,
        background: Color(0xFFF5F5F5),
        onBackground: Colors.black,
        error: errorColor,
        onError: Colors.white,
      ),
    );
  }

  /// Dark theme configuration
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: const ColorScheme.dark(
        primary: primaryColorLight,
        onPrimary: Colors.black,
        secondary: secondaryColorLight,
        onSecondary: Colors.black,
        surface: Color(0xFF1E1E1E),
        onSurface: Colors.white,
        background: Color(0xFF121212),
        onBackground: Colors.white,
        error: errorColor,
        onError: Colors.white,
      ),
    );
  }

   /// Get status color based on appointment status
  static Color getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'scheduled':
        return scheduledColor;
      case 'confirmed':
        return confirmedColor;
      case 'completed':
        return completedColor;
      case 'cancelled':
        return cancelledColor;
      default:
        return scheduledColor;
    }
  }

  /// Get role color based on user role
  static Color getRoleColor(String role) {
    switch (role.toLowerCase()) {
      case 'doctor':
        return doctorColor;
      case 'patient':
        return patientColor;
      case 'admin':
        return adminColor;
      default:
        return primaryColor;
    }
  }

}
