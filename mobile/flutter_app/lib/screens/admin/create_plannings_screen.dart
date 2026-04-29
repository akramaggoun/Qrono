import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../mock/schedule_mock_data.dart';
import '../../../../core/widgets/schedule_grid.dart';
import '../../../../providers/schedule_provider.dart';

class CreatePlanningsScreen extends StatefulWidget {
  const CreatePlanningsScreen({super.key});

  @override
  State<CreatePlanningsScreen> createState() => _CreatePlanningsScreenState();
}

class _CreatePlanningsScreenState extends State<CreatePlanningsScreen> {
  String? _selectedProfessorId;
  List<Map<String, dynamic>> _currentSessions = [];

  @override
  void initState() {
    super.initState();
    Future.microtask(
      () => context.read<ScheduleProvider>().fetchLookups(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheduleProvider = Provider.of<ScheduleProvider>(context);
    
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('create_plannings'.tr(), style: const TextStyle(color: Colors.black87)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      body: Column(
        children: [
          _buildProfessorSelector(scheduleProvider),
          const Divider(height: 1, thickness: 1, color: AppColors.borderColor),
          Expanded(
            child: _selectedProfessorId == null
                ? Center(
                    child: Text(
                      'select_professor'.tr(),
                      style: const TextStyle(color: AppColors.grayText, fontSize: 16),
                      textAlign: TextAlign.center,
                    ),
                  )
                : Column(
                    children: [
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: ScheduleGrid(
                            isAdmin: true,
                            sessions: _currentSessions,
                            onEmptyCellTap: _showAddSessionSheet,
                            onFilledCellTap: _showEditSessionSheet,
                            onRemoveSession: _removeSession,
                          ),
                        ),
                      ),
                      _buildAssignButton(scheduleProvider),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfessorSelector(ScheduleProvider provider) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: provider.isLoading
          ? const Center(
              child: SizedBox(
                height: 50,
                child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation(AppColors.primaryTeal)),
              ),
            )
          : provider.professors.isEmpty
              ? Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.borderColor),
                    borderRadius: BorderRadius.circular(10),
                    color: AppColors.cardColor,
                  ),
                  child: const Text(
                    'No professors available. Please check your database connection.',
                    style: TextStyle(color: AppColors.grayText, fontSize: 14),
                    textAlign: TextAlign.center,
                  ),
                )
              : DropdownButtonFormField<Map<String, dynamic>>(
                  initialValue: provider.professors.any((p) => p['id'] == _selectedProfessorId) 
                    ? provider.professors.firstWhere((p) => p['id'] == _selectedProfessorId)
                    : null,
                  decoration: InputDecoration(
                    labelText: 'professor'.tr(),
                    labelStyle: const TextStyle(color: AppColors.primaryTeal),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: AppColors.borderColor),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: AppColors.primaryTeal),
                    ),
                    filled: true,
                    fillColor: AppColors.cardColor,
                  ),
                  items: provider.professors.map((prof) {
                    return DropdownMenuItem<Map<String, dynamic>>(
                      value: prof,
                      child: Text('${prof['name']} (${prof['department']})',
                          style: const TextStyle(fontSize: 14)),
                    );
                  }).toList(),
                  onChanged: (value) async {
                    if (value == null) return;
                    setState(() {
                      _selectedProfessorId = value['id'];
                      _currentSessions = [];
                    });
                    
                    // The Schedule and Session records in DB use the PROFESSOR PROFILE ID, 
                    // not the USER ID.
                    final profileId = value['professorProfileId'];
                    if (profileId != null) {
                      await provider.fetchProfessorSchedule(profileId);
                      
                      final List<Map<String, dynamic>> mappedSessions = [];
                      for (var s in provider.professorSessions) {
                        try {
                          // Handle both ISO strings from DB and potential mock data structures
                          final DateTime startTime = s['startTime'] is String 
                              ? DateTime.parse(s['startTime']).toLocal() 
                              : s['startTime'];
                          final DateTime endTime = s['endTime'] is String 
                              ? DateTime.parse(s['endTime']).toLocal() 
                              : s['endTime'];
                              
                          // Format to HH:mm string for comparison with ScheduleMockData.timeSlots
                          final startStr = "${startTime.hour.toString().padLeft(2, '0')}:${startTime.minute.toString().padLeft(2, '0')}";
                          final endStr = "${endTime.hour.toString().padLeft(2, '0')}:${endTime.minute.toString().padLeft(2, '0')}";
                          final timeRange = "$startStr - $endStr";
                          
                          int slotIdx = ScheduleMockData.timeSlots.indexOf(timeRange);
                          if (slotIdx == -1) {
                            // Try looser match if exact range doesn't exist
                            slotIdx = ScheduleMockData.timeSlots.indexWhere((slot) => slot.startsWith(startStr));
                          }
                          
                          if (slotIdx == -1) {
                             debugPrint("No matching slot for: $timeRange");
                             continue;
                          }
                          
                          // Convert DateTime weekday (1=Mon, 7=Sun) to our Mock index (0=Sun, 1=Mon...)
                          int dayIdx = startTime.weekday % 7; 
                          
                          mappedSessions.add({
                            'id': s['id'],
                            'course': s['courseName'] ?? s['course'] ?? 'Unknown',
                            'groupId': s['groupId'],
                            'groupName': s['group']?['name'] ?? s['groupName'] ?? 'Group',
                            'labId': s['labId'],
                            'labName': s['lab']?['name'] ?? s['labName'] ?? 'Lab',
                            'day': ScheduleMockData.weekDays[dayIdx],
                            'startTime': startStr,
                            'endTime': endStr,
                            'dayIndex': dayIdx,
                            'slotIndex': slotIdx,
                          });
                        } catch (e) {
                          debugPrint('Error mapping session to grid: $e');
                        }
                      }
                      setState(() {
                        _currentSessions = mappedSessions;
                      });
                    }
                  },
                ),
    );
  }

  Widget _buildAssignButton(ScheduleProvider provider) {
    bool canAssign = _currentSessions.isNotEmpty;
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: canAssign ? () => _confirmAssignment(provider) : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primaryTeal,
            disabledBackgroundColor: AppColors.grayText.withOpacity(0.3),
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            elevation: 0,
          ),
          child: Text('assign_schedule'.tr(),
              style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
        ),
      ),
    );
  }

  void _confirmAssignment(ScheduleProvider provider) {
    if (_selectedProfessorId == null) return;
    final prof = provider.professors.firstWhere((p) => p['id'] == _selectedProfessorId);
    
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('assign_schedule'.tr()),
        content: Text('Assign this schedule to ${prof['name']}? They will see it immediately on their account.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('cancel'.tr(), style: const TextStyle(color: AppColors.grayText)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryTeal,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Saving schedule to database...'),
                  backgroundColor: AppColors.primaryTeal,
                  duration: Duration(seconds: 2),
                ),
              );

              final success = await provider.assignSchedule(_selectedProfessorId!, _currentSessions);
              
              if (success) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Schedule assigned successfully to ${prof['name']}'),
                      backgroundColor: AppColors.primaryTeal,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                  
                  setState(() {
                    _selectedProfessorId = null;
                    _currentSessions = [];
                  });
                }
              } else {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Failed to save schedule. Please try again.'),
                      backgroundColor: Colors.red,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              }
            },
            child: const Text('Confirm', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showAddSessionSheet(int dayIndex, int slotIndex) {
    _showAddOrEditSessionSheet(dayIndex: dayIndex, slotIndex: slotIndex, isEdit: false);
  }

  void _showEditSessionSheet(Map<String, dynamic> session) {
    _showAddOrEditSessionSheet(
      dayIndex: session['dayIndex'],
      slotIndex: session['slotIndex'],
      isEdit: true,
      existingSession: session,
    );
  }

  void _removeSession(Map<String, dynamic> session) {
    setState(() {
      _currentSessions.removeWhere((s) => s['id'] == session['id']);
    });
  }

  void _showAddOrEditSessionSheet({
    required int dayIndex,
    required int slotIndex,
    required bool isEdit,
    Map<String, dynamic>? existingSession,
  }) {
    final provider = context.read<ScheduleProvider>();
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SessionFormSheet(
          dayIndex: dayIndex,
          slotIndex: slotIndex,
          isEdit: isEdit,
          existingSession: existingSession,
          groups: provider.groups,
          labs: provider.labs,
          onSave: (sessionData) {
            setState(() {
              if (isEdit) {
                int idx = _currentSessions.indexWhere((s) => s['id'] == sessionData['id']);
                if (idx != -1) {
                  _currentSessions[idx] = sessionData;
                }
              } else {
                _currentSessions.add(sessionData);
              }
            });
          },
        );
      },
    );
  }
}

class SessionFormSheet extends StatefulWidget {
  final int dayIndex;
  final int slotIndex;
  final bool isEdit;
  final Map<String, dynamic>? existingSession;
  final List<Map<String, dynamic>> groups;
  final List<Map<String, dynamic>> labs;
  final Function(Map<String, dynamic>) onSave;

  const SessionFormSheet({
    super.key,
    required this.dayIndex,
    required this.slotIndex,
    required this.isEdit,
    this.existingSession,
    required this.groups,
    required this.labs,
    required this.onSave,
  });

  @override
  State<SessionFormSheet> createState() => _SessionFormSheetState();
}

class _SessionFormSheetState extends State<SessionFormSheet> {
  final _formKey = GlobalKey<FormState>();
  final _courseController = TextEditingController();
  String? _selectedGroupId;
  String? _selectedLabId;

  @override
  void initState() {
    super.initState();
    if (widget.isEdit && widget.existingSession != null) {
      _courseController.text = widget.existingSession!['course'];
      _selectedGroupId = widget.existingSession!['groupId'];
      _selectedLabId = widget.existingSession!['labId'];
    }
  }

  @override
  void dispose() {
    _courseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final dayStr = ScheduleMockData.weekDays[widget.dayIndex];
    final slotStr = ScheduleMockData.timeSlots[widget.slotIndex];
    
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 20, 20, bottomInset + 20),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  widget.isEdit ? 'edit_session'.tr() : 'add_session'.tr(),
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: AppColors.grayText),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 10),
            
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              decoration: BoxDecoration(
                color: AppColors.primaryTeal.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '$dayStr · $slotStr',
                style: const TextStyle(color: AppColors.primaryTeal, fontWeight: FontWeight.bold, fontSize: 16),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 20),

            TextFormField(
              controller: _courseController,
              decoration: InputDecoration(
                labelText: 'course_name'.tr(),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: AppColors.primaryTeal),
                ),
              ),
              validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
            ),
            const SizedBox(height: 16),
            
            DropdownButtonFormField<String>(
              initialValue: _selectedGroupId,
              decoration: InputDecoration(
                labelText: 'select_group'.tr(),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
              items: widget.groups.isEmpty
                  ? [
                      const DropdownMenuItem(
                        value: null,
                        child: Text('No groups available', style: TextStyle(color: AppColors.grayText)),
                      )
                    ]
                  : widget.groups.map((g) => DropdownMenuItem(
                        value: g['id'] as String,
                        child: Text('${g['name']}${g['yearLevel'] != null ? " (Year ${g['yearLevel']})" : ""}'),
                      )).toList(),
              onChanged: widget.groups.isEmpty ? null : (v) => setState(() => _selectedGroupId = v),
              validator: (v) => v == null ? 'Required' : null,
            ),
            const SizedBox(height: 16),

            DropdownButtonFormField<String>(
              initialValue: _selectedLabId,
              decoration: InputDecoration(
                labelText: 'select_lab'.tr(),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
              items: widget.labs.isEmpty
                  ? [
                      const DropdownMenuItem(
                        value: null,
                        child: Text('No labs available', style: TextStyle(color: AppColors.grayText)),
                      )
                    ]
                  : widget.labs.map((l) => DropdownMenuItem(
                        value: l['id'] as String,
                        child: Text(l['name'] ?? 'Unknown Lab'),
                      )).toList(),
              onChanged: widget.labs.isEmpty ? null : (v) => setState(() => _selectedLabId = v),
              validator: (v) => v == null ? 'Required' : null,
            ),
            const SizedBox(height: 30),

            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      side: const BorderSide(color: AppColors.grayText),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: const Text('Cancel', style: TextStyle(color: AppColors.grayText, fontSize: 16)),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _saveSession,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryTeal,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      elevation: 0,
                    ),
                    child: Text(widget.isEdit ? 'update'.tr() : 'add'.tr(), style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _saveSession() {
    if (_formKey.currentState!.validate()) {
      final grp = widget.groups.firstWhere((g) => g['id'] == _selectedGroupId);
      final lab = widget.labs.firstWhere((l) => l['id'] == _selectedLabId);
      final times = ScheduleMockData.timeSlots[widget.slotIndex].split(' - ');
      
      final sessionData = {
        'id': widget.isEdit ? widget.existingSession!['id'] : 'sess_tmp_${DateTime.now().millisecondsSinceEpoch}',
        'course': _courseController.text.trim(),
        'groupId': _selectedGroupId,
        'groupName': grp['name'],
        'labId': _selectedLabId,
        'labName': lab['name'],
        'day': ScheduleMockData.weekDays[widget.dayIndex],
        'startTime': times[0],
        'endTime': times[1],
        'dayIndex': widget.dayIndex,
        'slotIndex': widget.slotIndex,
        'dayOfWeek': widget.dayIndex, // 0=Sun, 1=Mon, 2=Tue, 3=Wed, 4=Thu, 5=Fri, 6=Sat
      };

      widget.onSave(sessionData);
      Navigator.pop(context);
    }
  }
}
