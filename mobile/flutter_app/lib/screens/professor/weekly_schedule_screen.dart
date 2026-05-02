import 'package:flutter/material.dart';
import 'dart:convert';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/network/api_client.dart';
import '../../../../mock/schedule_mock_data.dart';
import '../../../../core/widgets/schedule_grid.dart';
import '../../models/session_model.dart';
import 'show_qr_screen.dart';
import 'package:easy_localization/easy_localization.dart';

class WeeklyScheduleScreen extends StatefulWidget {
  final String professorId;

  const WeeklyScheduleScreen({super.key, required this.professorId});

  @override
  State<WeeklyScheduleScreen> createState() => _WeeklyScheduleScreenState();
}

class _WeeklyScheduleScreenState extends State<WeeklyScheduleScreen> {
  late List<Map<String, dynamic>> _mySessions;
  final ApiClient _apiClient = ApiClient();
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _mySessions = [];
    _fetchSessions();
  }

  Future<void> _fetchSessions() async {
    setState(() => _isLoading = true);
    
    try {
      final response = await _apiClient.get('/sessions/my-sessions');
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final sessions = List<Map<String, dynamic>>.from(data['sessions'] ?? []);
        
        if (sessions.isEmpty) {
          setState(() {
            _mySessions = [];
            _isLoading = false;
          });
          return;
        }
        
        // Convert backend sessions to grid format
        setState(() {
          _mySessions = sessions.map((session) {
            final startTime = DateTime.parse(session['startTime']).toLocal();
            final endTime = DateTime.parse(session['endTime']).toLocal();
            int dayIndex;
            if (startTime.weekday == 7) {
              dayIndex = 0;
            } else if (startTime.weekday >= 1 && startTime.weekday <= 4) {
              dayIndex = startTime.weekday;
            } else {
              dayIndex = -1; // Outside mock range
            }
            
            final hour = startTime.hour;
            final minute = startTime.minute;
            int slotIndex = 0;
            if (hour >= 8) slotIndex = 0; 
            if (hour > 9 || (hour == 9 && minute >= 30)) slotIndex = 1; 
            if (hour >= 11) slotIndex = 2;
            if (hour > 12 || (hour == 12 && minute >= 30)) slotIndex = 3;
            if (hour >= 14) slotIndex = 4;
            if (hour > 15 || (hour == 15 && minute >= 30)) slotIndex = 5;
            
            return {
              'id': session['id'],
              'course': session['courseName'],
              'groupId': session['group']['id'],
              'groupName': session['group']['name'],
              'labId': session['lab']['id'],
              'labName': session['lab']['name'],
              'qr_token': session['qr_code']?['token'] ?? "",
              'day': dayIndex != -1 ? ScheduleMockData.weekDays[dayIndex] : 'Unknown',
              'startTime': '${startTime.hour.toString().padLeft(2, '0')}:${startTime.minute.toString().padLeft(2, '0')}',
              'endTime': '${endTime.hour.toString().padLeft(2, '0')}:${endTime.minute.toString().padLeft(2, '0')}',
              'fullStartTime': startTime,
              'fullEndTime': endTime,
              'dayIndex': dayIndex,
              'slotIndex': slotIndex,
            };
          }).where((session) => session['dayIndex'] != -1).toList();
          _isLoading = false;
        });
      } else {
        setState(() {
          _mySessions = [];
          _isLoading = false;
        });
        throw Exception('Failed to fetch sessions: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error fetching sessions from database: $e');
      setState(() {
        _mySessions = [];
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('my_schedule'.tr(), style: const TextStyle(color: Colors.black87)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primaryTeal),
            )
          : _mySessions.isEmpty
              ? Center(
                  child: Text(
                    'no_assigned_sessions'.tr(),
                    style: const TextStyle(color: AppColors.grayText, fontSize: 16),
                    textAlign: TextAlign.center,
                  ),
                )
              : Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: ScheduleGrid(
                    isAdmin: false,
                    sessions: _mySessions,
                    onEmptyCellTap: (_, _) { }, // Non-interactive
                    onFilledCellTap: _handleSessionTap,
                  ),
                ),
    );
  }

  void _handleSessionTap(Map<String, dynamic> session) {
    // Determine if session is valid to start based on real time.
    final now = DateTime.now();
    int currentDayIndex = _getCurrentDayIndex(now);
    
    // If not today
    if (session['dayIndex'] != currentDayIndex) {
      _showWarningDialog(session);
      return;
    }

    // If today, check time
    final startTimeStr = session['startTime'] as String;
    final endTimeStr = session['endTime'] as String;
    
    final startParts = startTimeStr.split(':');
    final endParts = endTimeStr.split(':');
    
    final sessionStart = DateTime(now.year, now.month, now.day, int.parse(startParts[0]), int.parse(startParts[1]));
    final sessionEnd = DateTime(now.year, now.month, now.day, int.parse(endParts[0]), int.parse(endParts[1]));

    if (now.isBefore(sessionStart)) {
      _showWarningDialog(session);
    } else if (now.isAfter(sessionEnd)) {
      _showExpiredDialog(session);
    } else {
      _showStartSessionSheet(session);
    }
  }

  int _getCurrentDayIndex(DateTime date) {
    int weekday = date.weekday;
    if (weekday == 7) return 0; // Sun
    if (weekday >= 1 && weekday <= 4) return weekday; // Mon-Thu
    return -1; // Fri/Sat
  }

  void _showWarningDialog(Map<String, dynamic> session) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: const Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 40),
        title: Text('session_not_started'.tr()),
        content: Text(
          'session_scheduled_future'.tr(args: [session['day'].toString().toLowerCase().tr(), session['startTime'], session['endTime']]),
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryTeal, elevation: 0),
            onPressed: () => Navigator.pop(ctx),
            child: Text('got_it'.tr(), style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showExpiredDialog(Map<String, dynamic> session) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: const Icon(Icons.history, color: Colors.grey, size: 40),
        title: Text('session_ended'.tr()),
        content: Text(
          'session_scheduled_past'.tr(args: [session['day'].toString().toLowerCase().tr(), session['startTime'], session['endTime']]),
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryTeal, elevation: 0),
            onPressed: () => Navigator.pop(ctx),
            child: Text('got_it'.tr(), style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showStartSessionSheet(Map<String, dynamic> session) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('start_session_title'.tr(), style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black87)),
              const SizedBox(height: 20),
              
              // Summary Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.cardColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.borderColor),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(session['course'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.black87)),
                    const SizedBox(height: 8),
                    Text('${'group_label'.tr()}${session['groupName']}', style: const TextStyle(color: AppColors.grayText)),
                    Text('${'room_label'.tr()}${session['labName']}', style: const TextStyle(color: AppColors.grayText)),
                    Text('${'time_label'.tr()}${session['startTime']} - ${session['endTime']}', style: const TextStyle(color: AppColors.primaryTeal, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
              const SizedBox(height: 30),

              Row(
                children: [
                   Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(ctx),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        side: const BorderSide(color: AppColors.grayText),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      child: Text('cancel'.tr(), style: const TextStyle(color: AppColors.grayText, fontSize: 16)),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(ctx);
                        
                        // Map the raw session data to SessionModel
                        final sessionData = _mySessions.firstWhere((s) => s['id'] == session['id']);
                        
                        final sessionModel = SessionModel(
                          id: sessionData['id'],
                          courseName: sessionData['course'] ?? '',
                          labId: sessionData['labId']?.toString() ?? '',
                          groupId: sessionData['groupId']?.toString() ?? '',
                          professorId: widget.professorId,
                          qrToken: sessionData['qr_token'],
                          startTime: sessionData['fullStartTime'],
                          endTime: sessionData['fullEndTime'],
                          isRecurring: false,
                          status: "ACTIVE",
                        );

                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ShowQrScreen(session: sessionModel),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryTeal,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        elevation: 0,
                      ),
                      child: Text('generate_qr_code'.tr(), style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

