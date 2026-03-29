import 'dart:convert';
import 'package:flutter/material.dart';
import '../core/network/api_client.dart';
import '../core/constants/api_constants.dart';

class PresenceProvider extends ChangeNotifier {
  final _apiClient = ApiClient();
  bool _isLoading = false;
  String? _errorMessage;
  Map<String, dynamic>? _attendanceData;
  List<dynamic> _attendances = [];
  List<dynamic> _myAttendances = [];

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  Map<String, dynamic>? get attendanceData => _attendanceData;
  List<dynamic> get attendances => _attendances;
  List<dynamic> get myAttendances => _myAttendances;

  Future<void> fetchSessionAttendance(String sessionId) async {
    _isLoading = true;
    notifyListeners();
    try {
      final response = await _apiClient.get('/api/sessions/\$sessionId/attendances');
      if (response.statusCode == 200) {
        _attendances = jsonDecode(response.body)['attendances'] ?? [];
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
      final response = await _apiClient.get('/api/presences/my-attendances');
      if (response.statusCode == 200) {
        _myAttendances = jsonDecode(response.body)['attendances'] ?? [];
      }
    } catch (e) {
      _errorMessage = "Erreur historique: \$e";
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
      final response = await _apiClient.post('/api/presences/scan', {
        'qr_token': qrToken,
      });

      _isLoading = false;
      notifyListeners();

      if (response.statusCode == 201) {
        _attendanceData = jsonDecode(response.body)['attendance'];
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
