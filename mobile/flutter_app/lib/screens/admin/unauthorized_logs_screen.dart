import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
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
      return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}  ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return isoString;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        centerTitle: true,
        title: const Column(
          children: [
            Text('SECURITY SURVEILLANCE', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, letterSpacing: 1)),
            Text('Unauthorized access diagnostics', style: const TextStyle(fontSize: 10, color: Colors.white70)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Colors.white),
            onPressed: () => context.read<AdminProvider>().fetchUnauthorizedLogs(),
            tooltip: 'Refresh Logs',
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Consumer<AdminProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator(color: AppColors.primary));
          }

          final logs = provider.unauthorizedLogs;
          if (logs.isEmpty) {
            return _buildEmptyState();
          }

          return Column(
            children: [
              _buildSummaryHeader(logs.length),
              const Divider(height: 1),
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                  itemCount: logs.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) => _buildLogCard(logs[index]),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSummaryHeader(int total) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: AppColors.danger.withOpacity(0.1), borderRadius: BorderRadius.circular(16)),
            child: const Icon(Icons.gpp_maybe_rounded, color: AppColors.danger, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('$total SECURITY THREATS DETECTED', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13, color: AppColors.danger, letterSpacing: 0.5)),
                const Text('Review all unauthorized interaction attempts below.', style: TextStyle(fontSize: 11, color: AppColors.textLight, fontWeight: FontWeight.w500)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLogCard(UnauthorizedLogModel log) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: AppColors.danger.withOpacity(0.15)), boxShadow: AppColors.softShadow),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: AppColors.danger.withOpacity(0.05),
            child: Row(
              children: [
                const Icon(Icons.warning_amber_rounded, color: AppColors.danger, size: 18),
                const SizedBox(width: 12),
                const Expanded(child: Text('SECURITY ALERT', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 11, color: AppColors.danger, letterSpacing: 1))),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(color: AppColors.danger, borderRadius: BorderRadius.circular(8)),
                  child: const Text('CRITICAL', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 1)),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                _buildDiagnosticRow(Icons.calendar_today_rounded, 'TIMESTAMP', _formatDate(log.occurredAt.toString())),
                const Padding(padding: EdgeInsets.symmetric(vertical: 16), child: Divider(height: 1)),
                _buildDiagnosticRow(Icons.description_rounded, 'DETECTION REASON', log.reason, valueColor: AppColors.danger),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDiagnosticRow(IconData icon, String label, String value, {Color? valueColor}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: AppColors.textLight),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: AppColors.textLight, letterSpacing: 1)),
              const SizedBox(height: 4),
              Text(value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: valueColor ?? AppColors.textPrimary)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(color: AppColors.success.withOpacity(0.1), shape: BoxShape.circle),
            child: const Icon(Icons.verified_user_rounded, size: 64, color: AppColors.success),
          ),
          const SizedBox(height: 32),
          const Text('SYSTEM INTEGRITY SECURE', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: AppColors.textPrimary)),
          const SizedBox(height: 12),
          const Text('No unauthorized access attempts detected.\nYour perimeter remains protected.', style: TextStyle(color: AppColors.textSecondary, fontSize: 14, fontWeight: FontWeight.w500), textAlign: TextAlign.center),
        ],
      ),
    );
  }
}
