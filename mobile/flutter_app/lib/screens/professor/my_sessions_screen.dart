import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/session_provider.dart';
import '../../models/session_model.dart';
import 'show_qr_screen.dart';
import 'attendance_list_screen.dart';
import 'package:easy_localization/easy_localization.dart';

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

  String _formatTime(DateTime dateTime) {
    return '${dateTime.toLocal().hour.toString().padLeft(2, '0')}:${dateTime.toLocal().minute.toString().padLeft(2, '0')}';
  }

  bool _isSessionClosed(SessionModel session) {
    // 🛑 MASTER OVERRIDE: Calculate closure status manually
    final now = DateTime.now();
    final localEnd = session.endTime.toLocal();
    
    // Safety check: ensure we aren't comparing with a zeroed-out date
    if (session.endTime.year < 2020) return false;

    // Nuclear check: If current time is AFTER session end time, it is CLOSED.
    if (now.isAfter(localEnd)) {
      return true;
    }
    
    // Status backup
    final status = (session.status ?? '').toUpperCase();
    return status == 'CLOSED' || status == 'COMPLETED';
  }

  @override
  Widget build(BuildContext context) {
    const bgColor = Color(0xFF0D1117);
    const cardColor = Color(0xFF161B22);
    const tealColor = Color(0xFF00C9A7);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: Text('sessions_history'.tr(), style: const TextStyle(color: Colors.white)),
        backgroundColor: cardColor,
        iconTheme: const IconThemeData(color: tealColor),
        actions: [
            IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: () => context.read<SessionProvider>().fetchMySessions(),
            )
        ],
      ),
      body: Consumer<SessionProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator(color: tealColor));
          }

          final sessions = provider.sessions;

          if (sessions.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.event_busy, color: Colors.white54, size: 60),
                  const SizedBox(height: 16),
                  Text('no_session_created'.tr(), style: const TextStyle(color: Colors.white70, fontSize: 16)),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: sessions.length,
            itemBuilder: (context, index) {
              return _buildSessionCard(sessions[index], cardColor, tealColor, context);
            },
          );
        },
      ),
    );
  }

  Widget _buildSessionCard(SessionModel session, Color cardColor, Color tealColor, BuildContext context) {
    // 🛑 NUCLEAR OVERRIDE: Force status based on time
    final isClosed = _isSessionClosed(session);
    final statusText = isClosed ? 'status_closed'.tr() : 'status_active'.tr();
    final statusColor = isClosed ? Colors.red.shade700 : Colors.green;

    final startTimeStr = _formatTime(session.startTime);
    final endTimeStr = _formatTime(session.endTime);
    final groupName = session.groupName ?? 'N/A';
    final labName = session.labName ?? 'N/A';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white12, width: 0.5),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 10, offset: const Offset(0, 4))
          ]),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AttendanceListScreen(
                courseName: session.courseName,
                sessionId: session.id ?? '',
              ),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      session.courseName,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      statusText,
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: statusColor),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              _buildInfoRow(Icons.science_outlined, '${'lab_prefix'.tr()}$labName'),
              _buildInfoRow(Icons.groups_outlined, '${'group_prefix'.tr()}$groupName'),
              _buildInfoRow(Icons.people_alt_outlined, '${'attendance_prefix'.tr()}${session.attendanceCount ?? 0}${'students_label'.tr()}'),
              const Divider(color: Colors.white10, height: 30),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('time_label'.tr(), style: const TextStyle(color: Colors.white38, fontSize: 13)),
                  Text('$startTimeStr - $endTimeStr', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                ],
              ),
              if (!isClosed) ...[
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: tealColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ShowQrScreen(session: session),
                        ),
                      );
                    },
                    icon: const Icon(Icons.qr_code_scanner),
                    label: Text('show_qr_code'.tr()),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6.0),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.white54),
          const SizedBox(width: 8),
          Text(text, style: const TextStyle(fontSize: 14, color: Colors.white)),
        ],
      ),
    );
  }
}
