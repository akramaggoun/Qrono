import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/presence_provider.dart';
import 'package:easy_localization/easy_localization.dart';

class MyAttendanceScreen extends StatefulWidget {
  const MyAttendanceScreen({super.key});

  @override
  State<MyAttendanceScreen> createState() => _MyAttendanceScreenState();
}

class _MyAttendanceScreenState extends State<MyAttendanceScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PresenceProvider>().fetchMyAttendances();
    });
  }

  String _formatDateTime(String? isoString) {
    if (isoString == null) return '--';
    try {
      final dt = DateTime.parse(isoString).toLocal();
      return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
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
        title: Text('my_attendance'.tr(), style: const TextStyle(color: Colors.white)),
        backgroundColor: cardColor,
        iconTheme: const IconThemeData(color: tealColor),
      ),
      body: Consumer<PresenceProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator(color: tealColor));
          }

          final myAttendances = provider.myAttendances;

          return Column(
            children: [
              // Stats
              Container(
                padding: const EdgeInsets.all(20),
                margin: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [tealColor, tealColor.withValues(alpha: 0.7)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStatItem('total'.tr(), '${myAttendances.length}'),
                    Container(height: 30, width: 1, color: Colors.white30),
                    _buildStatItem('attendance_streak'.tr(), '${provider.streak}'),
                    Container(height: 30, width: 1, color: Colors.white30),
                    _buildStatItem('weekly_attendance'.tr(), '${provider.sessionsThisWeek}'),
                  ],
                ),
              ),
              
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'sessions_history'.tr(),
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    const Icon(Icons.filter_list, color: Colors.white54),
                  ],
                ),
              ),

              // List
              Expanded(
                child: myAttendances.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.history, color: Colors.white24, size: 60),
                            const SizedBox(height: 16),
                            Text('no_history'.tr(), style: const TextStyle(color: Colors.white70, fontSize: 16)),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: myAttendances.length,
                        itemBuilder: (context, index) {
                          return _buildAttendanceCard(myAttendances[index], cardColor, tealColor);
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.white)),
      ],
    );
  }

  Widget _buildAttendanceCard(dynamic att, Color cardColor, Color tealColor) {
    final session = att['session'] ?? {};
    final labName = session['room']?['name'] ?? 'laboratory_title'.tr();
    final courseName = 'course_session'.tr();
    final time = _formatDateTime(att['checkedInAt']);
    final isQr = att['method'] == 'qr';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white12, width: 0.5),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: tealColor.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(isQr ? Icons.qr_code : Icons.check_circle_outline, color: tealColor, size: 24),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  courseName,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white),
                ),
                const SizedBox(height: 4),
                Text(labName, style: const TextStyle(fontSize: 13, color: Colors.white70)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                time,
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Colors.white),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

