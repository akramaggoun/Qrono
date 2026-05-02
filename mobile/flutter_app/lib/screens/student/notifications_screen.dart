import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import 'package:provider/provider.dart';
import '../../providers/notification_provider.dart';
import '../../models/notification_model.dart';
import 'package:easy_localization/easy_localization.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
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
        title: Text('notifications'.tr()),
        actions: [
          TextButton(
            onPressed: () => Provider.of<NotificationProvider>(context, listen: false).markAllAsRead(),
            child: Text('read_all'.tr(), style: const TextStyle(color: AppColors.primaryTeal)),
          ),
        ],
      ),
      body: Consumer<NotificationProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading && provider.notifications.isEmpty) {
            return const Center(child: CircularProgressIndicator(color: AppColors.primaryTeal));
          }

          if (provider.notifications.isEmpty) {
            return _buildEmptyState();
          }

          return RefreshIndicator(
            onRefresh: () => provider.fetchNotifications(),
            color: AppColors.primaryTeal,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
              itemCount: provider.notifications.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final notification = provider.notifications[index];
                return _NotificationTile(notification: notification);
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.notifications_off_outlined, size: 80, color: AppColors.grayText.withValues(alpha: 0.5)),
          const SizedBox(height: 16),
          Text(
            'no_notifications_yet'.tr(),
            style: const TextStyle(color: AppColors.grayText, fontSize: 16),
          ),
        ],
      ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  final NotificationModel notification;

  const _NotificationTile({required this.notification});

  @override
  Widget build(BuildContext context) {
    Color iconColor;
    IconData iconData;

    switch (notification.type.toUpperCase()) {
      case 'ATTENDANCE_RECORDED':
        iconColor = Colors.green;
        iconData = Icons.verified_user_rounded;
        break;
      case 'WARNING':
        iconColor = Colors.orange;
        iconData = Icons.error_outline;
        break;
      default:
        iconColor = AppColors.primaryTeal;
        iconData = Icons.notifications_active_rounded;
    }

    final isUnread = !notification.isRead;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isUnread ? AppColors.primaryTeal.withValues(alpha: 0.3) : AppColors.borderColor,
          width: 0.5,
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(iconData, color: iconColor, size: 24),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                notification.localizedTitle,
                style: TextStyle(
                  fontWeight: isUnread ? FontWeight.bold : FontWeight.w600,
                  fontSize: 15,
                  color: Colors.black87,
                ),
              ),
            ),
            if (isUnread)
              const CircleAvatar(radius: 4, backgroundColor: AppColors.primaryTeal),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              notification.localizedBody,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 13, color: Colors.black54),
            ),
            const SizedBox(height: 8),
            Text(
              _formatDate(notification.createdAt),
              style: const TextStyle(fontSize: 11, color: AppColors.grayText),
            ),
          ],
        ),
        onTap: () {
          if (isUnread) {
             Provider.of<NotificationProvider>(context, listen: false).markAsRead(notification.id);
          }
        },
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    if (difference.inMinutes < 60) return "${difference.inMinutes}${ 'mins_ago'.tr()}";
    if (difference.inHours < 24) return "${difference.inHours}${ 'hours_ago'.tr()}";
    return DateFormat('MMM dd').format(date);
  }
}