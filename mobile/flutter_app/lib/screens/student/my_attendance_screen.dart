import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../models/attendance_model.dart';
import '../../providers/presence_provider.dart';

class MyAttendanceScreen extends StatefulWidget {
  const MyAttendanceScreen({super.key});

  @override
  State<MyAttendanceScreen> createState() => _MyAttendanceScreenState();
}

class _MyAttendanceScreenState extends State<MyAttendanceScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PresenceProvider>().fetchMyAttendances();
    });
  }

  String _formatDateTime(DateTime dt) => DateFormat('MMM dd, yyyy  •  HH:mm').format(dt.toLocal());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        centerTitle: true,
        title: const Column(
          children: [
            Text('MY ATTENDANCE', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, letterSpacing: 1)),
            Text('Complete history of your حضور', style: TextStyle(fontSize: 10, color: Colors.white70, fontWeight: FontWeight.w400)),
          ],
        ),
      ),
      body: Consumer<PresenceProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading && provider.myAttendances.isEmpty) {
            return const Center(child: CircularProgressIndicator(color: AppColors.primary));
          }

          final myAttendances = provider.myAttendances;

          if (myAttendances.isEmpty) {
            return _buildEmptyState();
          }

          return Column(
            children: [
              _buildStatsModule(myAttendances.length),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: () => provider.fetchMyAttendances(),
                  child: ListView.separated(
                    padding: const EdgeInsets.all(20),
                    itemCount: myAttendances.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) => _buildAttendanceCard(myAttendances[index]),
                  ),
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
            child: const Icon(Icons.history_rounded, size: 52, color: AppColors.textLight),
          ),
          const SizedBox(height: 24),
          const Text('No classes attended yet', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: AppColors.textPrimary)),
          const SizedBox(height: 8),
          const Text('Scan QR codes in class to see logs here.', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
        ],
      ),
    );
  }

  Widget _buildStatsModule(int total) {
    const goal = 20;
    final progress = (total / goal).clamp(0.0, 1.0);
    final percent = (progress * 100).toInt();

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(32), bottomRight: Radius.circular(32)),
        boxShadow: AppColors.softShadow,
      ),
      child: Row(
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 70, height: 70,
                child: CircularProgressIndicator(
                  value: progress,
                  strokeWidth: 8,
                  backgroundColor: AppColors.background,
                  color: AppColors.primary,
                ),
              ),
              Text('$percent%', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: AppColors.textPrimary)),
            ],
          ),
          const SizedBox(width: 24),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('$total SESSIONS COMPLETED', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: AppColors.textLight, letterSpacing: 1)),
                const SizedBox(height: 4),
                const Text('Keep it up! Your attendance rate is excellent.', style: TextStyle(fontSize: 13, color: AppColors.textSecondary, fontWeight: FontWeight.w600, height: 1.3)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAttendanceCard(AttendanceModel att) {
    final time = att.checkedInAt != null ? _formatDateTime(att.checkedInAt!) : 'N/A';
    final isQr = att.method == AttendanceMethod.qr;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppColors.softShadow,
        border: Border.all(color: AppColors.border.withOpacity(0.5)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: AppColors.success.withOpacity(0.1), borderRadius: BorderRadius.circular(14)),
              child: Icon(isQr ? Icons.qr_code_scanner_rounded : Icons.check_circle_rounded, color: AppColors.success, size: 20),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(att.courseName ?? 'Academic Session', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: AppColors.textPrimary)),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.location_on_rounded, size: 12, color: AppColors.textLight),
                      const SizedBox(width: 4),
                      Text(att.labName ?? 'Verified Hall', style: const TextStyle(fontSize: 11, color: AppColors.textLight, fontWeight: FontWeight.w600)),
                    ],
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                _statusBadge(att.status),
                const SizedBox(height: 8),
                Text(time.split('•').last.trim(), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: AppColors.primary)),
                Text(time.split('•').first.trim(), style: const TextStyle(fontSize: 9, color: AppColors.textLight, fontWeight: FontWeight.w700)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _statusBadge(String status) {
    final color = status.toLowerCase() == 'present' ? AppColors.success : AppColors.danger;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
      child: Text(status.toUpperCase(), style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: color, letterSpacing: 0.5)),
    );
  }
}
