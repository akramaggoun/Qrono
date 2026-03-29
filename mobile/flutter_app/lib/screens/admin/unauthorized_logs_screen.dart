import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/admin_provider.dart';
import '../../models/unauthorized_log_model.dart';

class UnauthorizedLogsScreen extends StatefulWidget {
  const UnauthorizedLogsScreen({super.key});

  @override
  State<UnauthorizedLogsScreen> createState() => _UnauthorizedLogsScreenState();
}

class _UnauthorizedLogsScreenState extends State<UnauthorizedLogsScreen> {
  
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AdminProvider>().fetchUnauthorizedLogs();
    });
  }

  String _formatDate(String isoString) {
    try {
      final dt = DateTime.parse(isoString);
      return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return isoString;
    }
  }

  @override
  Widget build(BuildContext context) {
    const bgColor = Color(0xFF0D1117);
    const cardColor = Color(0xFF161B22);
    const tealColor = Color(0xFF00C9A7);
    final alertColor = Colors.red.shade700;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: cardColor,
        iconTheme: const IconThemeData(color: tealColor),
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Sécurité & Alertes', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Colors.white)),
            Text('Logs d\'accès non autorisés', style: TextStyle(fontSize: 11, color: Colors.white70)),
          ],
        ),
      ),
      body: Consumer<AdminProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator(color: tealColor));
          }

          final logs = provider.unauthorizedLogs;

          if (logs.isEmpty) {
            return _buildEmptyState();
          }

          // Compute basic stats if needed
          int highCount = logs.where((l) => [l.reason].contains('Tentative d\'accès multiple')).length;
          int mediumCount = logs.length - highCount; 

          return Column(
            children: [
              _buildSeveritySummary(highCount, mediumCount, 0, logs.length, cardColor, alertColor, tealColor),
              const Divider(height: 1, color: Colors.white12),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: logs.length,
                  itemBuilder: (context, index) => _buildLogCard(logs[index], cardColor, alertColor, tealColor),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSeveritySummary(int high, int medium, int low, int total, Color cardColor, Color alertColor, Color tealColor) {
    return Container(
      color: cardColor,
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          _buildSeverityChip('$high', 'Critiques', alertColor),
          const SizedBox(width: 10),
          _buildSeverityChip('$medium', 'Moyennes', Colors.orange),
          const SizedBox(width: 10),
          _buildSeverityChip('$low', 'Faibles', tealColor),
          const Spacer(),
          Text('Total: $total', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white70)),
        ],
      ),
    );
  }

  Widget _buildSeverityChip(String count, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 6),
          Text('$count $label', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }

  Widget _buildLogCard(UnauthorizedLogModel log, Color cardColor, Color alertColor, Color tealColor) {
    final severityColor = alertColor;
    final severityLabel = '⚠ Critique';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: severityColor.withOpacity(0.25)),
        boxShadow: [BoxShadow(color: severityColor.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 4))],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: severityColor.withOpacity(0.06),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: severityColor.withOpacity(0.15),
                  child: Text(log.id.substring(0,1).toUpperCase(), style: TextStyle(fontWeight: FontWeight.bold, color: severityColor)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Using ID or User if present. The API will pass student info inside.
                      Text('Log ID: ${log.id}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.white)),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: severityColor.withOpacity(0.12), borderRadius: BorderRadius.circular(20)),
                  child: Text(severityLabel, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: severityColor)),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              children: [
                Row(
                  children: [
                    const Icon(Icons.science_outlined, size: 15, color: Colors.white54),
                    const SizedBox(width: 6),
                    const Text('Laboratory', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white)),
                    const Spacer(),
                    const Icon(Icons.access_time, size: 15, color: Colors.white54),
                    const SizedBox(width: 6),
                    Text(_formatDate(log.occurredAt.toString()), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white)),
                  ],
                ),
                const SizedBox(height: 10),
                const Divider(height: 1, color: Colors.white12),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Icon(Icons.info_outline, size: 15, color: severityColor),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(log.reason,
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: severityColor)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.verified_user_outlined, size: 64, color: Colors.green),
          SizedBox(height: 16),
          Text('Aucune alerte', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white)),
          SizedBox(height: 6),
          Text('Le système est sécurisé', style: TextStyle(color: Colors.white70)),
        ],
      ),
    );
  }
}
