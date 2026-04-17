import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/session_provider.dart';
import '../../models/session_model.dart';
import 'attendance_list_screen.dart';
import 'show_qr_screen.dart';

class MySessionsScreen extends StatefulWidget {
  const MySessionsScreen({super.key});

  @override
  State<MySessionsScreen> createState() => _MySessionsScreenState();
}

class _MySessionsScreenState extends State<MySessionsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SessionProvider>().fetchMySessions();
    });
  }

  String _formatTime(String? isoString) {
    if (isoString == null) return '--:--';
    try {
      final dt = DateTime.parse(isoString).toLocal();
      return DateFormat('HH:mm').format(dt);
    } catch (_) {
      return isoString;
    }
  }

  String _formatDate(DateTime dt) => DateFormat('MMM dd, yyyy').format(dt);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        centerTitle: true,
        title: const Column(
          children: [
            Text('SESSION HISTORY', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, letterSpacing: 1)),
            Text('Trace all your academic presence logs', style: TextStyle(fontSize: 10, color: Colors.white70, fontWeight: FontWeight.w400)),
          ],
        ),
      ),
      body: Consumer<SessionProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator(color: AppColors.primary));
          }

          final sessions = provider.sessions;

          if (sessions.isEmpty) {
            return _buildEmptyState();
          }

          return RefreshIndicator(
            onRefresh: () => provider.fetchMySessions(),
            child: ListView.separated(
              padding: const EdgeInsets.all(20),
              itemCount: sessions.length,
              separatorBuilder: (_, __) => const SizedBox(height: 16),
              itemBuilder: (context, index) => _buildSessionCard(sessions[index], context),
            ),
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
            child: const Icon(Icons.history_toggle_off_rounded, size: 52, color: AppColors.textLight),
          ),
          const SizedBox(height: 24),
          const Text('No sessions yet', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: AppColors.textPrimary)),
          const SizedBox(height: 8),
          const Text('Your attendance history will appear here.', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
        ],
      ),
    );
  }

  Widget _buildSessionCard(SessionModel session, BuildContext context) {
    final isClosed = DateTime.now().isAfter(session.endTime);
    final startTime = _formatTime(session.startTime.toIso8601String());
    final endTime = _formatTime(session.endTime.toIso8601String());
    final date = _formatDate(session.startTime);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: AppColors.softShadow,
        border: Border.all(color: !isClosed ? AppColors.primary.withOpacity(0.3) : AppColors.border.withOpacity(0.5), width: !isClosed ? 1.5 : 1),
      ),
      child: InkWell(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => AttendanceListScreen(courseName: session.courseName, sessionId: session.id ?? '')),
        ),
        borderRadius: BorderRadius.circular(24),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: (isClosed ? AppColors.textLight : AppColors.success).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(isClosed ? Icons.event_available_rounded : Icons.sensors_rounded, color: isClosed ? AppColors.textLight : AppColors.success, size: 20),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(session.courseName, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: AppColors.textPrimary)),
                        Text(date, style: const TextStyle(fontSize: 11, color: AppColors.textLight, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                  _buildStatusBadge(isClosed),
                ],
              ),
              const Padding(padding: EdgeInsets.symmetric(vertical: 16), child: Divider(height: 1)),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _iconLabel(Icons.groups_rounded, session.groupName ?? 'General Group'),
                      const SizedBox(height: 8),
                      _iconLabel(Icons.location_on_rounded, session.labName ?? 'Auditorium'),
                    ],
                  ),
                  _timeStats(startTime, endTime),
                ],
              ),
              if (session.attendanceCount != null) ...[
                const SizedBox(height: 20),
                _attendanceBar(session.attendanceCount!),
              ],
              if (!isClosed) ...[
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.qr_code_rounded, size: 18),
                    label: const Text('SHOW QR CODE', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12, letterSpacing: 1)),
                    onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ShowQrScreen(session: session))),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(bool isClosed) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: (isClosed ? AppColors.background : AppColors.success.withOpacity(0.1)),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: (isClosed ? AppColors.border : AppColors.success.withOpacity(0.2))),
      ),
      child: Text(
        isClosed ? 'CLOSED' : 'LIVE',
        style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: isClosed ? AppColors.textLight : AppColors.success, letterSpacing: 1),
      ),
    );
  }

  Widget _iconLabel(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 14, color: AppColors.textLight),
        const SizedBox(width: 8),
        Text(text, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, fontWeight: FontWeight.w600)),
      ],
    );
  }

  Widget _timeStats(String start, String end) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text('$start - $end', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: AppColors.textPrimary)),
        const Text('DURATION', style: TextStyle(fontSize: 9, color: AppColors.textLight, fontWeight: FontWeight.w800)),
      ],
    );
  }

  Widget _attendanceBar(int count) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(12)),
      child: Row(
        children: [
          const Icon(Icons.people_alt_rounded, size: 16, color: AppColors.primary),
          const SizedBox(width: 8),
          Text('$count Students Present', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: AppColors.primary)),
          const Spacer(),
          const Icon(Icons.arrow_forward_ios_rounded, size: 10, color: AppColors.textLight),
        ],
      ),
    );
  }
}
