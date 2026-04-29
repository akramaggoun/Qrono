import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../notification_screen.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/notification_provider.dart';
import '../../providers/presence_provider.dart';
import '../../providers/session_provider.dart';
import '../auth/login_screen.dart';
import '../../core/constants/app_colors.dart';
import 'scanner_screen.dart';
import 'my_attendance_screen.dart';

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
      Provider.of<SessionProvider>(context, listen: false).fetchStudentSessions();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFB),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        centerTitle: false,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('student_portal'.tr(), 
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF1A1C1E))),
            Text(Provider.of<AuthProvider>(context).userName ?? 'University Student', 
              style: const TextStyle(fontSize: 12, color: Color(0xFF6C757D), fontWeight: FontWeight.w500)),
          ],
        ),
        actions: [
          _buildNotificationIcon(),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: AppColors.primaryTeal),
            onPressed: () => _showLogoutDialog(context),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Consumer<PresenceProvider>(
        builder: (context, presenceProvider, child) {
          final attendances = presenceProvider.myAttendances;
          final presentCount = attendances.length;
          final totalSessions = Provider.of<SessionProvider>(context).sessions.length; 
          if (presenceProvider.isLoading && attendances.isEmpty) {
            return const Center(child: CircularProgressIndicator(color: AppColors.primaryTeal));
          }

          return RefreshIndicator(
            onRefresh: () async {
              final sessionProvider = Provider.of<SessionProvider>(context, listen: false);
              await presenceProvider.fetchMyAttendances();
              await sessionProvider.fetchStudentSessions();
            },
            color: AppColors.primaryTeal,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildWelcomeSection(),
                  const SizedBox(height: 25),
                  _buildQuickScanCard(context),
                  const SizedBox(height: 30),
                  _buildAttendanceIndicator(presentCount, totalSessions),
                  const SizedBox(height: 30),
                  _buildStatsSection(presenceProvider),
                  const SizedBox(height: 30),
                  _buildSectionHeader('your_recent_presence', 
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MyAttendanceScreen()))),
                  const SizedBox(height: 15),
                  _buildActivityList(attendances),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildNotificationIcon() {
    return Consumer<NotificationProvider>(
      builder: (context, provider, child) => Stack(
        alignment: Alignment.center,
        children: [
          Container(
            decoration: BoxDecoration(color: Colors.grey.withValues(alpha: 0.05), shape: BoxShape.circle),
            child: IconButton(
              icon: const Icon(Icons.notifications_none_rounded, color: Color(0xFF1A1C1E)),
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationScreen())),
            ),
          ),
          if (provider.unreadCount > 0)
            Positioned(
              top: 12, right: 12,
              child: Container(
                width: 10, height: 10,
                decoration: BoxDecoration(
                  color: Colors.redAccent,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildWelcomeSection() {
    final authProvider = Provider.of<AuthProvider>(context);
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('hello'.tr(), style: TextStyle(fontSize: 16, color: Color(0xFF9E9E9E), fontWeight: FontWeight.w500)),
              Text(authProvider.userName ?? 'Student', 
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Color(0xFF1A1C1E))),
            ],
          ),
        ),
        Container(
          height: 56, width: 56,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(colors: [AppColors.primaryTeal.withValues(alpha: 0.1), Colors.white]),
            border: Border.all(color: AppColors.primaryTeal.withValues(alpha: 0.2)),
          ),
          child: const Icon(Icons.person_pin_rounded, color: AppColors.primaryTeal, size: 32),
        ),
      ],
    );
  }

  Widget _buildQuickScanCard(BuildContext context) {
    return InkWell(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ScannerScreen())),
      borderRadius: BorderRadius.circular(28),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          gradient: const LinearGradient(
            colors: [AppColors.primaryTeal, Color(0xFF00796B)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(color: AppColors.primaryTeal.withValues(alpha: 0.3), blurRadius: 20, offset: const Offset(0, 10))
          ],
        ),
        child: Row(
          children: [
            const CircleAvatar(
              radius: 28,
              backgroundColor: Colors.white24,
              child: Icon(Icons.qr_code_scanner_rounded, color: Colors.white, size: 30),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('confirm_presence_title'.tr(), 
                    style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 4),
                  Text('tap_to_scan'.tr(), 
                    style: const TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w500)),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildAttendanceIndicator(int present, int total) {
    double progress = total > 0 ? (present / total) : 0.0;
    
    return InkWell(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MyAttendanceScreen())),
      borderRadius: BorderRadius.circular(24),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 12, offset: const Offset(0, 6))
          ],
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('attendance_overview'.tr(), 
                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppColors.grayText),
              ],
            ),
            const SizedBox(height: 20),
            Stack(
              children: [
                Container(height: 12, decoration: BoxDecoration(color: Colors.grey.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(6))),
                AnimatedContainer(
                  duration: const Duration(seconds: 1),
                  height: 12, width: (MediaQuery.of(context).size.width - 80) * progress,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [AppColors.primaryTeal, Color(0xFF4DB6AC)]),
                    borderRadius: BorderRadius.circular(6),
                    boxShadow: [BoxShadow(color: Colors.teal.withValues(alpha: 0.2), blurRadius: 6, offset: const Offset(0, 3))]
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('$present / $total ${'sessions_done'.tr()}', 
                      style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: Color(0xFF1A1C1E))),
                    Text('total_present_semester'.tr(), 
                      style: const TextStyle(fontSize: 11, color: Color(0xFF9E9E9E), fontWeight: FontWeight.w500)),
                  ],
                ),
                Text('${(progress * 100).round()}%', 
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: AppColors.primaryTeal)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsSection(PresenceProvider provider) {
    final sessionProvider = Provider.of<SessionProvider>(context);
    final totalScheduled = sessionProvider.sessions.length;
    final absences = totalScheduled - provider.myAttendances.length;
    final absencesSafe = absences < 0 ? 0 : absences;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('statistics_title'),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'attendance_streak'.tr(), 
                'days_streak'.tr(args: [provider.streak.toString()]),
                Icons.local_fire_department_rounded,
                Colors.orange,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                'absences_count'.tr(), 
                'total_absences'.tr(args: [absencesSafe.toString()]),
                Icons.event_busy_rounded,
                Colors.redAccent,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'top_course'.tr(), 
                provider.topCourse,
                Icons.emoji_events_rounded,
                Colors.amber,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                'weekly_attendance'.tr(), 
                'sessions_this_week'.tr(args: [provider.sessionsThisWeek.toString()]),
                Icons.bar_chart_rounded,
                AppColors.primaryTeal,
              ),
            ),
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
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 4))
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: color.withValues(alpha: 0.1), shape: BoxShape.circle),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(fontSize: 11, color: Colors.grey.shade600, fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text(value, 
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Color(0xFF1A1C1E)),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String titleKey, {VoidCallback? onTap}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(titleKey.tr(), 
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF1A1C1E))),
        if (onTap != null)
          TextButton(onPressed: onTap, child: Text('statistics_title'.tr(), style: const TextStyle(color: AppColors.primaryTeal, fontWeight: FontWeight.bold))),
      ],
    );
  }

  Widget _buildActivityList(List attendances) {
    if (attendances.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 40),
          child: Column(
            children: [
              Icon(Icons.history_toggle_off_rounded, size: 64, color: Colors.grey.withValues(alpha: 0.2)),
              const SizedBox(height: 16),
              Text('no_presence_recorded'.tr(), 
                style: TextStyle(color: Color(0xFF9E9E9E), fontSize: 14, fontWeight: FontWeight.w500)),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: attendances.take(5).length,
      itemBuilder: (context, index) {
        final a = attendances[index];
        final session = a['session'] ?? {};
        
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 8, offset: const Offset(0, 4))],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: Colors.green.withValues(alpha: 0.08), shape: BoxShape.circle),
                child: const Icon(Icons.check_circle_rounded, color: Colors.green, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(session['courseName'] ?? 'academic_session'.tr(), 
                      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: Color(0xFF1A1C1E))),
                    const SizedBox(height: 4),
                    Text('${session['lab']?['name'] ?? 'laboratory_title'.tr()} • ${'room'.tr()} ${session['lab']?['roomNumber'] ?? 'na'.tr()}',  
                      style: const TextStyle(fontSize: 12, color: Color(0xFF6C757D), fontWeight: FontWeight.w500)),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: Color(0xFFCFD8DC)),
            ],
          ),
        );
      },
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('logout_title'.tr()),
        content: Text('logout_confirm_msg'.tr()),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text('cancel'.tr())),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final authProvider = Provider.of<AuthProvider>(context, listen: false);
              final navigator = Navigator.of(context);
              await authProvider.logout();
              
              navigator.pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const LoginScreen()),
                (route) => false,
              );
            },
            child: Text('logout'.tr(), style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}



