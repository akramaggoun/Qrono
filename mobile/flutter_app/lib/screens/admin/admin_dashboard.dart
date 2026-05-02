import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../core/constants/app_colors.dart';
import 'manage_users_screen.dart';
import 'manage_labs_screen.dart';
import 'manage_groups_screen.dart';
import 'unauthorized_logs_screen.dart';
import '../notification_screen.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/notification_provider.dart';
import '../auth/login_screen.dart';
import '../../providers/admin_provider.dart';
import 'create_plannings_screen.dart';

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
      Provider.of<AdminProvider>(context, listen: false).fetchStatistics();
      Provider.of<NotificationProvider>(context, listen: false).fetchNotifications();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('control_hub_title'.tr(), style: const TextStyle(color: Colors.black87)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
        actions: [
          IconButton(
            tooltip: 'logout'.tr(),
            icon: const Icon(Icons.logout, color: Colors.redAccent),
            onPressed: () => _showLogoutDialog(context),
          ),
          Consumer<NotificationProvider>(
            builder: (context, provider, child) => Stack(
              alignment: Alignment.center,
              children: [
                IconButton(
                  tooltip: 'notifications'.tr(),
                  icon: const Icon(Icons.notifications_none_outlined, color: Colors.black87),
                  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationScreen())),
                ),
                if (provider.unreadCount > 0)
                  Positioned(
                    top: 10, right: 10,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: const BoxDecoration(color: Colors.redAccent, shape: BoxShape.circle),
                      constraints: const BoxConstraints(minWidth: 10, minHeight: 10),
                      child: Text(
                        provider.unreadCount > 9 ? '9+' : '${provider.unreadCount}',
                        style: const TextStyle(color: Colors.white, fontSize: 7, fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.black87), 
            onPressed: () => Provider.of<AdminProvider>(context, listen: false).fetchStatistics()
          ),
        ],
      ),
      body: Consumer<AdminProvider>(
        builder: (context, adminProvider, child) {
          if (adminProvider.isLoading && adminProvider.statistics.isEmpty) {
            return const Center(child: CircularProgressIndicator(color: AppColors.primaryTeal));
          }
          
          final stats = adminProvider.statistics;

          return RefreshIndicator(
            onRefresh: () async {
              final notifProvider = Provider.of<NotificationProvider>(context, listen: false);
              await adminProvider.fetchStatistics();
              await notifProvider.fetchNotifications();
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildAdminProfile(),
                  const SizedBox(height: 30),

                  // Unified Statistics Section
                  _buildUnifiedStats(stats, adminProvider),
                  const SizedBox(height: 40),

                  // Management Grid
                  Text('plannings_title'.tr(), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
                  const SizedBox(height: 15),
                  _buildActionTile('create_plannings_title'.tr(), 'build_professor_schedules'.tr(), Icons.calendar_view_week, Colors.orangeAccent, () => Navigator.push(context, MaterialPageRoute(builder: (context) => const CreatePlanningsScreen()))),
                  const SizedBox(height: 30),

                  Text('ecosystem_management'.tr(), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
                  const SizedBox(height: 15),
                  _buildManagementGrid(),

                  const SizedBox(height: 30),
                  // Quick Status
                  _buildQuickSecurityStatus(stats['unauthorizedToday']?.toString() ?? '0'),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildAdminProfile() {
    final name = Provider.of<AuthProvider>(context).userName ?? 'Admin';
    return Row(
      children: [
        CircleAvatar(radius: 28, backgroundColor: Colors.purple.withValues(alpha: 0.1), child: const Icon(Icons.admin_panel_settings, color: Colors.purple)),
        const SizedBox(width: 15),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('welcome_back'.tr(), style: const TextStyle(color: AppColors.grayText, fontSize: 13)),
            Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: Colors.black87)),
          ],
        ),
      ],
    );
  }

  Widget _buildUnifiedStats(Map<String, dynamic> stats, AdminProvider provider) {
    final activeLabs = (stats['laboratories'] is List ? (stats['laboratories'] as List).length : 0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Hero card: Active Sessions
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF00C9A7), Color(0xFF0099FF)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(22),
            boxShadow: [BoxShadow(color: AppColors.primaryTeal.withValues(alpha: 0.3), blurRadius: 20, offset: const Offset(0, 8))],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('active_sessions_count'.tr(), style: const TextStyle(color: Colors.white70, fontSize: 14)),
                  const SizedBox(height: 4),
                  Text(stats['activeSessions']?.toString() ?? '0', style: const TextStyle(color: Colors.white, fontSize: 42, fontWeight: FontWeight.bold, height: 1.0)),
                  const SizedBox(height: 4),
                  Text('realtime_monitor'.tr(), style: const TextStyle(color: Colors.white60, fontSize: 12)),
                ],
              ),
              const Icon(Icons.flash_on_rounded, color: Colors.white, size: 52),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Row 1: Professors & Students
        Row(
          children: [
            _buildStatCard('professors_label'.tr(), provider.totalProfessors.toString(), Icons.school, const Color(0xFF6C63FF)),
            const SizedBox(width: 12),
            _buildStatCard('students_label'.tr(), provider.totalStudents.toString(), Icons.school_outlined, AppColors.primaryTeal),
          ],
        ),
        const SizedBox(height: 12),

        // Row 2: Groups & Today Sessions
        Row(
          children: [
            _buildStatCard('groups_label'.tr(), provider.totalGroups.toString(), Icons.people_alt, const Color(0xFFFF9800)),
            const SizedBox(width: 12),
            _buildStatCard('today_sessions_label'.tr(), provider.todaySessions.toString(), Icons.event_available, const Color(0xFF2196F3)),
          ],
        ),
        const SizedBox(height: 12),

        // Row 3: Attendance & Security Alerts
        Row(
          children: [
            _buildStatCard('today_attendance'.tr(), provider.todayAttendance.toString(), Icons.check_circle_outline, Colors.green),
            const SizedBox(width: 12),
            _buildStatCard('security_alerts'.tr(), stats['unauthorizedToday']?.toString() ?? '0', Icons.gpp_maybe, Colors.redAccent),
          ],
        ),
        const SizedBox(height: 12),

        // Row 4: Total Users & Active Labs
        Row(
          children: [
            _buildStatCard('total_users'.tr(), stats['totalUsers']?.toString() ?? '0', Icons.people_outline, Colors.blueGrey),
            const SizedBox(width: 12),
            _buildStatCard('active_labs_count'.tr(), activeLabs.toString(), Icons.science_outlined, Colors.orange),
          ],
        ),
        const SizedBox(height: 16),

        // Attendance Rate Progress Bar
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.cardColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.borderColor, width: 0.5),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('attendance_rate_today'.tr(), style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black87)),
                  Text('${provider.attendanceRate.toInt()}%', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.primaryTeal)),
                ],
              ),
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: provider.attendanceRate / 100,
                  backgroundColor: AppColors.borderColor,
                  color: AppColors.primaryTeal,
                  minHeight: 10,
                ),
              ),
              const SizedBox(height: 10),
              Text('students_present_today'.tr(args: [provider.todayAttendance.toString()]), style: const TextStyle(fontSize: 12, color: AppColors.grayText)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.borderColor, width: 0.5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
              child: Icon(icon, color: color, size: 18),
            ),
            const SizedBox(height: 10),
            Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 22, color: Colors.black87)),
            Text(label, style: const TextStyle(fontSize: 11, color: AppColors.grayText)),
          ],
        ),
      ),
    );
  }

  Widget _buildManagementGrid() {
    return Column(
      children: [
        _buildActionTile('manage_users'.tr(), 'manage_accounts_desc'.tr(), Icons.people_outline, Colors.blueAccent, () => Navigator.push(context, MaterialPageRoute(builder: (context) => const ManageUsersScreen()))),
        _buildActionTile('manage_labs_title'.tr(), 'rooms_and_access_desc'.tr(), Icons.science_outlined, AppColors.primaryTeal, () => Navigator.push(context, MaterialPageRoute(builder: (context) => const ManageLabsScreen()))),
        _buildActionTile('manage_groups_title'.tr(), 'specialties_and_afouaj_desc'.tr(), Icons.groups_outlined, Colors.purpleAccent, () => Navigator.push(context, MaterialPageRoute(builder: (context) => const ManageGroupsScreen()))),
        _buildActionTile('security_alerts_title'.tr(), 'intrusion_logs_desc'.tr(), Icons.gpp_maybe_outlined, Colors.redAccent, () => Navigator.push(context, MaterialPageRoute(builder: (context) => const UnauthorizedLogsScreen()))),
      ],
    );
  }

  Widget _buildActionTile(String title, String sub, IconData icon, Color color, VoidCallback tap) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(color: AppColors.cardColor, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.borderColor, width: 0.5)),
      child: ListTile(
        leading: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)), child: Icon(icon, color: color, size: 24)),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.black87)),
        subtitle: Text(sub, style: const TextStyle(fontSize: 12, color: AppColors.grayText)),
        trailing: const Icon(Icons.arrow_forward_ios, size: 12, color: AppColors.grayText),
        onTap: tap,
      ),
    );
  }

  Widget _buildQuickSecurityStatus(String alertsCount) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.redAccent.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.redAccent.withValues(alpha: 0.2))),
      child: Row(
        children: [
          const Icon(Icons.shield_outlined, color: Colors.redAccent, size: 24),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('security_status'.tr(), style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.redAccent)),
                Text('$alertsCount ${'intrusion_attempts_today'.tr()}', style: const TextStyle(fontSize: 12, color: Colors.redAccent)),
              ],
            ),
          ),
          const Icon(Icons.warning_amber_rounded, color: Colors.redAccent, size: 18),
        ],
      ),
    );
  }



  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('logout_title'.tr()),
        content: Text('logout_confirm_msg'.tr()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('cancel'.tr()),
          ),
          TextButton(
            onPressed: () async {
              final authProvider = Provider.of<AuthProvider>(context, listen: false);
              final navigator = Navigator.of(context);
              Navigator.pop(ctx);
              await authProvider.logout();
              
              navigator.pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const LoginScreen()),
                (route) => false,
              );
            },
            child: Text('logout_title'.tr(), style: const TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
  }
}



