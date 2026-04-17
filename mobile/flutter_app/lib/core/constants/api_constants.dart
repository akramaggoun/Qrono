import 'package:flutter/foundation.dart';

class ApiConstants {
  // FINAL SOLUTION: Using "Physical ADB Bridge" via USB.
  // This maps the phone's port 3000 to the computer's port 3000.
  // 100% Stable, No Internet required, No Firebase lag.
  
  static const String baseUrl = 'http://localhost:3000/api'; 

  // Auth endpoints
  static String get login => '$baseUrl/auth/login';
  static String get logout => '$baseUrl/auth/logout';
}
