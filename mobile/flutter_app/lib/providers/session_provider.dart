import 'dart:convert';
import 'package:flutter/material.dart';
import '../core/network/api_client.dart';
import '../models/laboratory_model.dart';
import '../models/group_model.dart';
import '../models/session_model.dart';

class SessionProvider extends ChangeNotifier {
  final _apiClient = ApiClient();
  
  List<LaboratoryModel> _laboratories = [];
  List<GroupModel> _groups = [];
  List<SessionModel> _sessions = [];
  bool _isLoading = false;
  String? _errorMessage;

  Map<String, dynamic> _professorStats = {
    'totalSessions': 0,
    'todayAttendance': 0,
    'attendanceRate': '0'
  };

  List<LaboratoryModel> get laboratories => _laboratories;
  List<GroupModel> get groups => _groups;
  List<SessionModel> get sessions => _sessions;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  Map<String, dynamic> get professorStats => _professorStats;

  Future<void> fetchLabsAndGroups() async {
    _isLoading = true;
    notifyListeners();
    try {
      final labsRes = await _apiClient.get('/laboratories');
      final groupsRes = await _apiClient.get('/groups');
      
      if (labsRes.statusCode == 200 && groupsRes.statusCode == 200) {
        final List labsData = jsonDecode(labsRes.body)['laboratories'] ?? [];
        final List groupsData = jsonDecode(groupsRes.body)['groups'] ?? [];
        
        _laboratories = labsData.map((l) => LaboratoryModel.fromJson(l)).toList();
        _groups = groupsData.map((g) => GroupModel.fromJson(g)).toList();
      }
    } catch (e) {
      _errorMessage = "Erreur chargement labs: $e";
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<void> fetchMySessions() async {
    _isLoading = true;
    notifyListeners();
    try {
      final response = await _apiClient.get('/sessions/my-sessions');
      if (response.statusCode == 200) {
        final List data = jsonDecode(response.body)['sessions'] ?? [];
        
        // ⬇️ LIST PROTECTION: Clear existing list before mapping new ones to prevent doubling ⬇️
        final List<SessionModel> newList = data.map((e) => SessionModel.fromJson(e)).toList();
        _sessions = newList;
      }

      // Fetch real-time stats for professor
      final statsRes = await _apiClient.get('/statistics/professor');
      if (statsRes.statusCode == 200) {
        _professorStats = jsonDecode(statsRes.body);
      }
    } catch (e) {
      _errorMessage = "Erreur sessions: $e";
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<void> fetchStudentSessions() async {
    _isLoading = true;
    notifyListeners();
    try {
      // For now we use the same endpoint but backend might need special filter
      final response = await _apiClient.get('/sessions/my-sessions');
      if (response.statusCode == 200) {
        final List data = jsonDecode(response.body)['sessions'] ?? [];
        
        // ⬇️ LIST PROTECTION: Ensure list is fresh ⬇️
        final List<SessionModel> newList = data.map((e) => SessionModel.fromJson(e)).toList();
        _sessions = newList;
      }
    } catch (e) {
      _errorMessage = "Erreur sessions: $e";
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<SessionModel?> createSession(Map<String, dynamic> data) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      final response = await _apiClient.post('/sessions', data);
      _isLoading = false;
      notifyListeners();

      if (response.statusCode == 201) {
        final body = jsonDecode(response.body);
        print('📥 SESSION CREATED IN BACKEND: $body');
        final sessionData = body['session'];
        try {
          final session = SessionModel.fromJson(sessionData);
          print('✅ SESSION PARSED SUCCESSFULLY: ${session.courseName}');
          return session;
        } catch (e) {
          print('❌ ERROR PARSING SESSION MODEL: $e');
          _errorMessage = "Erreur de formatage des données.";
          return null;
        }
      } else {
        final errorBody = jsonDecode(response.body);
        _errorMessage = errorBody['message'] ?? "Erreur lors de la création de la session.";
        print('❌ SERVER REJECTED SESSION: $_errorMessage');
      }
    } catch (e) {
      _errorMessage = "Une erreur est survenue.";
      _isLoading = false;
      notifyListeners();
    }
    return null;
  }

  Future<bool> closeSession(String sessionId) async {
    try {
      final response = await _apiClient.patch('/sessions/$sessionId/close', {});
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
}
