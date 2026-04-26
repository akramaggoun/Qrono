import 'dart:convert';
import 'package:flutter/material.dart';
import '../core/network/api_client.dart';

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

  // Statistics Getters
  int get streak {
    if (_myAttendances.isEmpty) return 0;
    
    // Sort by date descending
    final sorted = List.from(_myAttendances)..sort((a, b) {
      final dateA = DateTime.parse(a['checkInAt'] ?? a['check_in_at']);
      final dateB = DateTime.parse(b['checkInAt'] ?? b['check_in_at']);
      return dateB.compareTo(dateA);
    });

    int currentStreak = 0;
    DateTime lastDate = DateTime.now();
    
    for (var i = 0; i < sorted.length; i++) {
      final checkIn = DateTime.parse(sorted[i]['checkInAt'] ?? sorted[i]['check_in_at']);
      final diff = DateTime(lastDate.year, lastDate.month, lastDate.day)
          .difference(DateTime(checkIn.year, checkIn.month, checkIn.day))
          .inDays;

      if (i == 0 && diff <= 1) {
        currentStreak = 1;
        lastDate = checkIn;
      } else if (i > 0 && diff == 1) {
        currentStreak++;
        lastDate = checkIn;
      } else if (i > 0 && diff == 0) {
        // Multiple sessions in same day, continue
        continue;
      } else if (i > 0) {
        break;
      }
    }
    return currentStreak;
  }

  String get topCourse {
    if (_myAttendances.isEmpty) return "N/A";
    
    final Map<String, int> counts = {};
    for (var a in _myAttendances) {
      final course = a['session']?['courseName'] ?? "Unknown";
      counts[course] = (counts[course] ?? 0) + 1;
    }
    
    var top = "N/A";
    var max = 0;
    counts.forEach((k, v) {
      if (v > max) {
        max = v;
        top = k;
      }
    });
    return top;
  }

  int get sessionsThisWeek {
    if (_myAttendances.isEmpty) return 0;
    
    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    final startOfToday = DateTime(weekStart.year, weekStart.month, weekStart.day);
    
    return _myAttendances.where((a) {
      final checkIn = DateTime.parse(a['checkInAt'] ?? a['check_in_at']);
      return checkIn.isAfter(startOfToday);
    }).length;
  }

  Future<void> fetchSessionAttendance(String sessionId) async {
    _isLoading = true;
    notifyListeners();
    try {
      final response = await _apiClient.get('/sessions/$sessionId/attendances');
      if (response.statusCode == 200) {
        _attendances = jsonDecode(response.body)['attendances'] ?? [];
      }
    } catch (e) {
      _errorMessage = "Erreur présences: $e";
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
        _myAttendances = jsonDecode(response.body)['attendances'] ?? [];
      }
    } catch (e) {
      _errorMessage = "Erreur historique: $e";
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
        return true;
      } else if (response.statusCode == 404) {
        _errorMessage = "Code QR invalide.";
      } else if (response.statusCode == 400) {
        final msg = jsonDecode(response.body)['message'];
        if (msg == "QR Code is revoked") {
          _errorMessage = "La session est fermée.";
        } else if (msg == "QR Code expired") {
          _errorMessage = "Le code QR a expiré.";
        } else if (msg == "Session is not active") {
          _errorMessage = "La session n'est plus active.";
        } else {
          _errorMessage = "Erreur de validation du QR.";
        }      } else if (response.statusCode == 403) {
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

  Future<bool> markManualAttendance(String sessionId, String studentId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _apiClient.post('/presences/manual', {
        'sessionId': sessionId,
        'studentId': studentId,
      });

      _isLoading = false;
      notifyListeners();

      if (response.statusCode == 200) {
        // Refresh the list after manual recording
        await fetchSessionAttendance(sessionId);
        return true;
      } else {
        final errorData = jsonDecode(response.body);
        _errorMessage = errorData['message'] ?? 'Erreur lors de l\'enregistrement manuel.';
      }
    } catch (e) {
      _errorMessage = "Erreur réseau: $e";
      _isLoading = false;
      notifyListeners();
    }
    return false;
  }

  Future<Map<String, dynamic>?> fetchStudentStats(String studentId) async {
    try {
      final response = await _apiClient.get('/presences/student/$studentId/stats');
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
    } catch (e) {
      _errorMessage = "Erreur stats étudiant: $e";
    }
    return null;
  }

  Future<bool> toggleExclusion(String studentRecordId, String courseName, bool exclude) async {
    try {
      final response = await _apiClient.post('/presences/exclude', {
        'studentId': studentRecordId,
        'courseName': courseName,
        'exclude': exclude,
      });
      return response.statusCode == 200;
    } catch (e) {
      _errorMessage = "Erreur exclusion: $e";
      return false;
    }
  }

  Future<bool> isStudentExcluded(String studentRecordId, String courseName) async {
    try {
      final response = await _apiClient.get('/presences/check-exclusion?studentId=$studentRecordId&courseName=$courseName');
      if (response.statusCode == 200) {
        return jsonDecode(response.body)['isExcluded'] ?? false;
      }
    } catch (e) {
      debugPrint("Erreur check exclusion: $e");
    }
    return false;
  }
}

