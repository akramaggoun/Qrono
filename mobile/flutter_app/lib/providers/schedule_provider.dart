import 'dart:convert';
import 'package:flutter/material.dart';
import '../core/network/api_client.dart';

class ScheduleProvider extends ChangeNotifier {
  final ApiClient _apiClient = ApiClient();
  
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  List<Map<String, dynamic>> _professors = [];
  List<Map<String, dynamic>> get professors => _professors;

  List<Map<String, dynamic>> _groups = [];
  List<Map<String, dynamic>> get groups => _groups;

  List<Map<String, dynamic>> _labs = [];
  List<Map<String, dynamic>> get labs => _labs;

  List<Map<String, dynamic>> _professorSessions = [];
  List<Map<String, dynamic>> get professorSessions => _professorSessions;

  /// Fetch initial lookups: Professors, Groups, Labs required for Admin Planning
  Future<void> fetchLookups() async {
    _isLoading = true;
    notifyListeners();

    try {
      // Fetch professors (filter from all users where role='professor')
      final professorsResponse = await _apiClient.get('/users');
      
      // Fetch groups
      final groupsResponse = await _apiClient.get('/groups');
      
      // Fetch laboratories
      final labsResponse = await _apiClient.get('/laboratories');

      // Parse professors (filter by role='professor')
      if (professorsResponse.statusCode == 200) {
        final data = jsonDecode(professorsResponse.body);
        final allUsers = List<Map<String, dynamic>>.from(data['users'] ?? []);
        final filteredProfessors = <Map<String, dynamic>>[];
        for (var u in allUsers) {
          if (u['role'] == 'professor') {
            filteredProfessors.add({
              'id': u['id'],
              'name': u['name'],
              'department': u['department'] ?? 'Unknown Department'
            });
          }
        }
        _professors = filteredProfessors;
      } else {
        _professors = [];
        throw Exception('Failed to fetch professors from database');
      }

      // Parse groups
      if (groupsResponse.statusCode == 200) {
        final data = jsonDecode(groupsResponse.body);
        final groupsList = (data['groups'] as List?)?.cast<Map<String, dynamic>>() ?? [];
        _groups = groupsList;
      } else {
        _groups = [];
        throw Exception('Failed to fetch groups from database');
      }

      // Parse laboratories
      if (labsResponse.statusCode == 200) {
        final data = jsonDecode(labsResponse.body);
        final labsList = (data['laboratories'] as List?)?.cast<Map<String, dynamic>>() ?? [];
        _labs = labsList;
      } else {
        _labs = [];
        throw Exception('Failed to fetch laboratories from database');
      }
    } catch (e) {
      debugPrint('Error fetching lookups from database: $e');
      _professors = [];
      _groups = [];
      _labs = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Fetch a specific professor's weekly schedule
  Future<void> fetchProfessorSchedule(String professorId) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await _apiClient.get('/schedules/professor/$professorId');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _professorSessions = List<Map<String, dynamic>>.from(data['sessions'] ?? []);
      } else {
        _professorSessions = [];
        throw Exception('Failed to fetch professor sessions from database');
      }
    } catch (e) {
      debugPrint('Error fetching professor sessions: $e');
      _professorSessions = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Assign a new schedule block (composed of multiple sessions) to a professor by creating individual sessions
  Future<bool> assignSchedule(String professorId, List<Map<String, dynamic>> sessions) async {
    _isLoading = true;
    notifyListeners();

    try {
      // Create each session individually via the API
      final createdSessions = <Map<String, dynamic>>[];
      
      for (final session in sessions) {
        // Parse the time slots to get actual DateTime values
        final now = DateTime.now();
        final sessionDate = now.add(Duration(days: (session['dayIndex'] as int) - now.weekday + 1));
        
        final timeParts = (session['startTime'] as String).split(':');
        final startTime = DateTime(
          sessionDate.year,
          sessionDate.month,
          sessionDate.day,
          int.parse(timeParts[0]),
          int.parse(timeParts[1]),
        );
        
        final endTimeParts = (session['endTime'] as String).split(':');
        final endTime = DateTime(
          sessionDate.year,
          sessionDate.month,
          sessionDate.day,
          int.parse(endTimeParts[0]),
          int.parse(endTimeParts[1]),
        );

        final response = await _apiClient.post('/sessions', {
          'courseName': session['course'],
          'startTime': startTime.toIso8601String(),
          'endTime': endTime.toIso8601String(),
          'groupId': session['groupId'],
          'labId': session['labId'],
          'professorId': professorId,
          'isRecurring': false,
        });

        if (response.statusCode == 200 || response.statusCode == 201) {
          createdSessions.add(session);
        } else {
          debugPrint('Failed to create session: ${response.body}');
          // Continue to try creating other sessions
        }
      }

      if (createdSessions.isNotEmpty) {
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Error assigning schedule: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}

