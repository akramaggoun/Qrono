import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/notification_provider.dart';
import '../../models/notification_model.dart';
import '../../providers/auth_provider.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  @override
  void initState() {
    super.initState();
    // Fetch notifications and initialize socket
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final notificationProvider = context.read<NotificationProvider>();
      final authProvider = context.read<AuthProvider>();
      
      notificationProvider.fetchNotifications();
      if (authProvider.user != null) {
        notificationProvider.initSocket(authProvider.user!.id);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final notificationProvider = context.watch<NotificationProvider>();
    final notifications = notificationProvider.notifications;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          if (notifications.any((n) => !n.isRead))
            TextButton(
              onPressed: () => notificationProvider.markAllAsRead(),
              child: const Text(
                'Mark as read', 
                style: TextStyle(
                  color: Colors.white, 
                  fontSize: 13, 
                  fontWeight: FontWeight.w600
                ),
              ),
            ),
        ],
      ),
      body: notificationProvider.isLoading && notifications.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () => notificationProvider.fetchNotifications(),
              child: notifications.isEmpty
                  ? _buildEmptyState()
                  : ListView.separated(
                      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
                      itemCount: notifications.length,
                      separatorBuilder: (context, index) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final item = notifications[index];
                        return _buildNotificationTile(item);
                      },
                    ),
            ),
    );
  }

  Widget _buildEmptyState() {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: Container(
        height: MediaQuery.of(context).size.height * 0.7,
        alignment: Alignment.center,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.notifications_off_outlined, 
              size: 80, 
              color: AppColors.textLight.withOpacity(0.5)
            ),
            const SizedBox(height: 16),
            const Text(
              'No notifications at the moment',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationTile(NotificationModel item) {
    Color iconColor;
    IconData iconData;

    switch (item.type) {
      case 'ATTENDANCE_RECORDED':
        iconColor = AppColors.success;
        iconData = Icons.check_circle_outline;
        break;
      case 'UNAUTHORIZED_ACCESS':
        iconColor = AppColors.danger;
        iconData = Icons.report_problem_outlined;
        break;
      case 'SESSION_STARTED':
        iconColor = AppColors.info;
        iconData = Icons.event_available_outlined;
        break;
      case 'SESSION_CLOSED':
        iconColor = AppColors.textSecondary;
        iconData = Icons.event_busy_outlined;
        break;
      default:
        iconColor = AppColors.primary;
        iconData = Icons.info_outline;
    }

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: item.isRead ? AppColors.border : AppColors.primary.withOpacity(0.2),
          width: 1,
        ),
        boxShadow: item.isRead ? null : [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(iconData, color: iconColor, size: 24),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                item.title,
                style: TextStyle(
                  fontWeight: item.isRead ? FontWeight.w600 : FontWeight.bold,
                  fontSize: 15,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            if (!item.isRead)
              const CircleAvatar(radius: 4, backgroundColor: AppColors.primary),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              item.body,
              style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 8),
            Text(
              DateFormat('MMM d, h:mm a').format(item.createdAt),
              style: const TextStyle(fontSize: 11, color: AppColors.textLight),
            ),
          ],
        ),
        onTap: () {
          if (!item.isRead) {
            context.read<NotificationProvider>().markAsRead(item.id);
          }
        },
      ),
    );
  }
}
