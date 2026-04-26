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

  String _formatTime(String? isoString) {
    if (isoString == null) return '--:--';
    try {
      final dt = DateTime.parse(isoString).toLocal();
      return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return isoString;
    }
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
                  Icon(Icons.event_busy, color: Colors.white54, size: 60),
                  SizedBox(height: 16),
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
    final isClosed = DateTime.now().isAfter(session.endTime);
    final statusText = isClosed ? 'status_closed'.tr() : 'status_active'.tr();
    final statusColor = isClosed ? Colors.red.shade700 : Colors.green;
    
    final startTime = _formatTime(session.startTime.toIso8601String());
    final endTime = _formatTime(session.endTime.toIso8601String());
    final groupName = session.groupName ?? session.groupId; 
    final labName = session.labName ?? session.labId;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white12, width: 0.5),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 10, offset: const Offset(0, 4))
        ]
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AttendanceListScreen(
                courseName: session.courseName, // Fixed from hardcoded 'Session'
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
                      color: statusColor.withValues(alpha: 0.1),
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
              if (session.attendanceCount != null)
                _buildInfoRow(Icons.people_outline, '${'attendance_prefix'.tr()}${session.attendanceCount}${'students_suffix'.tr()}'),
              const Divider(height: 30, color: Colors.white12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('time_prefix'.tr(), style: const TextStyle(color: Colors.white70, fontSize: 13)),
                  Text('$startTime - $endTime', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Colors.white)),
                ],
              ),
              if (!isClosed && (session.qrToken != null || true)) ...[
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: tealColor,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 12)
                    ),
                    icon: const Icon(Icons.qr_code_2),
                    label: Text('show_qr_scanner'.tr(), style: const TextStyle(fontWeight: FontWeight.bold)),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => ShowQrScreen(session: session)),
                      );
                    },
                  ),
                )
              ]
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

