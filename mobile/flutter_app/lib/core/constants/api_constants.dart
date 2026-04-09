class ApiConstants {
  // Dynamic base URL configuration for wireless access
  // Set this to your Cloudflare tunnel URL when using wireless access
  // Example: 'https://qrono-api.yourdomain.com/api'
  // For local development: 'http://localhost:3000/api'
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:3000/api'
  );

  // Alternative: Uncomment and use this for easy switching
  // static const String baseUrl = 'https://qrono-api.yourdomain.com/api'; // For wireless access
  // static const String baseUrl = 'http://localhost:3000/api'; // For local development

  // Auth endpoints
  static const String login = '$baseUrl/auth/login';
  static const String logout = '$baseUrl/auth/logout';
  static const String refreshToken = '$baseUrl/auth/refresh';

  // User endpoints
  static const String getProfile = '$baseUrl/users/profile';
  static const String updateProfile = '$baseUrl/users/profile';

  // Session endpoints
  static const String createSession = '$baseUrl/sessions';
  static const String getSessions = '$baseUrl/sessions';
  static const String getSessionById = '$baseUrl/sessions'; // + /:id
  static const String updateSession = '$baseUrl/sessions'; // + /:id
  static const String deleteSession = '$baseUrl/sessions'; // + /:id

  // Presence/Attendance endpoints
  static const String scanQR = '$baseUrl/presences/scan';
  static const String getMyAttendances = '$baseUrl/presences/my-attendances';
  static const String getSessionAttendances = '$baseUrl/sessions'; // + /:id/attendances

  // Notification endpoints
  static const String getNotifications = '$baseUrl/notifications';
  static const String markNotificationRead = '$baseUrl/notifications'; // + /:id/read

  // Laboratory endpoints
  static const String getLaboratories = '$baseUrl/laboratories';

  // Group endpoints
  static const String getGroups = '$baseUrl/groups';

  // Statistics endpoints
  static const String getStatistics = '$baseUrl/statistics';

  // Helper method to check if using wireless access
  static bool get isWirelessAccess => baseUrl.contains('yourdomain.com') || baseUrl.contains('tunnel');

  // Helper method to get current connection type
  static String get connectionType => isWirelessAccess ? 'Wireless (Cloudflare Tunnel)' : 'Local Network';
}
}
