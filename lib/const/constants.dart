/// Application constants and configuration
/// entralized constants for better maintainability
class AppConstants {
  // App Information
  static const String appName = 'Hospital Management System';
  static const String appVersion = '1.0.0';
  static const String appDescription = 'Comprehensive hospital management solution';
  
  // Hospital Information
  static const String hospitalName = 'City General Hospital';
  static const String hospitalAddress = '123 Medical Center Drive, Healthcare City, HC 12345';
  static const String hospitalPhone = '+1 (555) 123-4567';
  static const String hospitalEmail = 'info@citygeneralhospital.com';
  static const String hospitalWebsite = 'www.citygeneralhospital.com';
  
  // Default Values
  static const String defaultProfileImage = 'assets/images/default_profile.png';
  static const String defaultHospitalLogo = 'assets/images/hospital_logo.png';
  
  // Appointment Settings
  static const int defaultConsultationDuration = 30; // minutes
  static const double defaultConsultationFee = 50.0; // USD
  static const int appointmentReminderHours = 1;
  static const int maxAppointmentsPerDay = 20;
  
  // Validation Rules
  static const int minPasswordLength = 6;
  static const int maxPasswordLength = 50;
  static const int minNameLength = 2;
  static const int maxNameLength = 50;
  static const int minPhoneLength = 10;
  static const int maxPhoneLength = 15;
  
  // UI Constants
  static const double defaultPadding = 16.0;
  static const double defaultMargin = 8.0;
  static const double defaultBorderRadius = 8.0;
  static const double cardElevation = 2.0;
  static const double buttonHeight = 50.0;
  
  // Animation Durations
  static const Duration shortAnimationDuration = Duration(milliseconds: 200);
  static const Duration mediumAnimationDuration = Duration(milliseconds: 500);
  static const Duration longAnimationDuration = Duration(milliseconds: 1000);
  
  // Network Settings
  static const Duration networkTimeout = Duration(seconds: 30);
  static const int maxRetryAttempts = 3;
  
  // File Settings
  static const int maxFileSize = 10 * 1024 * 1024; // 10MB
  static const List<String> allowedImageTypes = ['jpg', 'jpeg', 'png', 'gif'];
  static const List<String> allowedDocumentTypes = ['pdf', 'doc', 'docx'];
  
  // Blood Groups
  static const List<String> bloodGroups = [
    'A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-'
  ];
  
  // Gender Options
  static const List<String> genderOptions = [
    'Male', 'Female', 'Other', 'Prefer not to say'
  ];
  
  // Days of Week
  static const List<String> daysOfWeek = [
    'Monday', 'Tuesday', 'Wednesday', 'Thursday', 
    'Friday', 'Saturday', 'Sunday'
  ];
  
  // Time Slots (24-hour format)
  static const List<String> timeSlots = [
    '09:00', '09:30', '10:00', '10:30', '11:00', '11:30',
    '12:00', '12:30', '13:00', '13:30', '14:00', '14:30',
    '15:00', '15:30', '16:00', '16:30', '17:00', '17:30'
  ];
  
  // Medical Specializations
  static const List<String> medicalSpecializations = [
    'General Medicine',
    'Cardiology',
    'Dermatology',
    'Endocrinology',
    'Gastroenterology',
    'Neurology',
    'Oncology',
    'Orthopedics',
    'Pediatrics',
    'Psychiatry',
    'Radiology',
    'Surgery',
    'Urology',
    'Gynecology',
    'Ophthalmology',
    'ENT (Ear, Nose, Throat)',
    'Emergency Medicine',
    'Anesthesiology',
    'Pathology',
    'Physical Medicine'
  ];
  
  // Error Messages
  static const String networkErrorMessage = 'Network error. Please check your connection.';
  static const String serverErrorMessage = 'Server error. Please try again later.';
  static const String unknownErrorMessage = 'An unknown error occurred.';
  static const String authErrorMessage = 'Authentication failed. Please try again.';
  static const String permissionErrorMessage = 'Permission denied. Please check your permissions.';
  
  // Success Messages
  static const String loginSuccessMessage = 'Login successful!';
  static const String registrationSuccessMessage = 'Registration successful!';
  static const String appointmentBookedMessage = 'Appointment booked successfully!';
  static const String appointmentCancelledMessage = 'Appointment cancelled successfully!';
  static const String profileUpdatedMessage = 'Profile updated successfully!';
  static const String passwordResetMessage = 'Password reset email sent!';
  
  // Notification Types
  static const String appointmentReminderType = 'appointment_reminder';
  static const String appointmentStatusType = 'appointment_status';
  static const String prescriptionReadyType = 'prescription_ready';
  static const String systemUpdateType = 'system_update';
  
  // Storage Paths
  static const String profileImagesPath = 'profile_images';
  static const String prescriptionsPath = 'prescriptions';
  static const String reportsPath = 'reports';
  static const String documentsPath = 'documents';
  
  // Firestore Collections
  static const String usersCollection = 'users';
  static const String appointmentsCollection = 'appointments';
  static const String departmentsCollection = 'departments';
  static const String notificationsCollection = 'notifications';
  static const String settingsCollection = 'settings';
  
  // Shared Preferences Keys
  static const String userIdKey = 'user_id';
  static const String userRoleKey = 'user_role';
  static const String isFirstLaunchKey = 'is_first_launch';
  static const String themePreferenceKey = 'theme_preference';
  static const String notificationEnabledKey = 'notification_enabled';
  
  // Regular Expressions
  static const String emailRegex = r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$';
  static const String phoneRegex = r'^\+?[1-9]\d{1,14}$';
  static const String nameRegex = r'^[a-zA-Z\s]+$';
  
  // Date Formats
  static const String dateFormat = 'dd/MM/yyyy';
  static const String timeFormat = 'HH:mm';
  static const String dateTimeFormat = 'dd/MM/yyyy HH:mm';
  static const String displayDateFormat = 'EEEE, MMMM dd, yyyy';
  
  // PDF Settings
  static const String pdfAuthor = 'Hospital Management System';
  static const String pdfCreator = 'Flutter PDF Generator';
  static const String pdfSubject = 'Medical Document';
  
  // Development Settings
  static const bool isDebugMode = true;
  static const bool enableLogging = true;
  static const bool enableAnalytics = false;
  
  // Feature Flags
  static const bool enableVideoConsultation = false;
  static const bool enableChatFeature = false;
  static const bool enablePaymentIntegration = false;
  static const bool enableMultiLanguage = false;
}