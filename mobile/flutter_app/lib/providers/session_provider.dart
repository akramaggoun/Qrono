import 'dart:convert';
import 'package:flutter/material.dart';
import '../core/network/api_client.dart';
import '../core/constants/api_constants.dart';
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

  List<LaboratoryModel> get laboratories => _laboratories;
  List<GroupModel> get groups => _groups;
  List<SessionModel> get sessions => _sessions;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> fetchLabsAndGroups() async {
    _isLoading = true;
    notifyListeners();
    try {
      final labsRes = await _apiClient.get('/api/rooms'); // UML Step 1
      final groupsRes = await _apiClient.get('/api/groups'); // UML Step 1
      
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
      final response = await _apiClient.get('/api/sessions/my-sessions');
      if (response.statusCode == 200) {
        final List data = jsonDecode(response.body)['sessions'] ?? [];
        _sessions = data.map((e) => SessionModel.fromJson(e)).toList();
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
      final response = await _apiClient.post('/api/sessions', data);
      _isLoading = false;
      notifyListeners();

      if (response.statusCode == 201) {
        final sessionData = jsonDecode(response.body)['session'];
        return SessionModel.fromJson(sessionData);
      } else if (response.statusCode == 409) {
        _errorMessage = "Le laboratoire est déjà occupé à cette heure.";
      } else {
        _errorMessage = "Erreur lors de la création de la session.";
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
      final response = await _apiClient.patch('/api/sessions/$sessionId/close', {});
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
}
