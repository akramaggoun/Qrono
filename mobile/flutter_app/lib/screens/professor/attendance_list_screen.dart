import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/presence_provider.dart';

class AttendanceListScreen extends StatefulWidget {
  final String courseName;
  final String sessionId;

  const AttendanceListScreen({super.key, required this.courseName, required this.sessionId});

  @override
  State<AttendanceListScreen> createState() => _AttendanceListScreenState();
}

class _AttendanceListScreenState extends State<AttendanceListScreen> {
  
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PresenceProvider>().fetchSessionAttendance(widget.sessionId);
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
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Attendance List', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Colors.white)),
            Text(widget.courseName, style: const TextStyle(fontSize: 11, color: Colors.white70)),
          ],
        ),
        backgroundColor: cardColor,
        iconTheme: const IconThemeData(color: tealColor),
      ),
      body: Consumer<PresenceProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator(color: tealColor));
          }

          final attendances = provider.attendances;

          if (attendances.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.search_off, size: 60, color: Colors.white24),
                  SizedBox(height: 16),
                  Text('Aucun étudiant présent', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white70)),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            itemCount: attendances.length,
            itemBuilder: (context, index) {
              return _buildStudentCard(attendances[index], cardColor, tealColor);
            },
          );
        },
      ),
    );
  }

  Widget _buildStudentCard(dynamic studentRecord, Color cardColor, Color tealColor) {
    // Parsing API response logic
    final studentName = studentRecord['student']?['name'] ?? 'Unknown';
    final matricule = studentRecord['student']?['registrationNumber'] ?? 'Unknown URN';
    final time = _formatTime(studentRecord['checkedInAt']);
    final isQr = studentRecord['method'] == 'qr';
    
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: tealColor.withOpacity(0.2)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          radius: 22,
          backgroundColor: tealColor.withOpacity(0.1),
          child: Text(
            studentName.toString()[0].toUpperCase(),
            style: TextStyle(fontWeight: FontWeight.bold, color: tealColor, fontSize: 16),
          ),
        ),
        title: Text(studentName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.white)),
        subtitle: Text('URN: \$matricule', style: const TextStyle(fontSize: 11, color: Colors.white70)),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(color: tealColor.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(isQr ? Icons.qr_code : Icons.edit, size: 12, color: tealColor),
                  const SizedBox(width: 4),
                  Text(isQr ? 'QR' : 'Manual', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: tealColor)),
                ],
              ),
            ),
            const SizedBox(height: 4),
            Text('Arrived: \$time', style: const TextStyle(fontSize: 10, color: Colors.white70)),
          ],
        ),
      ),
    );
  }
}
