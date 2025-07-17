class AppConstants {
  // Supabase Configuration
  static const String supabaseUrl = 'YOUR_SUPABASE_URL';
  static const String supabaseAnonKey = 'YOUR_SUPABASE_ANON_KEY';

  // Firebase Web Configuration
  static const Map<String, String> firebaseWebConfig = {
    'apiKey': 'YOUR_API_KEY',
    'authDomain': 'YOUR_AUTH_DOMAIN',
    'projectId': 'YOUR_PROJECT_ID',
    'storageBucket': 'YOUR_STORAGE_BUCKET',
    'messagingSenderId': 'YOUR_MESSAGING_SENDER_ID',
    'appId': 'YOUR_APP_ID',
    'measurementId': 'YOUR_MEASUREMENT_ID',
  };

  // App Settings
  static const String appName = 'Helping Hands';
  static const String appVersion = '1.0.0';
  static const String appBuildNumber = '1';

  // API Endpoints
  static const String apiBaseUrl = 'YOUR_API_BASE_URL';

  // Notification Channels
  static const String mainNotificationChannel = 'helping_hands_notifications';
  static const String notificationChannelName = 'Helping Hands Notifications';
  static const String notificationChannelDescription =
      'Notifications from Helping Hands app';

  // Cache Settings
  static const int maxCacheAge = 7; // days
  static const int maxCacheSize = 50; // MB

  // Timeouts
  static const int apiTimeout = 30; // seconds
  static const int locationTimeout = 10; // seconds
  static const int uploadTimeout = 300; // seconds

  // Pagination
  static const int defaultPageSize = 20;
  static const int maxPageSize = 100;

  // Job Settings
  static const double minHourlyRate = 1000.0; // LKR
  static const double maxHourlyRate = 10000.0; // LKR
  static const int maxJobDuration = 12; // hours
  static const int minJobDuration = 1; // hours

  // Location Settings
  static const double defaultLatitude = 6.9271; // Colombo
  static const double defaultLongitude = 79.8612; // Colombo
  static const double maxSearchRadius = 50.0; // km
  static const double defaultSearchRadius = 10.0; // km

  // Rating Settings
  static const int minRating = 1;
  static const int maxRating = 5;
  static const int minReviewLength = 10;
  static const int maxReviewLength = 500;

  // File Upload Settings
  static const int maxFileSize = 10; // MB
  static const List<String> allowedImageTypes = ['jpg', 'jpeg', 'png'];
  static const List<String> allowedDocumentTypes = ['pdf', 'doc', 'docx'];
  static const int maxImageDimension = 2048; // pixels

  // Error Messages
  static const String networkError = 'Please check your internet connection';
  static const String serverError =
      'Something went wrong. Please try again later';
  static const String locationError = 'Unable to get your location';
  static const String permissionError = 'Please grant the required permissions';
  static const String uploadError = 'Failed to upload file';
  static const String downloadError = 'Failed to download file';
  static const String authError = 'Authentication failed';
  static const String validationError = 'Please check your input';
  static const String paymentError = 'Payment processing failed';
  static const String notificationError = 'Failed to send notification';

  // Success Messages
  static const String uploadSuccess = 'File uploaded successfully';
  static const String downloadSuccess = 'File downloaded successfully';
  static const String paymentSuccess = 'Payment processed successfully';
  static const String notificationSuccess = 'Notification sent successfully';
  static const String profileUpdateSuccess = 'Profile updated successfully';
  static const String ratingSuccess = 'Rating submitted successfully';
  static const String bookingSuccess = 'Booking confirmed successfully';
  static const String cancellationSuccess = 'Booking cancelled successfully';

  // Date Formats
  static const String dateFormat = 'yyyy-MM-dd';
  static const String timeFormat = 'HH:mm';
  static const String dateTimeFormat = 'yyyy-MM-dd HH:mm';
  static const String humanReadableDateFormat = 'MMM dd, yyyy';
  static const String humanReadableTimeFormat = 'hh:mm a';
  static const String humanReadableDateTimeFormat = 'MMM dd, yyyy hh:mm a';
}
