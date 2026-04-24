import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/presence_provider.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/auth_provider.dart';
import 'package:easy_localization/easy_localization.dart';

class StudentStatsAdminScreen extends StatefulWidget {
  final String studentId;
  final String studentName;
  final String? courseName; // Added for professor exclusion feature

  const StudentStatsAdminScreen({
    super.key, 
    required this.studentId,
    required this.studentName,
    this.courseName,
  });

  @override
  State<StudentStatsAdminScreen> createState() => _StudentStatsAdminScreenState();
}

class _StudentStatsAdminScreenState extends State<StudentStatsAdminScreen> {
  Map<String, dynamic>? _stats;
  bool _isLoading = true;
  bool _isExcluded = false;
  bool _isExclusionLoading = false;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    final provider = Provider.of<PresenceProvider>(context, listen: false);
    final data = await provider.fetchStudentStats(widget.studentId);
    
    if (mounted) {
      setState(() {
        _stats = data;
        _isLoading = false;
      });
      
      // Check exclusion status if we have a courseName and user is professor
      final auth = Provider.of<AuthProvider>(context, listen: false);
      if (widget.courseName != null && auth.userRole == 'professor' && _stats != null) {
        final recordId = _stats!['student']['id'];
        final excluded = await provider.isStudentExcluded(recordId, widget.courseName!);
        if (mounted) setState(() => _isExcluded = excluded);
      }
    }
  }

  Future<void> _toggleExclusion() async {
    if (widget.courseName == null || _stats == null) return;
    
    setState(() => _isExclusionLoading = true);
    final provider = Provider.of<PresenceProvider>(context, listen: false);
    final recordId = _stats!['student']['id'];
    
    final success = await provider.toggleExclusion(recordId, widget.courseName!, !_isExcluded);
    
    if (mounted) {
      setState(() {
        if (success) _isExcluded = !_isExcluded;
        _isExclusionLoading = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(_isExcluded ? 'student_excluded_success'.tr() : 'student_included_success'.tr()),
        backgroundColor: _isExcluded ? Colors.redAccent : Colors.green,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(widget.studentName, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _stats == null
              ? Center(child: Text('error_occurred'.tr()))
              : RefreshIndicator(
                  onRefresh: _loadStats,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildHeader(),
                        const SizedBox(height: 25),
                        _buildSummaryCards(),
                        const SizedBox(height: 30),
                        Text('sessions_history'.tr(), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 15),
                        _buildAttendanceList(),
                      ],
                    ),
                  ),
                ),
    );
  }

  Widget _buildHeader() {
    final student = _stats!['student'];
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10)],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: AppColors.primaryTeal.withOpacity(0.1),
            child: const Icon(Icons.person, color: AppColors.primaryTeal, size: 30),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(student['name'], style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                Text(student['email'], style: const TextStyle(color: AppColors.grayText, fontSize: 13)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.primaryTeal.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(student['groupName'], style: const TextStyle(color: AppColors.primaryTeal, fontSize: 11, fontWeight: FontWeight.bold)),
                    ),
                    if (widget.courseName != null && Provider.of<AuthProvider>(context, listen: false).userRole == 'professor') ...[
                      const SizedBox(width: 10),
                      GestureDetector(
                        onTap: _isExclusionLoading ? null : _toggleExclusion,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: _isExcluded ? Colors.red.withOpacity(0.1) : Colors.grey.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: _isExcluded ? Colors.red : Colors.grey),
                          ),
                          child: Row(
                            children: [
                              if (_isExclusionLoading) 
                                const SizedBox(width: 12, height: 12, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.red))
                              else
                                Icon(_isExcluded ? Icons.block : Icons.check_circle_outline, size: 12, color: _isExcluded ? Colors.red : Colors.grey),
                              const SizedBox(width: 4),
                              Text(
                                _isExcluded ? 'excluded'.tr() : 'exclude'.tr(),
                                style: TextStyle(color: _isExcluded ? Colors.red : Colors.grey, fontSize: 11, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCards() {
    final present = _stats!['presentCount'];
    final absent = _stats!['absentCount'];
    final total = _stats!['totalScheduled'];
    final rate = total > 0 ? (present / total * 100).round() : 0;

    return Column(
      children: [
        Row(
          children: [
            Expanded(child: _buildStatCard('present'.tr(), '$present', Icons.check_circle_rounded, Colors.green)),
            const SizedBox(width: 15),
            Expanded(child: _buildStatCard('absences_count'.tr(), '$absent', Icons.cancel_rounded, Colors.redAccent)),
          ],
        ),
        const SizedBox(height: 15),
        Row(
          children: [
            Expanded(child: _buildStatCard('total'.tr(), '$total', Icons.calendar_today_rounded, Colors.blue)),
            const SizedBox(width: 15),
            Expanded(child: _buildStatCard('rate'.tr(), '$rate%', Icons.analytics_rounded, Colors.orange)),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 8)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 12),
          Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          Text(title, style: const TextStyle(color: AppColors.grayText, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildAttendanceList() {
    final attendances = _stats!['attendances'] as List;
    if (attendances.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 40),
          child: Text('no_presence_recorded'.tr(), style: const TextStyle(color: AppColors.grayText)),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: attendances.length,
      itemBuilder: (context, index) {
        final a = attendances[index];
        final session = a['session'];
        final date = DateTime.parse(a['checkInAt']).toLocal();
        final dateStr = '${date.day}/${date.month} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.borderColor),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: (a['method'] == 'qr' ? Colors.green : Colors.orange).withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  a['method'] == 'qr' ? Icons.qr_code : Icons.person_add_alt_1,
                  color: a['method'] == 'qr' ? Colors.green : Colors.orange,
                  size: 20,
                ),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(session['courseName'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    Text(session['lab']['name'], style: const TextStyle(color: AppColors.grayText, fontSize: 12)),
                  ],
                ),
              ),
              Text(dateStr, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
            ],
          ),
        );
      },
    );
  }
}
