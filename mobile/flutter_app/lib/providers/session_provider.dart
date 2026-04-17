import 'dart:convert';
import 'package:flutter/material.dart';
import '../core/network/api_client.dart';
import '../core/constants/api_constants.dart';
import '../models/laboratory_model.dart';
import '../models/group_model.dart';
import '../models/session_model.dart';
import '../models/schedule_model.dart';

class SessionProvider extends ChangeNotifier {
  final _apiClient = ApiClient();
  
  List<LaboratoryModel> _laboratories = [];
  List<GroupModel> _groups = [];
  List<SessionModel> _sessions = [];
  List<ScheduleModel> _schedules = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<LaboratoryModel> get laboratories => _laboratories;
  List<GroupModel> get groups => _groups;
  List<SessionModel> get sessions => _sessions;
  List<ScheduleModel> get schedules => _schedules;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

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

  Future<void> fetchSchedules() async {
    _isLoading = true;
    notifyListeners();
    try {
      final cacheBuster = DateTime.now().millisecondsSinceEpoch;
      final res = await _apiClient.get('/schedules?_cb=$cacheBuster');
      if (res.statusCode == 200) {
        final List data = jsonDecode(res.body)['schedules'] ?? [];
        _schedules = data.map((g) => ScheduleModel.fromJson(g)).toList();
      }
    } catch (e) {
      _errorMessage = "Erreur chargement schedules: $e";
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<void> fetchMySessions() async {
    _isLoading = true;
    notifyListeners();
    try {
      final cacheBuster = DateTime.now().millisecondsSinceEpoch;
      print('⏳ [SessionProvider] Fetching my-sessions...');
      final response = await _apiClient.get('/sessions/my-sessions?_cb=$cacheBuster');
      print('⏳ [SessionProvider] Got response statusCode: ${response.statusCode}');
      if (response.statusCode == 200 || response.statusCode == 304) {
        final List data = jsonDecode(response.body)['sessions'] ?? [];
        print('🔥 [SessionProvider] fetchMySessions API returned ${data.length} items');
        try {
          _sessions = data.map((e) {
            print('   -> parsing session id: ${e["id"]}');
            return SessionModel.fromJson(e);
          }).toList();
          print('🔥 [SessionProvider] successfully mapped ${_sessions.length} sessions. Active count: ${_sessions.where((s)=>s.status == SessionStatus.ACTIVE).length}');
        } catch (mapErr) {
          print('❌ [SessionProvider] mapping error: $mapErr');
        }
      }
    } catch (e, stack) {
      print('❌ [SessionProvider] FATAL CATCH in fetchMySessions: $e\n$stack');
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
          
          // CRITICAL: locally update state
          _sessions.removeWhere((s) => s.id == session.id);
          _sessions.insert(0, session);
          notifyListeners();
          
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
      print('⏳ [SessionProvider] Attempting to close session: $sessionId');
      final response = await _apiClient.patch('/sessions/$sessionId/close', {});
      print('✅ [SessionProvider] Close response status: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        // Locally update closed status
        final idx = _sessions.indexWhere((s) => s.id == sessionId);
        if (idx != -1) {
          final old = _sessions[idx];
          _sessions[idx] = SessionModel(
            id: old.id,
            courseName: old.courseName,
            labId: old.labId,
            groupId: old.groupId,
            professorId: old.professorId,
            startTime: old.startTime,
            endTime: DateTime.now(),
            isRecurring: old.isRecurring,
            qrToken: null,
            scheduleId: old.scheduleId,
            status: SessionStatus.CLOSED,
            labName: old.labName,
            groupName: old.groupName,
            attendanceCount: old.attendanceCount,
          );
          notifyListeners();
        }
        return true;
      }
      
      _errorMessage = "Erreur back-end: ${response.statusCode}";
      return false;
    } catch (e, st) {
      print('❌ [SessionProvider] Close session ERROR: $e\n$st');
      _errorMessage = "Erreur de connexion";
      return false;
    }
  }
}
