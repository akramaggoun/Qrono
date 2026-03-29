import 'package:flutter/material.dart';
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
        title: const Text('Qrono Control Hub'),
        actions: [
          IconButton(
            tooltip: 'Logout',
            icon: const Icon(Icons.logout, color: Colors.redAccent),
            onPressed: () => _showLogoutDialog(context),
          ),
          Consumer<NotificationProvider>(
            builder: (context, provider, child) => Stack(
              alignment: Alignment.center,
              children: [
                IconButton(
                  tooltip: 'Notifications',
                  icon: const Icon(Icons.notifications_none_outlined),
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
            icon: const Icon(Icons.refresh), 
            onPressed: () => Provider.of<AdminProvider>(context, listen: false).fetchStatistics()
          ),
        ],
      ),
      body: Consumer<AdminProvider>(
        builder: (context, adminProvider, child) {
          if (adminProvider.isLoading && adminProvider.statistics.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }
          
          final stats = adminProvider.statistics;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildAdminProfile(),
                const SizedBox(height: 30),

                // Statistics Section (Step 6)
                _buildStatsSection(stats),
                const SizedBox(height: 40),

                // Management Grid
                const Text('Ecosystem Management', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
                const SizedBox(height: 15),
                _buildManagementGrid(),

                const SizedBox(height: 30),
                // Quick Status
                _buildQuickSecurityStatus(stats['unauthorizedToday']?.toString() ?? '0'),
              ],
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
        CircleAvatar(radius: 28, backgroundColor: Colors.purple.withOpacity(0.1), child: const Icon(Icons.admin_panel_settings, color: Colors.purple)),
        const SizedBox(width: 15),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Welcome back,', style: TextStyle(color: AppColors.grayText, fontSize: 13)),
            Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: Colors.black87)),
          ],
        ),
      ],
    );
  }

  Widget _buildStatsSection(Map<String, dynamic> stats) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Global Dashboard', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
        const SizedBox(height: 15),
        
        // Main Trend Card (Active Sessions)
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.primaryTeal,
            borderRadius: BorderRadius.circular(25),
            boxShadow: [BoxShadow(color: AppColors.primaryTeal.withOpacity(0.3), blurRadius: 15, offset: const Offset(0, 8))],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Active Sessions', style: TextStyle(color: Colors.white70, fontSize: 14)),
              const SizedBox(height: 5),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(stats['activeSessions']?.toString() ?? '0', style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)),
                  const Icon(Icons.flash_on, color: Colors.white, size: 40),
                ],
              ),
              const Text('Real-time monitoring', style: TextStyle(color: Colors.white60, fontSize: 12)),
            ],
          ),
        ),
        const SizedBox(height: 15),

        // Grid of Stats (Step 6)
        Row(
          children: [
            _buildSmallStatCard('Total Users', stats['totalUsers']?.toString() ?? '0', Icons.people_outline, Colors.blue),
            const SizedBox(width: 15),
            _buildSmallStatCard('Today Attendance', stats['todayAttendance']?.toString() ?? '0', Icons.check_circle_outline, Colors.green),
          ],
        ),
        const SizedBox(height: 15),
        Row(
          children: [
            _buildSmallStatCard('Security Alerts', stats['unauthorizedToday']?.toString() ?? '0', Icons.gpp_maybe, Colors.redAccent),
            const SizedBox(width: 15),
            _buildSmallStatCard('Active Labs', stats['laboratoriesCount']?.toString() ?? '0', Icons.science_outlined, Colors.orange),
          ],
        ),
      ],
    );
  }

  Widget _buildSmallStatCard(String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: AppColors.cardColor, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.borderColor, width: 0.5)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(height: 10),
            Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.black87)),
            Text(label, style: const TextStyle(fontSize: 11, color: AppColors.grayText)),
          ],
        ),
      ),
    );
  }

  Widget _buildManagementGrid() {
    return Column(
      children: [
        _buildActionTile('Manage Users', 'Manage accounts', Icons.people_outline, Colors.blueAccent, () => Navigator.push(context, MaterialPageRoute(builder: (context) => const ManageUsersScreen()))),
        _buildActionTile('Manage Labs', 'Rooms and access', Icons.science_outlined, AppColors.primaryTeal, () => Navigator.push(context, MaterialPageRoute(builder: (context) => const ManageLabsScreen()))),
        _buildActionTile('Manage Groups', 'Specialties and Afouaj', Icons.groups_outlined, Colors.purpleAccent, () => Navigator.push(context, MaterialPageRoute(builder: (context) => const ManageGroupsScreen()))),
        _buildActionTile('Security Alerts', 'Intrusion logs', Icons.gpp_maybe_outlined, Colors.redAccent, () => Navigator.push(context, MaterialPageRoute(builder: (context) => const UnauthorizedLogsScreen()))),
      ],
    );
  }

  Widget _buildActionTile(String title, String sub, IconData icon, Color color, VoidCallback tap) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(color: AppColors.cardColor, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.borderColor, width: 0.5)),
      child: ListTile(
        leading: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(10)), child: Icon(icon, color: color, size: 24)),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
        subtitle: Text(sub, style: const TextStyle(fontSize: 12, color: AppColors.grayText)),
        trailing: const Icon(Icons.arrow_forward_ios, size: 12, color: AppColors.grayText),
        onTap: tap,
      ),
    );
  }

  Widget _buildQuickSecurityStatus(String alertsCount) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.redAccent.withOpacity(0.05), borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.redAccent.withOpacity(0.2))),
      child: Row(
        children: [
          const Icon(Icons.shield_outlined, color: Colors.redAccent, size: 24),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Security Status', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.redAccent)),
                Text('$alertsCount Intrusion attempts today', style: const TextStyle(fontSize: 12, color: Colors.redAccent)),
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
        title: const Text('Logout'),
        content: const Text('Are you sure you want to log out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final authProvider = Provider.of<AuthProvider>(context, listen: false);
              await authProvider.logout();
              if (mounted) {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                  (route) => false,
                );
              }
            },
            child: const Text('Logout', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
  }
}
