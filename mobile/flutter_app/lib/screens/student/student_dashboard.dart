import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../providers/notification_provider.dart';
import '../../providers/presence_provider.dart';
import '../auth/login_screen.dart';
import '../notification_screen.dart';
import 'scanner_screen.dart';
import 'my_attendance_screen.dart';
import '../../models/attendance_model.dart';

class StudentDashboard extends StatefulWidget {
  const StudentDashboard({super.key});

  @override
  State<StudentDashboard> createState() => _StudentDashboardState();
}

class _StudentDashboardState extends State<StudentDashboard> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final notifProvider = Provider.of<NotificationProvider>(context, listen: false);

      if (authProvider.userId != null) {
        notifProvider.initSocket(authProvider.userId!);
      }
      notifProvider.fetchNotifications();
      Provider.of<PresenceProvider>(context, listen: false).fetchMyAttendances();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Consumer<PresenceProvider>(
        builder: (context, presenceProvider, child) {
          final authProvider = Provider.of<AuthProvider>(context);
          final attendances = presenceProvider.myAttendances;

          return CustomScrollView(
            slivers: [
              _buildSliverAppBar(authProvider),
              SliverToBoxAdapter(
                child: RefreshIndicator(
                  onRefresh: () => presenceProvider.fetchMyAttendances(),
                  child: Column(
                    children: [
                      _buildScanAction(),
                      _buildAttendanceGoal(attendances),
                      _buildRecentHistory(attendances),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSliverAppBar(AuthProvider auth) {
    return SliverAppBar(
      expandedHeight: 180,
      pinned: true,
      elevation: 0,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: AppColors.primaryGradient,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Stack(
            children: [
              Positioned(
                right: -20,
                bottom: -20,
                child: Icon(Icons.qr_code_scanner, size: 200, color: Colors.white.withOpacity(0.05)),
              ),
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      const Text(
                        'STUDENT PORTAL',
                        style: TextStyle(color: Colors.white60, fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 2),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Hello, ${auth.userName ?? "Student"}',
                        style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        _buildNotifIcon(),
        IconButton(
          icon: const Icon(Icons.power_settings_new_rounded),
          onPressed: () => _showLogoutDialog(context),
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildScanAction() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: GestureDetector(
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ScannerScreen())),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: AppColors.primaryGradient),
            borderRadius: BorderRadius.circular(24),
            boxShadow: AppColors.activeShadow,
          ),
          child: const Row(
            children: [
              Icon(Icons.qr_code_scanner_rounded, color: Colors.white, size: 40),
              SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('SCAN ATTENDANCE', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 16)),
                    Text('Point your camera at the lecture QR', style: TextStyle(color: Colors.white70, fontSize: 12)),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios_rounded, color: Colors.white38, size: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAttendanceGoal(List<AttendanceModel> attendances) {
    final provider = Provider.of<PresenceProvider>(context, listen: false);
    final stats = provider.attendanceData?['stats'];
    
    final totalSessions = stats?['totalSessions'] ?? attendances.length;
    final attendedCount = stats?['attendedCount'] ?? attendances.length;
    final absentCount = stats?['absentCount'] ?? 0;
    
    final double attendanceRate = double.tryParse(stats?['attendanceRate']?.toString() ?? '0') ?? 0;
    final double absenceRate = totalSessions > 0 ? (absentCount / totalSessions) * 100 : 0;
    final int percent = attendanceRate.toInt();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('PRESENCE ANALYTICS', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: AppColors.textLight, letterSpacing: 1.5)),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), boxShadow: AppColors.softShadow),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('$percent%', style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: percent > 75 ? AppColors.success : AppColors.primary)),
                        const Text('Personal Attendance Rate', style: TextStyle(fontSize: 12, color: AppColors.textLight)),
                      ],
                    ),
                    const Icon(Icons.insights_rounded, color: AppColors.background, size: 48),
                  ],
                ),
                const SizedBox(height: 20),
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: LinearProgressIndicator(
                    value: totalSessions > 0 ? (attendedCount / totalSessions) : 0,
                    minHeight: 12,
                    backgroundColor: AppColors.background,
                    valueColor: AlwaysStoppedAnimation<Color>(percent > 75 ? AppColors.success : AppColors.primary),
                  ),
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: AppColors.background.withOpacity(0.5), borderRadius: BorderRadius.circular(16)),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _enhancedMiniStat('${attendedCount}', 'PRESENT', AppColors.success),
                      Container(width: 1, height: 20, color: AppColors.border),
                      _enhancedMiniStat('${absentCount}', 'ABSENT', AppColors.danger),
                      Container(width: 1, height: 20, color: AppColors.border),
                      _enhancedMiniStat('${absenceRate.toStringAsFixed(1)}%', 'MISSING', AppColors.textLight),
                    ],
                  ),
                )
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _enhancedMiniStat(String val, String label, Color color) {
    return Column(
      children: [
        Text(val, style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: color)),
        Text(label, style: const TextStyle(fontSize: 9, color: AppColors.textLight, fontWeight: FontWeight.w800)),
      ],
    );
  }

  Widget _miniStat(String val, String label) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(val, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: AppColors.textPrimary)),
        Text(label, style: const TextStyle(fontSize: 10, color: AppColors.textLight, fontWeight: FontWeight.w600)),
      ],
    );
  }

  Widget _buildRecentHistory(List<AttendanceModel> attendances) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('RECENT ACTIVITY', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: AppColors.textLight, letterSpacing: 1.5)),
              TextButton(onPressed: () {}, child: const Text('View All', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800))),
            ],
          ),
          const SizedBox(height: 8),
          attendances.isEmpty
            ? _buildEmptyHistory()
            : Column(children: attendances.take(4).map((a) => _buildHistoryItem(a)).toList()),
        ],
      ),
    );
  }

  Widget _buildHistoryItem(AttendanceModel a) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.border.withOpacity(0.5))),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: AppColors.success.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
          child: const Icon(Icons.check_circle_rounded, color: AppColors.success, size: 20),
        ),
        title: Text(a.courseName ?? 'Academic Session', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
        subtitle: Text(a.labName ?? 'Verified Location', style: const TextStyle(fontSize: 12)),
        trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppColors.textLight),
      ),
    );
  }

  Widget _buildEmptyHistory() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: AppColors.border)),
      child: const Column(
        children: [
          Icon(Icons.history_rounded, color: AppColors.textLight, size: 32),
          SizedBox(height: 12),
          Text('No attendance records found yet.', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
        ],
      ),
    );
  }

  Widget _buildNotifIcon() {
    return Consumer<NotificationProvider>(
      builder: (context, provider, child) => Stack(
        alignment: Alignment.center,
        children: [
          IconButton(
            icon: const Icon(Icons.notifications_none_rounded, color: Colors.white),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationScreen())),
          ),
          if (provider.unreadCount > 0)
            Positioned(top: 12, right: 12, child: Container(width: 8, height: 8, decoration: const BoxDecoration(color: AppColors.danger, shape: BoxShape.circle))),
        ],
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('Sign Out?', style: TextStyle(fontWeight: FontWeight.w900)),
        content: const Text('Are you sure you want to end your dashboard session?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            onPressed: () async {
              Navigator.pop(ctx);
              await Provider.of<AuthProvider>(context, listen: false).logout();
              if (mounted) Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const LoginScreen()), (r) => false);
            },
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }
}
