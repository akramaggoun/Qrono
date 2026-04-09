import 'package:flutter/material.dart';
import '../notification_screen.dart';
import '../wireless_settings_screen.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/notification_provider.dart';
import '../../providers/presence_provider.dart';
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
            const Text('Student Portal', 
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF1A1C1E))),
            Text(Provider.of<AuthProvider>(context).userName ?? 'University Student', 
              style: const TextStyle(fontSize: 12, color: Color(0xFF6C757D), fontWeight: FontWeight.w500)),
          ],
        ),
        actions: [
          _buildNotificationIcon(),
          IconButton(
            icon: const Icon(Icons.settings, color: AppColors.primaryTeal),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const WirelessSettingsScreen()),
            ),
          ),
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
          const totalSessions = 20; 

          if (presenceProvider.isLoading && attendances.isEmpty) {
            return const Center(child: CircularProgressIndicator(color: AppColors.primaryTeal));
          }

          return RefreshIndicator(
            onRefresh: () => presenceProvider.fetchMyAttendances(),
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
                  _buildSectionHeader('Your Recent Presence', 
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
            decoration: BoxDecoration(color: Colors.grey.withOpacity(0.05), shape: BoxShape.circle),
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
              const Text('Hello,', style: TextStyle(fontSize: 16, color: Color(0xFF9E9E9E), fontWeight: FontWeight.w500)),
              Text(authProvider.userName ?? 'Student', 
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Color(0xFF1A1C1E))),
            ],
          ),
        ),
        Container(
          height: 56, width: 56,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(colors: [AppColors.primaryTeal.withOpacity(0.1), Colors.white]),
            border: Border.all(color: AppColors.primaryTeal.withOpacity(0.2)),
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
            BoxShadow(color: AppColors.primaryTeal.withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 10))
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
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Confirm Presence', 
                    style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800)),
                  SizedBox(height: 4),
                  Text('Tap to scan session QR', 
                    style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w500)),
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
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 12, offset: const Offset(0, 6))
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Attendance Overview', 
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: Colors.teal.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                child: const Text('L3 INFO', style: TextStyle(color: Colors.teal, fontSize: 10, fontWeight: FontWeight.w900)),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Stack(
            children: [
              Container(height: 12, decoration: BoxDecoration(color: Colors.grey.withOpacity(0.08), borderRadius: BorderRadius.circular(6))),
              AnimatedContainer(
                duration: const Duration(seconds: 1),
                height: 12, width: MediaQuery.of(context).size.width * 0.7 * progress,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [AppColors.primaryTeal, Color(0xFF4DB6AC)]),
                  borderRadius: BorderRadius.circular(6),
                  boxShadow: [BoxShadow(color: Colors.teal.withOpacity(0.2), blurRadius: 6, offset: const Offset(0, 3))]
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
                  Text('$present Sessions Done', 
                    style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: Color(0xFF1A1C1E))),
                  const Text('Total present this semester', 
                    style: TextStyle(fontSize: 11, color: Color(0xFF9E9E9E), fontWeight: FontWeight.w500)),
                ],
              ),
              Text('${(progress * 100).round()}%', 
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: AppColors.primaryTeal)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, {VoidCallback? onTap}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, 
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF1A1C1E))),
        if (onTap != null)
          TextButton(onPressed: onTap, child: const Text('Statistics', style: TextStyle(color: AppColors.primaryTeal, fontWeight: FontWeight.bold))),
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
              Icon(Icons.history_toggle_off_rounded, size: 64, color: Colors.grey.withOpacity(0.2)),
              const SizedBox(height: 16),
              const Text('No presence recorded yet', 
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
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8, offset: const Offset(0, 4))],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: Colors.green.withOpacity(0.08), shape: BoxShape.circle),
                child: const Icon(Icons.check_circle_rounded, color: Colors.green, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(session['courseName'] ?? 'Academic Session', 
                      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: Color(0xFF1A1C1E))),
                    const SizedBox(height: 4),
                    Text('${session['lab']?['name'] ?? 'Laboratory'} • room ${session['lab']?['roomNumber'] ?? 'N/A'}', 
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
        title: const Text('Confirm Logout'),
        content: const Text('Do you want to sign out from your student account?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
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
            child: const Text('Logout', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
