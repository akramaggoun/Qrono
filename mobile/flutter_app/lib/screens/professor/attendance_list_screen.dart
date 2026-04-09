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
    const bgColor = Color(0xFFF8FAFB);
    const primaryColor = Color(0xFF1A1C1E);
    const tealColor = Color(0xFF00C9A7);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        centerTitle: false,
        iconTheme: const IconThemeData(color: primaryColor),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Live Attendance', 
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: primaryColor)),
            Text(widget.courseName, 
              style: const TextStyle(fontSize: 12, color: Color(0xFF6C757D), fontWeight: FontWeight.w500)),
          ],
        ),
      ),
      body: Consumer<PresenceProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator(color: tealColor));
          }

          final attendances = provider.attendances;

          if (attendances.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.person_search_rounded, size: 64, color: Colors.grey.withOpacity(0.2)),
                  const SizedBox(height: 16),
                  const Text('No students registered yet', 
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16, color: Color(0xFF9E9E9E))),
                  const SizedBox(height: 8),
                  const Text('Waiting for QR scans...', 
                    style: TextStyle(fontSize: 13, color: Color(0xFFBDBDBD))),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
            itemCount: attendances.length,
            itemBuilder: (context, index) {
              return _buildStudentCard(attendances[index], tealColor);
            },
          );
        },
      ),
    );
  }

  Widget _buildStudentCard(dynamic studentRecord, Color tealColor) {
    final studentName = studentRecord['student']?['user']?['name'] ?? 'Incomplete Profile';
    final matricule = studentRecord['student']?['urn'] ?? 'N/A';
    final time = _formatTime(studentRecord['checkInAt']);
    final isPresent = studentRecord['status'] == 'present';
    final isQr = studentRecord['method'] == 'qr';
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Container(
          height: 48, width: 48,
          decoration: BoxDecoration(
            color: isPresent ? tealColor.withOpacity(0.1) : Colors.red.withOpacity(0.1),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Center(
            child: Text(
              studentName.toString()[0].toUpperCase(),
              style: TextStyle(fontWeight: FontWeight.w900, color: isPresent ? tealColor : Colors.red, fontSize: 18),
            ),
          ),
        ),
        title: Text(studentName, 
          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: Color(0xFF1A1C1E))),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4.0),
          child: Row(
            children: [
              const Icon(Icons.badge_outlined, size: 12, color: Color(0xFF9E9E9E)),
              const SizedBox(width: 4),
              Text(matricule, style: const TextStyle(fontSize: 12, color: Color(0xFF9E9E9E), fontWeight: FontWeight.w600)),
            ],
          ),
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: isPresent 
                  ? (isQr ? Colors.green : Colors.orange).withOpacity(0.1)
                  : Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(isPresent ? (isQr ? 'حاضر (QR)' : 'حاضر (يدوي)') : 'غائب', 
                style: TextStyle(
                  fontSize: 11, 
                  fontWeight: FontWeight.w900, 
                  color: isPresent ? (isQr ? Colors.green : Colors.orange) : Colors.red
                )),
            ),
            const SizedBox(height: 6),
            Text(isPresent ? time : '--:--', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF1A1C1E))),
          ],
        ),
      ),
    );
  }
}
