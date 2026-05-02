class ApiConstants {
  // Compile-time default base URL.
  // Runtime switching (wireless/local) is handled by ApiConfig (SharedPreferences).
  static const String defaultBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:3000/api',
  );

  // Alternative: Uncomment and use this for easy switching
  // static const String baseUrl = 'https://qrono-api.yourdomain.com/api'; // For wireless access
  // static const String baseUrl = 'http://localhost:3000/api'; // For local development

  // Auth endpoints
  static const String login = '$defaultBaseUrl/auth/login';
  static const String logout = '$defaultBaseUrl/auth/logout';
  static const String refreshToken = '$defaultBaseUrl/auth/refresh';

  // User endpoints
  static const String getProfile = '$defaultBaseUrl/users/profile';
  static const String updateProfile = '$defaultBaseUrl/users/profile';

  // Session endpoints
  static const String createSession = '$defaultBaseUrl/sessions';
  static const String getSessions = '$defaultBaseUrl/sessions';
  static const String getSessionById = '$defaultBaseUrl/sessions'; // + /:id
  static const String updateSession = '$defaultBaseUrl/sessions'; // + /:id
  static const String deleteSession = '$defaultBaseUrl/sessions'; // + /:id

  // Presence/Attendance endpoints
  static const String scanQR = '$defaultBaseUrl/presences/scan';
  static const String getMyAttendances = '$defaultBaseUrl/presences/my-attendances';
  static const String getSessionAttendances = '$defaultBaseUrl/sessions'; // + /:id/attendances

  // Notification endpoints
  static const String getNotifications = '$defaultBaseUrl/notifications';
  static const String markNotificationRead = '$defaultBaseUrl/notifications'; // + /:id/read

  // Laboratory endpoints
  static const String getLaboratories = '$defaultBaseUrl/laboratories';

  // Group endpoints
  static const String getGroups = '$defaultBaseUrl/groups';

  // Statistics endpoints
  static const String getStatistics = '$defaultBaseUrl/statistics';
}
