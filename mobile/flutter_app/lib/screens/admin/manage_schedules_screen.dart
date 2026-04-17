import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../models/schedule_model.dart';
import '../../models/user_model.dart';
import '../../providers/admin_provider.dart';

class ManageSchedulesScreen extends StatefulWidget {
  const ManageSchedulesScreen({super.key});

  @override
  State<ManageSchedulesScreen> createState() => _ManageSchedulesScreenState();
}

class _ManageSchedulesScreenState extends State<ManageSchedulesScreen> {
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<AdminProvider>(context, listen: false);
      provider.fetchSchedules();
      provider.fetchUsers();
      provider.fetchGroups();
      provider.fetchLaboratories();
    });
  }

  String _getDayName(int? day) {
    if (day == null) return 'Unknown';
    const days = ['', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    return days[day];
  }

  void _showScheduleDialog({ScheduleModel? schedule}) {
    final adminProvider = Provider.of<AdminProvider>(context, listen: false);
    final isEditing = schedule != null;

    final nameCtrl = TextEditingController(text: schedule?.name ?? '');
    final descCtrl = TextEditingController(text: schedule?.description ?? '');
    final startCtrl = TextEditingController(text: schedule?.startTime ?? '08:00');
    final endCtrl = TextEditingController(text: schedule?.endTime ?? '09:30');

    String? selectedProfId = schedule?.professorId;
    String? selectedGroupId = schedule?.groupId;
    String? selectedLabId = schedule?.labId;
    int selectedDay = schedule?.dayOfWeek ?? 1;
    bool isActive = schedule?.isActive ?? true;

    final professors = adminProvider.users.where((u) => u.role == UserRole.professor).toList();
    final groups = adminProvider.groups;
    final labs = adminProvider.laboratories;

    if (selectedProfId == null && professors.isNotEmpty) selectedProfId = professors[0].profileId;
    if (selectedGroupId == null && groups.isNotEmpty) selectedGroupId = groups[0].id;
    if (selectedLabId == null && labs.isNotEmpty) selectedLabId = labs[0].id;

    final formKey = GlobalKey<FormState>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(32))),
      builder: (context) => StatefulBuilder(
        builder: (ctx, setSheet) => Padding(
          padding: EdgeInsets.only(left: 24, right: 24, top: 32, bottom: MediaQuery.of(ctx).viewInsets.bottom + 32),
          child: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                   Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: AppColors.divider, borderRadius: BorderRadius.circular(2)))),
                  const SizedBox(height: 24),
                  Text(isEditing ? 'Update Schedule Slot' : 'Create New Lecture Slot', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: AppColors.textPrimary)),
                  const SizedBox(height: 24),
                  _label('SESSION TITLE'),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: nameCtrl,
                    decoration: const InputDecoration(hintText: 'e.g. Advanced Algorithm TP', prefixIcon: Icon(Icons.title_rounded, size: 20)),
                    validator: (v) => (v == null || v.isEmpty) ? 'Required field' : null,
                  ),
                  const SizedBox(height: 20),
                  _label('DESCRIPTION (OPTIONAL)'),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: descCtrl,
                    decoration: const InputDecoration(hintText: 'Additional details or objectives...', prefixIcon: Icon(Icons.notes_rounded, size: 20)),
                  ),
                  const SizedBox(height: 20),
                  _label('ASSIGNED TEACHER'),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: selectedProfId,
                    decoration: const InputDecoration(prefixIcon: Icon(Icons.school_rounded, size: 20)),
                    items: professors.map((p) => DropdownMenuItem(value: p.profileId, child: Text(p.fullName))).toList(),
                    onChanged: (v) => setSheet(() => selectedProfId = v),
                    validator: (v) => v == null ? 'Teacher selection required' : null,
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _label('TARGET GROUP'),
                            const SizedBox(height: 8),
                            DropdownButtonFormField<String>(
                              value: selectedGroupId,
                              decoration: const InputDecoration(prefixIcon: Icon(Icons.groups_rounded, size: 20)),
                              items: groups.map((g) => DropdownMenuItem(value: g.id, child: Text(g.name, style: const TextStyle(fontSize: 12)))).toList(),
                              onChanged: (v) => setSheet(() => selectedGroupId = v),
                              validator: (v) => v == null ? 'Required' : null,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _label('FACILITY / LAB'),
                            const SizedBox(height: 8),
                            DropdownButtonFormField<String>(
                              value: selectedLabId,
                              decoration: const InputDecoration(prefixIcon: Icon(Icons.meeting_room_rounded, size: 20)),
                              items: labs.map((l) => DropdownMenuItem(value: l.id, child: Text(l.name, style: const TextStyle(fontSize: 12)))).toList(),
                              onChanged: (v) => setSheet(() => selectedLabId = v),
                              validator: (v) => v == null ? 'Required' : null,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  _label('DAY OF THE WEEK'),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<int>(
                    value: selectedDay,
                    decoration: const InputDecoration(prefixIcon: Icon(Icons.calendar_month_rounded, size: 20)),
                    items: const [
                      DropdownMenuItem(value: 1, child: Text('Monday')),
                      DropdownMenuItem(value: 2, child: Text('Tuesday')),
                      DropdownMenuItem(value: 3, child: Text('Wednesday')),
                      DropdownMenuItem(value: 4, child: Text('Thursday')),
                      DropdownMenuItem(value: 5, child: Text('Friday')),
                      DropdownMenuItem(value: 6, child: Text('Saturday')),
                    ],
                    onChanged: (v) => setSheet(() => selectedDay = v!),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _label('START TIME'),
                            const SizedBox(height: 8),
                            TextFormField(
                              controller: startCtrl,
                              readOnly: true,
                              decoration: const InputDecoration(prefixIcon: Icon(Icons.access_time_filled_rounded, size: 20)),
                              onTap: () async {
                                final time = await showTimePicker(context: context, initialTime: const TimeOfDay(hour: 8, minute: 0));
                                if (time != null) {
                                  final formatted = '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
                                  startCtrl.text = formatted;
                                  final endH = (time.hour + 1) % 24;
                                  final endM = (time.minute + 30) % 60;
                                  endCtrl.text = '${endH.toString().padLeft(2, '0')}:${endM.toString().padLeft(2, '0')}';
                                  setSheet(() {});
                                }
                              },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _label('END TIME'),
                            const SizedBox(height: 8),
                            TextFormField(
                              controller: endCtrl,
                              readOnly: true,
                              decoration: const InputDecoration(prefixIcon: Icon(Icons.timer_off_rounded, size: 20)),
                              onTap: () async {
                                final time = await showTimePicker(context: context, initialTime: const TimeOfDay(hour: 9, minute: 30));
                                if (time != null) {
                                  endCtrl.text = '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
                                  setSheet(() {});
                                }
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  _label('AVAILABILITY'),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(16)),
                    child: Row(
                      children: [
                        const Icon(Icons.check_circle_rounded, color: AppColors.success, size: 20),
                        const SizedBox(width: 12),
                        const Expanded(child: Text('Active Slot', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: AppColors.textPrimary))),
                        Switch(value: isActive, activeColor: AppColors.success, onChanged: (v) => setSheet(() => isActive = v)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 18), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                      onPressed: () async {
                        if (!formKey.currentState!.validate()) return;
                        final data = {
                          'name': nameCtrl.text,
                          'description': descCtrl.text,
                          'professorId': selectedProfId,
                          'groupId': selectedGroupId,
                          'labId': selectedLabId,
                          'dayOfWeek': selectedDay,
                          'startTime': startCtrl.text,
                          'endTime': endCtrl.text,
                          'isActive': isActive,
                        };
                        bool success = isEditing ? await adminProvider.updateSchedule(schedule.id, data) : await adminProvider.addSchedule(data);
                        if (success && mounted) {
                          Navigator.pop(ctx);
                          _showSnack(isEditing ? 'Schedule record updated' : 'Lecture slot created', AppColors.success);
                        }
                      },
                      child: Text(isEditing ? 'UPDATE RECORD' : 'CREATE RECORD', style: const TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('CANCEL', style: TextStyle(color: AppColors.textLight, fontWeight: FontWeight.w800))),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _confirmDelete(ScheduleModel schedule) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('Remove Lecture Slot?', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18)),
        content: Text('The schedule entry "${schedule.name}" will be permanently removed.', style: const TextStyle(fontSize: 14, color: AppColors.textSecondary)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('CANCEL', style: TextStyle(color: AppColors.textLight, fontWeight: FontWeight.w800))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            onPressed: () async {
              final success = await Provider.of<AdminProvider>(context, listen: false).deleteSchedule(schedule.id);
              if (success && mounted) {
                Navigator.pop(context);
                _showSnack('Entry removed successfully', AppColors.success);
              }
            },
            child: const Text('REMOVE', style: TextStyle(fontWeight: FontWeight.w900)),
          ),
        ],
      ),
    );
  }

  void _showSnack(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: const TextStyle(fontWeight: FontWeight.w700)),
      backgroundColor: color,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }

  Widget _label(String text) => Text(text, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: AppColors.textLight, letterSpacing: 1));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        centerTitle: true,
        title: const Text('ACADEMIC SCHEDULE', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, letterSpacing: 1)),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showScheduleDialog(),
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add_task_rounded, color: Colors.white),
      ),
      body: Consumer<AdminProvider>(
        builder: (context, provider, child) {
          final filtered = provider.schedules.where((s) => s.name.toLowerCase().contains(_query.toLowerCase())).toList();
          if (provider.isLoading && provider.schedules.isEmpty) {
            return const Center(child: CircularProgressIndicator(color: AppColors.primary));
          }

          return Column(
            children: [
              Container(
                color: Colors.white,
                padding: const EdgeInsets.all(20),
                child: TextField(
                  controller: _searchController,
                  onChanged: (v) => setState(() => _query = v),
                  decoration: InputDecoration(
                    hintText: 'Search by session name or subject...',
                    prefixIcon: const Icon(Icons.search_rounded, size: 20),
                    suffixIcon: _query.isNotEmpty ? IconButton(icon: const Icon(Icons.cancel_rounded, size: 20), onPressed: () => setState(() { _query = ''; _searchController.clear(); })) : null,
                    filled: true,
                    fillColor: AppColors.background,
                  ),
                ),
              ),
              Expanded(
                child: filtered.isEmpty
                    ? _buildEmptyState()
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
                        itemCount: filtered.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (context, index) => _buildScheduleCard(filtered[index]),
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.calendar_month_rounded, size: 64, color: AppColors.textLight.withOpacity(0.3)),
          const SizedBox(height: 16),
          const Text('No schedule entries found', style: TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.w700, fontSize: 16)),
        ],
      ),
    );
  }

  Widget _buildScheduleCard(ScheduleModel s) {
    final isActive = s.isActive ?? true;
    return Container(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: isActive ? AppColors.border.withOpacity(0.5) : AppColors.danger.withOpacity(0.2)), boxShadow: AppColors.softShadow),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              children: [
                Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: AppColors.accent.withOpacity(0.1), borderRadius: BorderRadius.circular(16)), child: const Icon(Icons.event_note_rounded, color: AppColors.accent, size: 24)),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(s.name, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: AppColors.textPrimary)),
                      if (s.description != null && s.description!.isNotEmpty) Text(s.description!, style: const TextStyle(fontSize: 11, color: AppColors.textLight, fontWeight: FontWeight.w500)),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(color: AppColors.accent.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                  child: Text(_getDayName(s.dayOfWeek).toUpperCase(), style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: AppColors.accent, letterSpacing: 0.5)),
                ),
              ],
            ),
            const Padding(padding: EdgeInsets.symmetric(vertical: 16), child: Divider(height: 1)),
            Row(
              children: [
                _buildMetaItem(Icons.access_time_filled_rounded, '${s.startTime} - ${s.endTime}'),
                const SizedBox(width: 16),
                _buildMetaItem(Icons.person_3_rounded, s.professorName ?? 'Unassigned'),
                const Spacer(),
                IconButton(icon: const Icon(Icons.edit_note_rounded, color: AppColors.info, size: 24), onPressed: () => _showScheduleDialog(schedule: s)),
                IconButton(icon: const Icon(Icons.delete_sweep_rounded, color: AppColors.danger, size: 24), onPressed: () => _confirmDelete(s)),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _buildMetaItem(Icons.groups_3_rounded, s.groupName ?? 'No Cohort'),
                const SizedBox(width: 16),
                _buildMetaItem(Icons.door_front_door_rounded, s.labName ?? 'No Room'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetaItem(IconData icon, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: AppColors.textLight),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, fontWeight: FontWeight.w600)),
      ],
    );
  }
}
