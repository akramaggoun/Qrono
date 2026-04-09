class ApiConstants {
  // Use localhost for local PostgreSQL
  static const String baseUrl = 'http://localhost:3000/api';
  // Auth endpoints (no need for /api here as it's in baseUrl)
  static const String login = '$baseUrl/auth/login';
  static const String logout = '$baseUrl/auth/logout';
}
