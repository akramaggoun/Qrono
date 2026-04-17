import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../models/attendance_model.dart';
import '../../providers/presence_provider.dart';

class AttendanceListScreen extends StatefulWidget {
  final String courseName;
  final String sessionId;

  const AttendanceListScreen(
      {super.key, required this.courseName, required this.sessionId});

  @override
  State<AttendanceListScreen> createState() => _AttendanceListScreenState();
}

class _AttendanceListScreenState extends State<AttendanceListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PresenceProvider>().fetchSessionAttendance(widget.sessionId);
    });
  }

  String _formatTime(DateTime dt) => DateFormat('HH:mm').format(dt.toLocal());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        centerTitle: true,
        title: Column(
          children: [
            const Text('ATTENDANCE LIST', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
            Text(widget.courseName, style: const TextStyle(fontSize: 10, color: Colors.white70, fontWeight: FontWeight.w400, letterSpacing: 1)),
          ],
        ),
      ),
      body: Consumer<PresenceProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator(color: AppColors.primary));
          }

          final attendances = provider.attendances;
          final meta = provider.attendanceData;
          final total = meta?['totalStudents'] ?? attendances.length;
          final present = meta?['presentCount'] ?? attendances.length;

          if (attendances.isEmpty) {
            return _buildEmptyState();
          }

          return Column(
            children: [
              _buildStatsHeader(present, total),
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.all(20),
                  itemCount: attendances.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) => _buildStudentCard(attendances[index]),
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
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.05), shape: BoxShape.circle),
            child: const Icon(Icons.person_search_rounded, size: 64, color: AppColors.textLight),
          ),
          const SizedBox(height: 24),
          const Text('No records found', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 20, color: AppColors.textPrimary)),
          const SizedBox(height: 8),
          const Text('Waiting for students to scan the QR code...', style: TextStyle(fontSize: 14, color: AppColors.textSecondary)),
        ],
      ),
    );
  }

  Widget _buildStatsHeader(int present, int total) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              const Icon(Icons.people_alt_rounded, color: AppColors.primary, size: 20),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('$present / $total Students', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: AppColors.textPrimary)),
                  const Text('Attendance Summary', style: TextStyle(fontSize: 10, color: AppColors.textLight, fontWeight: FontWeight.w600)),
                ],
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(color: AppColors.success.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
            child: const Text('LIVE SYNCED', style: TextStyle(color: AppColors.success, fontSize: 10, fontWeight: FontWeight.w900)),
          ),
        ],
      ),
    );
  }

  Widget _buildStudentCard(AttendanceModel record) {
    final name = record.studentName ?? 'Unknown Student';
    final urn = record.urn ?? 'N/A';
    final isPresent = record.status.toLowerCase() == 'present';
    final time = record.checkedInAt != null ? _formatTime(record.checkedInAt!) : 'Not Registered';
    final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isPresent ? AppColors.success.withOpacity(0.2) : AppColors.danger.withOpacity(0.2)),
        boxShadow: AppColors.softShadow,
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            gradient: isPresent 
              ? const LinearGradient(
                  colors: AppColors.primaryGradient, 
                  begin: Alignment.topLeft, 
                  end: Alignment.bottomRight
                ) 
              : null,
            color: isPresent ? null : Colors.grey.shade300,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Center(
            child: Text(initial, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 18)),
          ),
        ),
        title: Text(name, style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15, color: isPresent ? AppColors.textPrimary : AppColors.textLight)),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Row(
            children: [
              Icon(Icons.badge_rounded, size: 12, color: isPresent ? AppColors.textLight : Colors.grey.withOpacity(0.5)),
              const SizedBox(width: 4),
              Text(urn, style: TextStyle(fontSize: 12, color: isPresent ? AppColors.textLight : Colors.grey.withOpacity(0.5), fontWeight: FontWeight.w600)),
            ],
          ),
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: isPresent ? AppColors.success.withOpacity(0.1) : AppColors.danger.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                isPresent ? time : 'ABSENT',
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 10,
                  color: isPresent ? AppColors.success : AppColors.danger,
                ),
              ),
              if (isPresent)
                const Text('CHECK-IN', style: TextStyle(fontSize: 7, color: AppColors.success, fontWeight: FontWeight.w800)),
            ],
          ),
        ),
      ),
    );
  }
}
