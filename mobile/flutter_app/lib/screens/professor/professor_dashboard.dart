import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../models/session_model.dart';

import 'my_sessions_screen.dart';
import 'my_schedules_screen.dart';
import 'live_session_screen.dart';
import '../notification_screen.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/notification_provider.dart';
import '../../providers/session_provider.dart';
import '../../models/schedule_model.dart';
import '../auth/login_screen.dart';

class ProfessorDashboard extends StatefulWidget {
  const ProfessorDashboard({super.key});

  @override
  State<ProfessorDashboard> createState() => _ProfessorDashboardState();
}

class _ProfessorDashboardState extends State<ProfessorDashboard> {
  static const List<String> _dayNames = [
    '', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'
  ];

  static const List<String> _dayNamesFull = [
    '', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'
  ];

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

      final sessionProvider = Provider.of<SessionProvider>(context, listen: false);
      sessionProvider.fetchMySessions();
      sessionProvider.fetchSchedules();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Consumer<SessionProvider>(
        builder: (context, sessionProvider, child) {
          final authProvider = Provider.of<AuthProvider>(context);
          
          return CustomScrollView(
            slivers: [
              _buildSliverAppBar(authProvider),
              SliverToBoxAdapter(
                child: RefreshIndicator(
                  onRefresh: () async {
                    await sessionProvider.fetchMySessions();
                    await sessionProvider.fetchSchedules();
                  },
                  child: Column(
                    children: [
                      _buildQuickActions(),
                      _buildStatsSection(sessionProvider.sessions),
                      _buildScheduleSection(sessionProvider),
                      _buildRecentHistory(sessionProvider),
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
                child: Icon(Icons.school, size: 200, color: Colors.white.withOpacity(0.05)),
              ),
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      const Text(
                        'PROFESSOR PORTAL',
                        style: TextStyle(color: Colors.white60, fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 2),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Welcome, ${auth.userName ?? "Professor"}',
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

  Widget _buildQuickActions() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Row(
        children: [
          _buildActionItem(
            'PLANNING',
            Icons.event_note_rounded,
            () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MySchedulesScreen())),
            AppColors.primary,
          ),
          const SizedBox(width: 16),
          _buildActionItem(
            'HISTORY',
            Icons.history_edu_rounded,
            () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MySessionsScreen())),
            AppColors.accent,
          ),
        ],
      ),
    );
  }

  Widget _buildActionItem(String title, IconData icon, VoidCallback onTap, Color color) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: AppColors.softShadow,
          ),
          child: Column(
            children: [
              Icon(icon, color: color, size: 32),
              const SizedBox(height: 12),
              Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12, letterSpacing: 1, color: AppColors.textPrimary),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatsSection(List sessions) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader('QUICK INSIGHTS'),
          const SizedBox(height: 16),
          Row(
            children: [
              _statTile('Lectures', sessions.length.toString(), Icons.play_lesson_rounded),
              const SizedBox(width: 12),
              _statTile('Attendance', _calculateTotal(sessions), Icons.group_add_rounded),
            ],
          ),
        ],
      ),
    );
  }

  String _calculateTotal(List sessions) {
    num total = 0;
    for (var s in sessions) total += (s.attendanceCount ?? 0);
    return total.toString();
  }

  Widget _statTile(String label, String value, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border.withOpacity(0.5)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(12)),
              child: Icon(icon, color: AppColors.primary, size: 20),
            ),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(value, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: AppColors.textPrimary)),
                Text(label, style: const TextStyle(fontSize: 10, color: AppColors.textLight, fontWeight: FontWeight.w600)),
              ],
            )
          ],
        ),
      ),
    );
  }

  // ─── SCHEDULE SECTION ─── Shows ALL schedules always, GO LIVE for matching ones
  Widget _buildScheduleSection(SessionProvider provider) {
    if (provider.schedules.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionHeader('MY SCHEDULE'),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.border.withOpacity(0.5)),
              ),
              child: Column(
                children: [
                  Icon(Icons.event_busy_rounded, size: 48, color: AppColors.textLight.withOpacity(0.4)),
                  const SizedBox(height: 12),
                  const Text('No scheduled classes', style: TextStyle(color: AppColors.textLight, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          ],
        ),
      );
    }

    // Group schedules by dayOfWeek
    final Map<int, List<ScheduleModel>> byDay = {};
    for (var s in provider.schedules) {
      final day = s.dayOfWeek ?? 0;
      byDay.putIfAbsent(day, () => []).add(s);
    }
    final sortedDays = byDay.keys.toList()..sort();

    final now = DateTime.now();
    final todayWeekday = now.weekday; // Monday=1 … Friday=5 … Sunday=7

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader('MON EMPLOI DU TEMPS'),
          const SizedBox(height: 16),
          ...sortedDays.map((day) {
            final isToday = day == todayWeekday;
            final daySchedules = byDay[day]!;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Day header
                Container(
                  margin: const EdgeInsets.only(bottom: 8, top: 4),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: isToday ? AppColors.primary : AppColors.background,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          (day >= 1 && day <= 7) ? _dayNamesFull[day].toUpperCase() : 'DAY $day',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.2,
                            color: isToday ? Colors.white : AppColors.textLight,
                          ),
                        ),
                      ),
                      if (isToday) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.success.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text('TODAY', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: AppColors.success, letterSpacing: 1)),
                        ),
                      ],
                    ],
                  ),
                ),
                ...daySchedules.map((s) => _buildScheduleCard(s, isToday, now, provider)),
                const SizedBox(height: 8),
              ],
            );
          }),
        ],
      ),
    );
  }

  Widget _buildScheduleCard(ScheduleModel s, bool isToday, DateTime now, SessionProvider provider) {
    bool isClosedToday = false;
    if (isToday) {
      for (var session in provider.sessions) {
        if (session.scheduleId == s.id && session.status == SessionStatus.CLOSED) {
          if (session.startTime.year == now.year && session.startTime.month == now.month && session.startTime.day == now.day) {
            isClosedToday = true;
            break;
          }
        }
      }
    }

    final isLive = !isClosedToday && _checkIsLive(s, isToday, now);
    final isUpcoming = !isClosedToday && _checkIsUpcoming(s, isToday, now);

    Color cardColor = Colors.white;
    Color borderColor = AppColors.border;
    double borderWidth = 1;

    if (isLive) {
      cardColor = AppColors.primary.withOpacity(0.05);
      borderColor = AppColors.primary;
      borderWidth = 2;
    } else if (isUpcoming) {
      cardColor = AppColors.accent.withOpacity(0.03);
      borderColor = AppColors.accent.withOpacity(0.4);
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: borderColor, width: borderWidth),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: isLive ? AppColors.primary : (isUpcoming ? AppColors.accent.withOpacity(0.1) : AppColors.background),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(
            isLive ? Icons.sensors_rounded : (isClosedToday ? Icons.check_circle_rounded : (isUpcoming ? Icons.timer_outlined : Icons.event_available_rounded)),
            color: isLive ? Colors.white : (isClosedToday ? AppColors.success : (isUpcoming ? AppColors.accent : AppColors.textLight)),
          ),
        ),
        title: Text(s.name, style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.textPrimary, fontSize: 14)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 2),
            Text(
              '${s.startTime ?? '--'} - ${s.endTime ?? '--'}',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: isLive ? AppColors.primary : AppColors.textSecondary,
              ),
            ),
            if (s.groupName != null)
              Text('${s.groupName} • ${s.labName ?? ''}', style: const TextStyle(fontSize: 11, color: AppColors.textLight)),
          ],
        ),
        trailing: SizedBox(
          width: isLive ? 90 : (isClosedToday ? 85 : 60),
          child: isLive
            ? ElevatedButton(
                onPressed: () => _startLiveSession(s),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                ),
                child: const Text('GO LIVE', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900)),
              )
            : isClosedToday
              ? Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 5),
                  decoration: BoxDecoration(color: AppColors.success.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                  child: const Center(child: Text('COMPLETED', style: TextStyle(fontSize: 8, fontWeight: FontWeight.w900, color: AppColors.success, letterSpacing: 0.5))),
                )
              : isUpcoming
                ? Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 5),
                    decoration: BoxDecoration(color: AppColors.accent.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                    child: const Center(child: Text('SOON', style: TextStyle(fontSize: 8, fontWeight: FontWeight.w900, color: AppColors.accent, letterSpacing: 0.5))),
                  )
                : const Center(child: Icon(Icons.check_circle_outline_rounded, size: 18, color: AppColors.textLight)),
        ),
      ),
    );
  }

  // Live = same day AND within the time window
  bool _checkIsLive(ScheduleModel s, bool isToday, DateTime now) {
    if (!isToday) return false;
    if (s.startTime == null || s.endTime == null) return false;
    final current = '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
    return current.compareTo(s.startTime!) >= 0 && current.compareTo(s.endTime!) <= 0;
  }

  // Upcoming = same day AND hasn't started yet (within 2 hours)
  bool _checkIsUpcoming(ScheduleModel s, bool isToday, DateTime now) {
    if (!isToday) return false;
    if (s.startTime == null) return false;
    final current = '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
    if (current.compareTo(s.startTime!) >= 0) return false; // already started or passed
    // Check within 2 hours
    final parts = s.startTime!.split(':');
    if (parts.length != 2) return false;
    final startHour = int.tryParse(parts[0]) ?? 0;
    final startMin = int.tryParse(parts[1]) ?? 0;
    final startMinutes = startHour * 60 + startMin;
    final currentMinutes = now.hour * 60 + now.minute;
    return (startMinutes - currentMinutes) <= 120;
  }

  Widget _buildRecentHistory(SessionProvider provider) {
    final sessions = provider.sessions.take(3).toList();
    if (sessions.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _sectionHeader('RECENT SESSIONS'),
              TextButton(onPressed: () {}, child: const Text('View All', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800))),
            ],
          ),
          const SizedBox(height: 8),
          ...sessions.map((s) => _buildHistoryRow(s)),
        ],
      ),
    );
  }

  Widget _buildHistoryRow(SessionModel s) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.border.withOpacity(0.5))),
      child: ListTile(
        leading: const CircleAvatar(backgroundColor: AppColors.background, child: Icon(Icons.history, color: AppColors.primary, size: 20)),
        title: Text(s.courseName, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
        subtitle: Text('${s.groupName} • ${s.labName}', style: const TextStyle(fontSize: 11)),
        trailing: Text('${s.attendanceCount ?? 0} PAX', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: AppColors.primary)),
      ),
    );
  }

  Widget _sectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: AppColors.textLight, letterSpacing: 1.5),
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

  void _startLiveSession(ScheduleModel schedule) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => LiveSessionScreen(schedule: schedule)));
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('Sign Out?', style: TextStyle(fontWeight: FontWeight.w900)),
        content: const Text('Are you sure you want to end your session?'),
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
