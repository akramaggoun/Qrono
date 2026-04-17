import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/admin_provider.dart';

class EntityStatsScreen extends StatefulWidget {
  final String entityId;
  final String type; // student, professor, group, lab
  final String title;

  const EntityStatsScreen({
    super.key,
    required this.entityId,
    required this.type,
    required this.title,
  });

  @override
  State<EntityStatsScreen> createState() => _EntityStatsScreenState();
}

class _EntityStatsScreenState extends State<EntityStatsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<AdminProvider>(context, listen: false).fetchEntityStats(widget.type, widget.entityId);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('${widget.type.toUpperCase()} ANALYTICS', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14, letterSpacing: 1.5)),
        centerTitle: true,
      ),
      body: Consumer<AdminProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator(color: AppColors.primary));
          }

          final stats = provider.currentEntityStats;
          if (stats == null) {
            return Center(child: Text(provider.errorMessage ?? 'Failed to load statistics'));
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(),
                const SizedBox(height: 32),
                if (widget.type == 'student') _buildStudentStats(stats),
                if (widget.type == 'professor') _buildProfessorStats(stats),
                if (widget.type == 'group') _buildGroupStats(stats),
                if (widget.type == 'lab') _buildLabStats(stats),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: AppColors.primaryGradient, begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(24),
        boxShadow: AppColors.softShadow,
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: Colors.white.withOpacity(0.1), shape: BoxShape.circle),
            child: Icon(_getIcon(), color: Colors.white, size: 32),
          ),
          const SizedBox(height: 16),
          Text(widget.title, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
          const SizedBox(height: 4),
          Text(widget.type.toUpperCase(), style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1.5)),
        ],
      ),
    );
  }

  IconData _getIcon() {
    switch (widget.type) {
      case 'student': return Icons.person_rounded;
      case 'professor': return Icons.school_rounded;
      case 'group': return Icons.groups_rounded;
      case 'lab': return Icons.science_rounded;
      default: return Icons.analytics_rounded;
    }
  }

  Widget _buildStudentStats(Map<String, dynamic> stats) {
    final rate = double.tryParse(stats['attendanceRate'].toString()) ?? 0;
    return Column(
      children: [
        _buildStatCard('ATTENDANCE RATE', '${rate.toInt()}%', rate / 100, AppColors.success),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(child: _buildMiniCard('PRESENT', '${stats['attendedCount']}', AppColors.success)),
            const SizedBox(width: 16),
            Expanded(child: _buildMiniCard('ABSENT', '${stats['absenceCount']}', AppColors.danger)),
          ],
        ),
        const SizedBox(height: 16),
        _buildMiniCard('TOTAL SESSIONS', '${stats['totalSessions']}', AppColors.primary),
      ],
    );
  }

  Widget _buildProfessorStats(Map<String, dynamic> stats) {
    final rate = double.tryParse(stats['avgAttendanceRate'].toString()) ?? 0;
    return Column(
      children: [
        _buildStatCard('AVG. STUDENT PARTICIPATION', '${rate.toInt()}%', rate / 100, AppColors.info),
        const SizedBox(height: 16),
        _buildMiniCard('SESSIONS CONDUCTED', '${stats['sessionCount']}', AppColors.primary),
        const SizedBox(height: 16),
        _buildMiniCard('TOTAL STUDENTS ENGAGED', '${stats['totalStudentsEngaged']}', AppColors.success),
      ],
    );
  }

  Widget _buildGroupStats(Map<String, dynamic> stats) {
    final rate = double.tryParse(stats['globalAttendanceRate'].toString()) ?? 0;
    return Column(
      children: [
        _buildStatCard('GLOBAL GROUP ATTENDANCE', '${rate.toInt()}%', rate / 100, AppColors.accent),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(child: _buildMiniCard('STUDENTS', '${stats['studentCount']}', AppColors.primary)),
            const SizedBox(width: 16),
            Expanded(child: _buildMiniCard('SESSIONS', '${stats['totalSessions']}', AppColors.info)),
          ],
        ),
        const SizedBox(height: 16),
        _buildMiniCard('TOTAL CHECK-INS', '${stats['totalAttendances']}', AppColors.success),
      ],
    );
  }

  Widget _buildLabStats(Map<String, dynamic> stats) {
    return Column(
      children: [
        _buildMiniCard('FACILITY USAGE (SESSIONS)', '${stats['usageCount']}', AppColors.primary),
        const SizedBox(height: 16),
        _buildMiniCard('TOTAL SCANS RECORDED', '${stats['totalScans']}', AppColors.success),
        const SizedBox(height: 16),
        _buildMiniCard('UNAUTHORIZED ATTEMPTS', '${stats['unauthorizedCount']}', AppColors.danger),
      ],
    );
  }

  Widget _buildStatCard(String label, String value, double progress, Color color) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), boxShadow: AppColors.softShadow),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: AppColors.textLight, letterSpacing: 1.5)),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(value, style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: color)),
              Icon(Icons.trending_up_rounded, color: color),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(value: progress, minHeight: 8, backgroundColor: AppColors.background, valueColor: AlwaysStoppedAnimation<Color>(color)),
          ),
        ],
      ),
    );
  }

  Widget _buildMiniCard(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: AppColors.border.withOpacity(0.5))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: AppColors.textLight, letterSpacing: 1)),
          const SizedBox(height: 8),
          Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: color)),
        ],
      ),
    );
  }
}
