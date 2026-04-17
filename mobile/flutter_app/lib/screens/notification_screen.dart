import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../core/constants/app_colors.dart';
import '../providers/notification_provider.dart';
import '../models/notification_model.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
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
        centerTitle: true,
        title: const Column(
          children: [
            Text('NOTIFICATIONS', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, letterSpacing: 1)),
            Text('Stay updated with your academic activity', style: TextStyle(fontSize: 10, color: Colors.white70, fontWeight: FontWeight.w400)),
          ],
        ),
        actions: [
          Consumer<NotificationProvider>(
            builder: (context, provider, _) => provider.unreadCount > 0
                ? TextButton(
                    onPressed: () => provider.markAllAsRead(),
                    child: const Text('Mark all read', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w800)),
                  )
                : const SizedBox.shrink(),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Consumer<NotificationProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading && provider.notifications.isEmpty) {
            return const Center(child: CircularProgressIndicator(color: AppColors.primary));
          }

          if (provider.notifications.isEmpty) {
            return _buildEmptyState();
          }

          return RefreshIndicator(
            onRefresh: () => provider.fetchNotifications(),
            color: AppColors.primary,
            child: ListView.separated(
              padding: const EdgeInsets.all(20),
              itemCount: provider.notifications.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) => _NotificationCard(notification: provider.notifications[index]),
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
            child: const Icon(Icons.notifications_none_rounded, size: 52, color: AppColors.textLight),
          ),
          const SizedBox(height: 24),
          const Text('All clear!', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: AppColors.textPrimary)),
          const SizedBox(height: 8),
          const Text('You have no new notifications to show.', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
        ],
      ),
    );
  }
}

class _NotificationCard extends StatelessWidget {
  final NotificationModel notification;

  const _NotificationCard({required this.notification});

  IconData _getIcon(String? type) {
    switch (type) {
      case 'ATTENDANCE_RECORDED': return Icons.verified_user_rounded;
      case 'SESSION_STARTED': return Icons.play_circle_filled_rounded;
      case 'SESSION_CLOSED': return Icons.stop_circle_rounded;
      case 'UNAUTHORIZED_ACCESS': return Icons.gpp_bad_rounded;
      default: return Icons.notifications_active_rounded;
    }
  }

  Color _getColor(String? type) {
    switch (type) {
      case 'ATTENDANCE_RECORDED': return AppColors.success;
      case 'SESSION_STARTED': return AppColors.primary;
      case 'SESSION_CLOSED': return AppColors.warning;
      case 'UNAUTHORIZED_ACCESS': return AppColors.danger;
      default: return AppColors.primary;
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return DateFormat('MMM dd').format(date);
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<NotificationProvider>(context, listen: false);
    final isUnread = !notification.isRead;
    final color = _getColor(notification.type);

    return GestureDetector(
      onTap: () { if (isUnread) provider.markAsRead(notification.id); },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: AppColors.softShadow,
          border: Border.all(color: isUnread ? color.withOpacity(0.3) : AppColors.border.withOpacity(0.5), width: isUnread ? 1.5 : 1),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(14)),
                child: Icon(_getIcon(notification.type), color: color, size: 20),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            notification.title,
                            style: TextStyle(fontWeight: isUnread ? FontWeight.w900 : FontWeight.w700, fontSize: 14, color: AppColors.textPrimary),
                          ),
                        ),
                        if (isUnread) Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(notification.body, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, height: 1.4)),
                    const SizedBox(height: 12),
                    Text(_formatDate(notification.createdAt), style: const TextStyle(fontSize: 10, color: AppColors.textLight, fontWeight: FontWeight.w800)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
