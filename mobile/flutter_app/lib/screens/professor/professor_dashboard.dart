import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import 'create_session_screen.dart';
import 'my_sessions_screen.dart';
import 'attendance_list_screen.dart';
import 'notifications_screen.dart';
import '../notification_screen.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/notification_provider.dart';
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
      Provider.of<NotificationProvider>(context, listen: false).fetchNotifications();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        // IHM: AppBar contextuel avec rôle visible
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Professor Workspace', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
            Text(Provider.of<AuthProvider>(context).userName ?? 'Professor', style: const TextStyle(fontSize: 11, color: AppColors.grayText)),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Logout',
            icon: const Icon(Icons.logout, color: Colors.blue),
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
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // IHM: Salutation + contexte actuel
            _buildWelcomeHeader(),
            const SizedBox(height: 25),

            // IHM: Prochaine session active en cours → info contextuelle urgente
            _buildCurrentSessionBanner(),
            const SizedBox(height: 25),

            // IHM: CTA principal visible et immédiat (Lancer une session)
            _buildLaunchSessionCard(),
            const SizedBox(height: 25),

            // IHM: Actions secondaires groupées — charge cognitive réduite
            _buildSectionHeader('Laboratory Management'),
            const SizedBox(height: 14),
            Row(
              children: [
                _buildActionCard(icon: Icons.history, label: 'Recent Sessions', color: Colors.blueAccent,
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MySessionsScreen()))),
                const SizedBox(width: 14),
                _buildActionCard(icon: Icons.list_alt, label: 'Attendance', color: Colors.orangeAccent,
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => AttendanceListScreen(courseName: 'All Sessions', sessionId: '')))),
              ],
            ),
            const SizedBox(height: 25),

            // IHM: Aperçu statistiques — données utiles sans surcharge
            _buildSectionHeader('Semester Overview'),
            const SizedBox(height: 14),
            _buildStatsRow(),
            const SizedBox(height: 25),

            // IHM: Activité récente — feedback sur l'historique d'actions
            _buildSectionHeader('Recent Sessions'),
            const SizedBox(height: 12),
            // IHM: Empty state for recent sessions
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: Column(
                  children: [
                    Icon(Icons.event_note_outlined, color: AppColors.grayText, size: 40),
                    SizedBox(height: 10),
                    Text('No recent sessions found', style: TextStyle(color: AppColors.grayText, fontSize: 13)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomeHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Welcome,', style: TextStyle(fontSize: 14, color: AppColors.grayText)),
            const Text('Professor', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black87)),
          ],
        ),
        // IHM: Avatar distinctif par rôle (bleu = professeur)
        CircleAvatar(
          radius: 24,
          backgroundColor: Colors.blue.withOpacity(0.1),
          child: const Icon(Icons.school, color: Colors.blue),
        ),
      ],
    );
  }

  Widget _buildCurrentSessionBanner() {
    // IHM: Bandeau d'information contextuelle (session en cours) — état système visible
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.orange.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: Colors.orange.withOpacity(0.15), borderRadius: BorderRadius.circular(10)),
            child: const Icon(Icons.schedule, color: Colors.orange, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Next session', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black87)),
                const Text('Algorithmique 2 — in 45 minutes', style: TextStyle(fontSize: 12, color: AppColors.grayText)),
              ],
            ),
          ),
          // IHM: Badge d'action — permet d'agir directement
          const Text('Start →', style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold, fontSize: 13)),
        ],
      ),
    );
  }

  Widget _buildLaunchSessionCard() {
    return InkWell(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CreateSessionScreen())),
      borderRadius: BorderRadius.circular(24),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(26),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AppColors.primaryTeal, Color(0xFF00897B)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [BoxShadow(color: AppColors.primaryTeal.withOpacity(0.35), blurRadius: 20, offset: const Offset(0, 10))],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(18)),
              child: const Icon(Icons.add_circle_outline, color: Colors.white, size: 36),
            ),
            const SizedBox(width: 18),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Launch new session', style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  const Text('Generate QR code for attendance', style: TextStyle(color: Colors.white70, fontSize: 12)),
                ],
              ),
            ),
            // IHM: Flèche = affordance de navigation
            const Icon(Icons.arrow_forward_ios, color: Colors.white70, size: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Colors.black87));
  }

  Widget _buildActionCard({required IconData icon, required String label, required Color color, required VoidCallback onTap}) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 22),
          decoration: BoxDecoration(
            color: AppColors.cardColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.borderColor, width: 0.5),
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                child: Icon(icon, color: color, size: 28),
              ),
              const SizedBox(height: 12),
              Text(label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: Colors.black87)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatsRow() {
    return Row(
      children: [
        _buildStatCard('Sessions', '0', Icons.calendar_today_outlined, Colors.blue),
        const SizedBox(width: 14),
        _buildStatCard('Students', '0', Icons.people_outline, AppColors.primaryTeal),
        const SizedBox(width: 14),
        _buildStatCard('Avg. Rate', '0%', Icons.bar_chart, Colors.orange),
      ],
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.borderColor, width: 0.5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(height: 8),
            Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
            Text(label, style: const TextStyle(fontSize: 10, color: AppColors.grayText)),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentSession(String courseName, String details, String attendance) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderColor, width: 0.5),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: AppColors.primaryTeal.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
            child: const Icon(Icons.science_outlined, color: AppColors.primaryTeal, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(courseName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                const SizedBox(height: 3),
                Text(details, style: const TextStyle(fontSize: 12, color: AppColors.grayText)),
              ],
            ),
          ),
          // IHM: Badge statistique — info clé visible sans clic supplémentaire
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(color: AppColors.primaryTeal.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
            child: Text(attendance, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.primaryTeal)),
          ),
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
