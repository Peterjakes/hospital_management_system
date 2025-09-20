import 'package:flutter/material.dart';

/// Application theme configuration
class AppTheme {
  // Primary color palette - Modern medical blue theme
  static const Color primaryColor = Color(0xFF4A90E2); // Modern medical blue
  static const Color primaryColorDark = Color(0xFF357ABD);
  static const Color primaryColorLight = Color(0xFF7BB3F0);
  
  // Secondary color palette - Clean white and soft grays
  static const Color secondaryColor = Color(0xFFF8F9FA);
  static const Color secondaryColorDark = Color(0xFFE9ECEF);
  static const Color secondaryColorLight = Color(0xFFFFFFFF);
  
  // Role-based colors for better UX
  static const Color doctorColor = Color(0xFF4A90E2); // Medical blue
  static const Color patientColor = Color(0xFF6C63FF); // Modern purple
  static const Color adminColor = Color(0xFF2ECC71); // Fresh green
  
  // Status colors for appointments
  static const Color scheduledColor = Color(0xFF4A90E2); // Blue
  static const Color confirmedColor = Color(0xFF2ECC71); // Green
  static const Color completedColor = Color(0xFF27AE60); // Dark Green
  static const Color cancelledColor = Color(0xFFF44336); // Red
  static const Color appointmentColor = Color(0xFFF39C12); // Orange
  
  // Utility colors
  static const Color errorColor = Color(0xFFE74C3C);
  static const Color warningColor = Color(0xFFF39C12);
  static const Color successColor = Color(0xFF2ECC71);
  
  // Text colors
  static const Color textPrimary = Color(0xFF2C3E50);
  static const Color textSecondary = Color(0xFF7F8C8D);
  static const Color textHint = Color(0xFFBDC3C7);
  
  // Background colors
  static const Color backgroundColor = Color(0xFFF8F9FA);
  static const Color surfaceColor = Color(0xFFFFFFFF);
  static const Color cardColor = Color(0xFFFFFFFF);
  
  // Medical app specific colors
  static const Color emergencyColor = Color(0xFFE74C3C);
  static const Color consultationColor = Color(0xFF4A90E2);
  static const Color medicineColor = Color(0xFF9B59B6);
  static const Color ambulanceColor = Color(0xFFE67E22);

  /// Light theme configuration
  /// Modern medical app theming system
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      fontFamily: 'SF Pro Display', // iOS-style font
      
      colorScheme: const ColorScheme.light(
        primary: primaryColor,
        onPrimary: Colors.white,
        secondary: secondaryColor,
        onSecondary: Colors.white,
        surface: surfaceColor,
        onSurface: textPrimary,
        background: backgroundColor,
        onBackground: textPrimary,
        error: errorColor,
        onError: Colors.white,
      ),
      
      // App bar theme for consistent headers
      appBarTheme: const AppBarTheme(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),
      
      // Card theme for consistent containers
      cardTheme: CardThemeData(
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        color: cardColor,
        shadowColor: Colors.black.withOpacity(0.1),
      ),
      
      // Button themes for consistent interactions
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      
      // Input decoration theme
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primaryColor, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        filled: true,
        fillColor: Color(0xFFF8F9FA),
      ),
    );
  }

  /// Medical app specific gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primaryColor, primaryColorLight],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  static const LinearGradient emergencyGradient = LinearGradient(
    colors: [Color(0xFFE74C3C), Color(0xFFC0392B)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  static const LinearGradient consultationGradient = LinearGradient(
    colors: [Color(0xFF4A90E2), Color(0xFF357ABD)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

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