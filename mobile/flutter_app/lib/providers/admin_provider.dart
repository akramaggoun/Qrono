import 'dart:convert';
import 'package:flutter/material.dart';
import 'dart:async'; // Added for Timer
import '../core/network/api_client.dart';
import '../models/user_model.dart';
import '../models/laboratory_model.dart';
import '../models/group_model.dart';
import '../models/unauthorized_log_model.dart';
import '../models/schedule_model.dart';

class AdminProvider extends ChangeNotifier {
  final _apiClient = ApiClient();
  bool _isLoading = false;
  String? _errorMessage;
  
  // Data lists
  List<UserModel> _users = [];
  List<LaboratoryModel> _laboratories = [];
  List<GroupModel> _groups = [];
  List<ScheduleModel> _schedules = [];
  Map<String, dynamic> _statistics = {};
  List<UnauthorizedLogModel> _unauthorizedLogs = [];
  Map<String, dynamic>? _currentEntityStats;
  Timer? _refreshTimer; // Added for auto-refresh

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  List<UserModel> get users => _users;
  List<LaboratoryModel> get laboratories => _laboratories;
  List<GroupModel> get groups => _groups;
  List<UnauthorizedLogModel> get unauthorizedLogs => _unauthorizedLogs;
  List<ScheduleModel> get schedules => _schedules;
  Map<String, dynamic> get statistics => _statistics;
  Map<String, dynamic>? get currentEntityStats => _currentEntityStats;

  int get totalProfessors => _statistics['totalProfessors'] ?? 0;
  int get totalStudents => _statistics['totalStudents'] ?? 0;
  int get totalGroups => _statistics['totalGroups'] ?? 0;
  int get todaySessions => _statistics['todaySessions'] ?? 0;
  int get todayAttendance => _statistics['todayAttendance'] ?? 0;
  double get attendanceRate => (_statistics['attendanceRate'] ?? 0).toDouble();

  // ═══════════════════════════════
  //  AUTO-REFRESH LOGIC
  // ═══════════════════════════════
  void startAutoRefresh(Duration interval) {
    _refreshTimer?.cancel();
    _refreshTimer = Timer.periodic(interval, (_) {
      fetchStatistics();
      fetchUnauthorizedLogs();
    });
    print('🔄 ADMIN: Auto-refresh started (Interval: ${interval.inSeconds}s)');
  }

  void stopAutoRefresh() {
    _refreshTimer?.cancel();
    _refreshTimer = null;
    print('🛑 ADMIN: Auto-refresh stopped');
  }

  // ═══════════════════════════════
  //  STATISTICS (Scenario 6)
  // ═══════════════════════════════
  Future<void> fetchStatistics() async {
    _isLoading = true;
    notifyListeners();
    try {
      final response = await _apiClient.get('/statistics');
      if (response.statusCode == 200) {
        _statistics = jsonDecode(response.body);
      }
    } catch (e) {
      _errorMessage = "Stats error: $e";
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<void> fetchEntityStats(String type, String id) async {
    _isLoading = true;
    _currentEntityStats = null;
    notifyListeners();
    try {
      final response = await _apiClient.get('/statistics/$type/$id');
      if (response.statusCode == 200) {
        _currentEntityStats = jsonDecode(response.body);
      } else {
        _errorMessage = "Failed to load $type stats";
      }
    } catch (e) {
      _errorMessage = "Network error: $e";
    }
    _isLoading = false;
    notifyListeners();
  }

  // ═══════════════════════════════
  //  LOGS NON AUTORISÉS
  // ═══════════════════════════════
  Future<void> fetchUnauthorizedLogs() async {
    _isLoading = true;
    notifyListeners();
    try {
      final response = await _apiClient.get('/unauthorized-logs');
      if (response.statusCode == 200) {
        final List data = jsonDecode(response.body)['logs'] ?? [];
        _unauthorizedLogs = data.map((e) => UnauthorizedLogModel.fromJson(e)).toList();
      }
    } catch (e) {
      _errorMessage = "Erreur logs: $e";
    }
    _isLoading = false;
    notifyListeners();
  }

  // ═══════════════════════════════
  //  USERS (Scenario 1, 2, 3)
  // ═══════════════════════════════
  Future<void> fetchUsers() async {
    _isLoading = true;
    notifyListeners();
    try {
      final response = await _apiClient.get('/users');
      if (response.statusCode == 200) {
        final List data = jsonDecode(response.body)['users'];
        _users = data.map((u) => UserModel.fromJson(u)).toList();
      }
    } catch (e) {
      _errorMessage = "Erreur chargement utilisateurs.";
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<bool> addUser(Map<String, dynamic> userData) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      print('🌐 API CALL STARTED: POST /users');
      print('📦 BODY: $userData');
      final response = await _apiClient.post('/users', userData);
      if (response.statusCode == 201) {
        await fetchUsers();
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        final body = jsonDecode(response.body);
        _errorMessage = body['message'] ?? "Failed to create user (${response.statusCode})";
      }
    } catch (e) {
      print('❌ ERROR: $e');
      _errorMessage = "Connection error: $e";
    }
    _isLoading = false;
    notifyListeners();
    return false;
  }

  Future<bool> updateUser(String id, Map<String, dynamic> userData) async {
    _isLoading = true;
    notifyListeners();
    try {
      final response = await _apiClient.put('/users/$id', userData);
      if (response.statusCode == 200) {
        await fetchUsers();
        _isLoading = false;
        notifyListeners();
        return true;
      }
    } catch (e) {
      _errorMessage = "Erreur mise à jour.";
    }
    _isLoading = false;
    notifyListeners();
    return false;
  }

  Future<bool> deleteUser(String id) async {
    try {
      final response = await _apiClient.delete('/users/$id');
      if (response.statusCode == 200) {
        await fetchUsers();
        return true;
      }
    } catch (e) {
      _errorMessage = "Erreur suppression.";
    }
    return false;
  }

  // ═══════════════════════════════
  //  LABORATORIES (Scenario 4)
  // ═══════════════════════════════
  Future<void> fetchLaboratories() async {
    _isLoading = true;
    notifyListeners();
    try {
      final response = await _apiClient.get('/laboratories');
      if (response.statusCode == 200) {
        final List data = jsonDecode(response.body)['laboratories'];
        _laboratories = data.map((l) => LaboratoryModel.fromJson(l)).toList();
      }
    } catch (e) {
      _errorMessage = "Erreur chargement labos.";
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<bool> addLaboratory(Map<String, dynamic> labData) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      print('🌐 API CALL STARTED: POST /laboratories');
      print('📦 BODY: $labData');
      final response = await _apiClient.post('/laboratories', labData);
      if (response.statusCode == 201) {
        await fetchLaboratories();
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        final body = jsonDecode(response.body);
        _errorMessage = body['message'] ?? "Failed to create laboratory (${response.statusCode})";
      }
    } catch (e) {
      print('❌ ERROR: $e');
      _errorMessage = "Connection error: $e";
    }
    _isLoading = false;
    notifyListeners();
    return false;
  }

  Future<bool> updateLaboratory(String id, Map<String, dynamic> labData) async {
    _isLoading = true;
    notifyListeners();
    try {
      final response = await _apiClient.put('/laboratories/$id', labData);
      if (response.statusCode == 200) {
        await fetchLaboratories();
        _isLoading = false;
        notifyListeners();
        return true;
      }
    } catch (e) {
      _errorMessage = "Erreur mise à jour labo.";
    }
    _isLoading = false;
    notifyListeners();
    return false;
  }

  Future<bool> deleteLaboratory(String id) async {
    try {
      final response = await _apiClient.delete('/laboratories/$id');
      if (response.statusCode == 200) {
        await fetchLaboratories();
        return true;
      }
    } catch (e) {
      _errorMessage = "Erreur suppression labo.";
    }
    return false;
  }

  // ═══════════════════════════════
  //  GROUPS (Scenario 5)
  // ═══════════════════════════════
  Future<void> fetchGroups() async {
    _isLoading = true;
    notifyListeners();
    try {
      final response = await _apiClient.get('/groups');
      if (response.statusCode == 200) {
        final List data = jsonDecode(response.body)['groups'];
        _groups = data.map((g) => GroupModel.fromJson(g)).toList();
      }
    } catch (e) {
      _errorMessage = "Erreur chargement groupes.";
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<bool> addGroup(Map<String, dynamic> groupData) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      print('🌐 API CALL STARTED: POST /groups');
      print('📦 BODY: $groupData');
      final response = await _apiClient.post('/groups', groupData);
      if (response.statusCode == 201) {
        await fetchGroups();
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        final body = jsonDecode(response.body);
        _errorMessage = body['message'] ?? "Failed to create group (${response.statusCode})";
      }
    } catch (e) {
      print('❌ ERROR: $e');
      _errorMessage = "Connection error: $e";
    }
    _isLoading = false;
    notifyListeners();
    return false;
  }

  Future<bool> updateGroup(String id, Map<String, dynamic> groupData) async {
    _isLoading = true;
    notifyListeners();
    try {
      final response = await _apiClient.put('/groups/$id', groupData);
      if (response.statusCode == 200) {
        await fetchGroups();
        _isLoading = false;
        notifyListeners();
        return true;
      }
    } catch (e) {
      _errorMessage = "Erreur mise à jour groupe.";
    }
    _isLoading = false;
    notifyListeners();
    return false;
  }

  Future<bool> deleteGroup(String id) async {
    try {
      final response = await _apiClient.delete('/groups/$id');
      if (response.statusCode == 200) {
        await fetchGroups();
        return true;
      }
    } catch (e) {
      _errorMessage = "Erreur suppression groupe.";
    }
    return false;
  }

  // ═══════════════════════════════
  //  SCHEDULES
  // ═══════════════════════════════
  Future<void> fetchSchedules() async {
    _isLoading = true;
    notifyListeners();
    try {
      final response = await _apiClient.get('/schedules');
      if (response.statusCode == 200) {
        final List data = jsonDecode(response.body)['schedules'] ?? [];
        _schedules = data.map((g) => ScheduleModel.fromJson(g)).toList();
      }
    } catch (e) {
      _errorMessage = "Erreur chargement schedules.";
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<bool> addSchedule(Map<String, dynamic> scheduleData) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      final response = await _apiClient.post('/schedules', scheduleData);
      if (response.statusCode == 201) {
        await fetchSchedules();
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        final body = jsonDecode(response.body);
        _errorMessage = body['message'] ?? "Failed to create schedule (${response.statusCode})";
      }
    } catch (e) {
      _errorMessage = "Connection error: $e";
    }
    _isLoading = false;
    notifyListeners();
    return false;
  }

  Future<bool> updateSchedule(String id, Map<String, dynamic> scheduleData) async {
    _isLoading = true;
    notifyListeners();
    try {
      final response = await _apiClient.put('/schedules/$id', scheduleData);
      if (response.statusCode == 200) {
        await fetchSchedules();
        _isLoading = false;
        notifyListeners();
        return true;
      }
    } catch (e) {
      _errorMessage = "Erreur mise à jour schedule.";
    }
    _isLoading = false;
    notifyListeners();
    return false;
  }

  Future<bool> deleteSchedule(String id) async {
    try {
      final response = await _apiClient.delete('/schedules/$id');
      if (response.statusCode == 200) {
        await fetchSchedules();
        return true;
      }
    } catch (e) {
      _errorMessage = "Erreur suppression schedule.";
    }
    return false;
  }
}
