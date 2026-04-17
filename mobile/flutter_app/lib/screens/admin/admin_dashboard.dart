import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import 'manage_users_screen.dart';
import 'manage_labs_screen.dart';
import 'manage_groups_screen.dart';
import 'manage_schedules_screen.dart';
import 'unauthorized_logs_screen.dart';
import '../notification_screen.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/notification_provider.dart';
import '../auth/login_screen.dart';
import '../../providers/admin_provider.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<AdminProvider>(context, listen: false);
      provider.fetchStatistics();
      provider.startAutoRefresh(const Duration(seconds: 5)); // Start auto-refresh
      Provider.of<NotificationProvider>(context, listen: false).fetchNotifications();
    });
  }

  @override
  void dispose() {
    // Ensure timer stops when leaving the dashboard
    Provider.of<AdminProvider>(context, listen: false).stopAutoRefresh();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        centerTitle: true,
        title: const Column(
          children: [
            Text('ADMIN CONSOLE', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, letterSpacing: 1.5)),
            Text('Central Control & Monitoring', style: TextStyle(fontSize: 10, color: Colors.white70, fontWeight: FontWeight.w400)),
          ],
        ),
        actions: [
          Consumer<NotificationProvider>(
            builder: (context, provider, child) => IconButton(
              icon: Badge(
                isLabelVisible: provider.unreadCount > 0,
                label: Text('${provider.unreadCount}'),
                child: const Icon(Icons.notifications_none_rounded, color: Colors.white),
              ),
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationScreen())),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.power_settings_new_rounded, color: Colors.white),
            onPressed: () => _showLogoutDialog(context),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Consumer<AdminProvider>(
        builder: (context, adminProvider, child) {
          if (adminProvider.isLoading && adminProvider.statistics.isEmpty) {
            return const Center(child: CircularProgressIndicator(color: AppColors.primary));
          }

          final stats = adminProvider.statistics;

          return RefreshIndicator(
            onRefresh: () async {
              await adminProvider.fetchStatistics();
              await Provider.of<NotificationProvider>(context, listen: false).fetchNotifications();
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeroHeader(adminProvider),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _sectionHeader('System Overview'),
                        const SizedBox(height: 16),
                        _buildStatsGrid(stats, adminProvider),
                        const SizedBox(height: 32),
                        _sectionHeader('Attendance Analytics'),
                        const SizedBox(height: 16),
                        _buildAttendanceCard(adminProvider),
                        const SizedBox(height: 32),
                        _sectionHeader('System Management'),
                        const SizedBox(height: 16),
                        _buildNavigationList(),
                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeroHeader(AdminProvider provider) {
    final name = Provider.of<AuthProvider>(context).userName ?? 'Administrator';
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(40), bottomRight: Radius.circular(40)),
        boxShadow: AppColors.activeShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: Colors.white.withOpacity(0.2),
                child: const Icon(Icons.admin_panel_settings_rounded, color: Colors.white, size: 28),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Welcome back,', style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 12, fontWeight: FontWeight.w600)),
                  Text(name, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 32),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(color: Colors.white.withOpacity(0.12), borderRadius: BorderRadius.circular(24), border: Border.all(color: Colors.white.withOpacity(0.2))),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('${provider.statistics['activeSessions'] ?? 0} LIVE SESSIONS', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 16, letterSpacing: 0.5)),
                      Text('Actively monitoring campus activity', style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 11, fontWeight: FontWeight.w500)),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(color: AppColors.success, shape: BoxShape.circle),
                  child: const Icon(Icons.sensors_rounded, color: Colors.white, size: 16),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsGrid(Map<String, dynamic> stats, AdminProvider provider) {
    final items = [
      _StatItem('Teachers', provider.totalProfessors.toString(), Icons.school_rounded, AppColors.primary),
      _StatItem('Students', provider.totalStudents.toString(), Icons.people_alt_rounded, AppColors.info),
      _StatItem('Groups', provider.totalGroups.toString(), Icons.hub_rounded, AppColors.warning),
      _StatItem('Sessions', provider.todaySessions.toString(), Icons.calendar_today_rounded, AppColors.success),
      _StatItem('Presence', provider.todayAttendance.toString(), Icons.verified_user_rounded, AppColors.success),
      _StatItem('Alerts', stats['unauthorizedToday']?.toString() ?? '0', Icons.gpp_maybe_rounded, AppColors.danger),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, crossAxisSpacing: 16, mainAxisSpacing: 16, childAspectRatio: 1.5),
      itemCount: items.length,
      itemBuilder: (_, i) => _buildStatCard(items[i]),
    );
  }

  Widget _buildStatCard(_StatItem item) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), boxShadow: AppColors.softShadow, border: Border.all(color: AppColors.border.withOpacity(0.5))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: item.color.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
            child: Icon(item.icon, color: item.color, size: 20),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(item.value, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 22, color: AppColors.textPrimary)),
              Text(item.label, style: const TextStyle(fontSize: 10, color: AppColors.textLight, fontWeight: FontWeight.w800, letterSpacing: 0.5)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAttendanceCard(AdminProvider provider) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), boxShadow: AppColors.softShadow, border: Border.all(color: AppColors.border.withOpacity(0.5))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Daily Attendance Rate', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
              Text('${provider.attendanceRate.toInt()}%', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AppColors.primary)),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: provider.attendanceRate / 100,
              backgroundColor: AppColors.background,
              color: provider.attendanceRate >= 70 ? AppColors.success : AppColors.warning,
              minHeight: 10,
            ),
          ),
          const SizedBox(height: 12),
          Text('${provider.todayAttendance} students registered today', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildNavigationList() {
    final items = [
      _NavItem('User Management', 'Manage student and teacher accounts', Icons.person_search_rounded, AppColors.primary, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ManageUsersScreen()))),
      _NavItem('Lab Resources', 'Control auditoriums and laboratory access', Icons.science_rounded, AppColors.info, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ManageLabsScreen()))),
      _NavItem('Academic Groups', 'Organize student sections and levels', Icons.layers_rounded, AppColors.warning, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ManageGroupsScreen()))),
      _NavItem('Schedules & Plans', 'Academic calendar and time allocations', Icons.auto_graph_rounded, AppColors.accent, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ManageSchedulesScreen()))),
      _NavItem('Security Logs', 'View unauthorized access attempts', Icons.shield_rounded, AppColors.danger, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const UnauthorizedLogsScreen()))),
    ];

    return Column(children: items.map((i) => _buildNavTile(i)).toList());
  }

  Widget _buildNavTile(_NavItem item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: AppColors.border.withOpacity(0.5)), boxShadow: AppColors.softShadow),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: item.color.withOpacity(0.1), borderRadius: BorderRadius.circular(14)),
          child: Icon(item.icon, color: item.color, size: 22),
        ),
        title: Text(item.title, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: AppColors.textPrimary)),
        subtitle: Text(item.subtitle, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary, fontWeight: FontWeight.w500)),
        trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppColors.textLight),
        onTap: item.onTap,
      ),
    );
  }

  Widget _sectionHeader(String title) {
    return Text(title.toUpperCase(), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: AppColors.textLight, letterSpacing: 1.5));
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('Sign Out', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18)),
        content: const Text('Are you sure you want to exit the admin console?', style: TextStyle(fontSize: 14, color: AppColors.textSecondary)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('CANCEL', style: TextStyle(color: AppColors.textLight, fontWeight: FontWeight.w800))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            onPressed: () async {
              Navigator.pop(ctx);
              await Provider.of<AuthProvider>(context, listen: false).logout();
              if (mounted) Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute(builder: (_) => const LoginScreen()), (route) => false);
            },
            child: const Text('LOGOUT', style: TextStyle(fontWeight: FontWeight.w900)),
          ),
        ],
      ),
    );
  }
}

class _StatItem {
  final String label, value;
  final IconData icon;
  final Color color;
  const _StatItem(this.label, this.value, this.icon, this.color);
}

class _NavItem {
  final String title, subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  const _NavItem(this.title, this.subtitle, this.icon, this.color, this.onTap);
}
