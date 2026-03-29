import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/session_provider.dart';
import '../../models/session_model.dart';
import 'attendance_list_screen.dart';

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
        title: const Text('Sessions History', style: TextStyle(color: Colors.white)),
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
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.event_busy, color: Colors.white54, size: 60),
                  SizedBox(height: 16),
                  Text('Aucune séance créée', style: TextStyle(color: Colors.white70, fontSize: 16)),
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
    final statusText = isClosed ? 'CLOSED' : 'ACTIVE';
    final statusColor = isClosed ? Colors.red.shade700 : Colors.green;
    
    final startTime = _formatTime(session.startTime.toIso8601String());
    final endTime = _formatTime(session.endTime.toIso8601String());
    final groupName = session.groupId; 
    final labName = session.labId;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white12, width: 0.5),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AttendanceListScreen(
                courseName: 'Session', 
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
                  const Text(
                    'Course Session',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white),
                  ),
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
              _buildInfoRow(Icons.science_outlined, labName),
              _buildInfoRow(Icons.groups_outlined, groupName),
              const Divider(height: 30, color: Colors.white12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Time:', style: TextStyle(color: Colors.white70, fontSize: 13)),
                  Text('\$startTime - \$endTime', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Colors.white)),
                ],
              ),
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
