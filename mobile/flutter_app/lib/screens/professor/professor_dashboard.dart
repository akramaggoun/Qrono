import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import 'create_session_screen.dart';
import 'my_sessions_screen.dart';
import 'attendance_list_screen.dart';
import '../notification_screen.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/notification_provider.dart';
import '../../providers/session_provider.dart';
import '../auth/login_screen.dart';

class ProfessorDashboard extends StatefulWidget {
  const ProfessorDashboard({super.key});

  @override
  State<ProfessorDashboard> createState() => _ProfessorDashboardState();
}

class _ProfessorDashboardState extends State<ProfessorDashboard> {
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
      Provider.of<SessionProvider>(context, listen: false).fetchMySessions();
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
            const Text('Professor Dashboard', 
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF1A1C1E))),
            Text(Provider.of<AuthProvider>(context).userName ?? 'University Faculty', 
              style: const TextStyle(fontSize: 12, color: Color(0xFF6C757D), fontWeight: FontWeight.w500)),
          ],
        ),
        actions: [
          _buildNotificationIcon(),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.power_settings_new_rounded, color: Colors.redAccent),
            onPressed: () => _showLogoutDialog(context),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Consumer<SessionProvider>(
        builder: (context, sessionProvider, child) {
          final sessions = sessionProvider.sessions;
          
          if (sessionProvider.isLoading && sessions.isEmpty) {
            return const Center(child: CircularProgressIndicator(color: AppColors.primaryTeal));
          }

          return RefreshIndicator(
            onRefresh: () => sessionProvider.fetchMySessions(),
            color: AppColors.primaryTeal,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildQuickActionHeader(context),
                  const SizedBox(height: 30),
                  _buildSectionTitle('Academic Insights'),
                  const SizedBox(height: 15),
                  _buildModernStats(sessions),
                  const SizedBox(height: 30),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildSectionTitle('Active & Recent Sessions'),
                      TextButton(
                        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MySessionsScreen())),
                        child: const Text('View All', style: TextStyle(color: AppColors.primaryTeal, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  _buildSessionList(sessions),
                ],
              ),
            ),
          );
        }
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

  Widget _buildQuickActionHeader(BuildContext context) {
    return InkWell(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CreateSessionScreen())),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          gradient: const LinearGradient(
            colors: [Color(0xFF009688), Color(0xFF00796B)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF009688).withOpacity(0.3),
              blurRadius: 20,
              offset: const Offset(0, 10),
            )
          ],
        ),
        child: Row(
          children: [
            const CircleAvatar(
              radius: 30,
              backgroundColor: Colors.white24,
              child: Icon(Icons.qr_code_scanner_rounded, color: Colors.white, size: 32),
            ),
            const SizedBox(width: 20),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Start Attendance', 
                    style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800)),
                  SizedBox(height: 4),
                  Text('Launch session & generate QR', 
                    style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w500)),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 28),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(title, 
      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF1A1C1E)));
  }

  Widget _buildModernStats(List sessions) {
    num totalAttendance = 0;
    for (var s in sessions) totalAttendance += (s.attendanceCount ?? 0);
    final avg = sessions.isNotEmpty ? (totalAttendance / sessions.length).toStringAsFixed(1) : '0';

    return Row(
      children: [
        _buildStatsCard('Sessions', sessions.length.toString(), Icons.layers_rounded, Colors.blue),
        const SizedBox(width: 12),
        _buildStatsCard('Total Present', totalAttendance.toString(), Icons.group_rounded, Colors.teal),
        const SizedBox(width: 12),
        _buildStatsCard('Daily Avg', avg, Icons.analytics_rounded, Colors.orange),
      ],
    );
  }

  Widget _buildStatsCard(String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 12),
            Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Color(0xFF1A1C1E))),
            const SizedBox(height: 2),
            Text(label, style: const TextStyle(fontSize: 10, color: Color(0xFF9E9E9E), fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  Widget _buildSessionList(List sessions) {
    if (sessions.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 40),
        child: Column(
          children: [
            Icon(Icons.inbox_rounded, size: 64, color: Colors.grey.withOpacity(0.2)),
            const SizedBox(height: 16),
            const Text('Your session history is empty', 
              style: TextStyle(color: Color(0xFF9E9E9E), fontSize: 14, fontWeight: FontWeight.w500)),
          ],
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: sessions.take(5).length,
      itemBuilder: (context, index) {
        final session = sessions[index];
        bool isActive = session.status == 'ACTIVE';
        
        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          child: InkWell(
            onTap: () => Navigator.push(context, MaterialPageRoute(
              builder: (_) => AttendanceListScreen(courseName: session.courseName, sessionId: session.id ?? '')
            )),
            borderRadius: BorderRadius.circular(24),
            child: Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 12, offset: const Offset(0, 6))
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: (isActive ? Colors.teal : Colors.blueGrey).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16)
                    ),
                    child: Icon(Icons.school_rounded, color: isActive ? Colors.teal : Colors.blueGrey, size: 24),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(session.courseName, 
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: Color(0xFF1A1C1E))),
                            ),
                            const SizedBox(width: 8),
                            _buildStatusBadge(isActive),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text('${session.groupName} • ${session.labName}', 
                          style: const TextStyle(fontSize: 12, color: Color(0xFF6C757D), fontWeight: FontWeight.w500)),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text('${session.attendanceCount ?? 0}', 
                        style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: AppColors.primaryTeal)),
                      const Text('Students', style: TextStyle(fontSize: 10, color: Color(0xFF9E9E9E), fontWeight: FontWeight.w600)),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatusBadge(bool active) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: (active ? Colors.green : Colors.grey).withOpacity(0.1),
        borderRadius: BorderRadius.circular(8)
      ),
      child: Text(active ? 'ACTIVE' : 'CLOSED', 
        style: TextStyle(color: active ? Colors.green : Colors.grey, fontSize: 10, fontWeight: FontWeight.w800)),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Confirm Logout'),
        content: const Text('Do you want to terminate your current session?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Stay')),
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
