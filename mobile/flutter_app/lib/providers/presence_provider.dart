import 'dart:convert';
import 'package:flutter/material.dart';
import '../core/network/api_client.dart';

import '../models/attendance_model.dart';

class PresenceProvider extends ChangeNotifier {
  final _apiClient = ApiClient();
  bool _isLoading = false;
  String? _errorMessage;
  Map<String, dynamic>? _attendanceData;
  List<AttendanceModel> _attendances = [];
  List<AttendanceModel> _myAttendances = [];
  List<dynamic> _groupStudents = [];
  
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  Map<String, dynamic>? get attendanceData => _attendanceData;
  List<AttendanceModel> get attendances => _attendances;
  List<AttendanceModel> get myAttendances => _myAttendances;
  List<dynamic> get groupStudents => _groupStudents;

  Future<void> fetchSessionAttendance(String sessionId) async {
    _isLoading = true;
    notifyListeners();
    try {
      final response = await _apiClient.get('/sessions/$sessionId/attendances');
      if (response.statusCode == 200) {
        final Map<String, dynamic> body = jsonDecode(response.body);
        final List data = body['attendances'] ?? [];
        _attendances = data.map((e) => AttendanceModel.fromJson(e)).toList();
        _attendanceData = body; // Store full response for metadata
      }
    } catch (e) {
      _errorMessage = "Erreur présences: \$e";
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<void> fetchMyAttendances() async {
    _isLoading = true;
    notifyListeners();
    try {
      final response = await _apiClient.get('/presences/my-attendances');
      if (response.statusCode == 200) {
        final Map<String, dynamic> body = jsonDecode(response.body);
        final List data = body['attendances'] ?? [];
        _myAttendances = data.map((e) => AttendanceModel.fromJson(e)).toList();
        _attendanceData = body; // Store full response for stats
      }
    } catch (e) {
      _errorMessage = "Erreur historique: \$e";
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<void> fetchGroupStudents(String groupId) async {
    _isLoading = true;
    notifyListeners();
    try {
      final response = await _apiClient.get('/groups/$groupId/students');
      if (response.statusCode == 200) {
        _groupStudents = jsonDecode(response.body)['students'] ?? [];
      }
    } catch (e) {
      _errorMessage = "Erreur chargement groupe: $e";
    }
    _isLoading = false; 
    notifyListeners();
  }

  Future<bool> scanQR(String qrToken) async {
    _isLoading = true;
    _errorMessage = null;
    _attendanceData = null;
    notifyListeners();

    try {
      final response = await _apiClient.post('/presences/scan', {
        'qr_token': qrToken,
      });

      _isLoading = false;
      notifyListeners();

      if (response.statusCode == 201) {
        _attendanceData = jsonDecode(response.body)['attendance'];
        await fetchMyAttendances(); // Refresh history and stats immediately
        return true;
      } else if (response.statusCode == 404) {
        _errorMessage = "Code QR invalide.";
      } else if (response.statusCode == 400) {
        final msg = jsonDecode(response.body)['message'];
        if (msg == "QR Code is revoked") _errorMessage = "La session est fermée.";
        else if (msg == "QR Code expired") _errorMessage = "Le code QR a expiré.";
        else if (msg == "Session is not active") _errorMessage = "La session n'est plus active.";
        else _errorMessage = "Erreur de validation du QR.";
      } else if (response.statusCode == 403) {
        _errorMessage = "Cette session n'est pas destinée à votre groupe.";
      } else if (response.statusCode == 409) {
        _errorMessage = "Vous avez déjà enregistré votre présence.";
      } else {
        _errorMessage = "Une erreur est survenue lors de l'enregistrement.";
      }
    } catch (e) {
      _errorMessage = "Erreur réseau ou serveur.";
      _isLoading = false;
      notifyListeners();
    }
    return false;
  }
}
