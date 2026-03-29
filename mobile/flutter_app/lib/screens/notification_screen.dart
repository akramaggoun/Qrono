import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/notification_provider.dart';
import '../../models/notification_model.dart';
import 'package:intl/intl.dart';

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
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          TextButton(
            onPressed: () => Provider.of<NotificationProvider>(context, listen: false).markAllAsRead(),
            child: const Text('Tout marquer lu', style: TextStyle(color: AppColors.primaryTeal)),
          ),
        ],
      ),
      body: Consumer<NotificationProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading && provider.notifications.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.notifications.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.notifications_none, size: 80, color: Colors.grey.shade300),
                  const SizedBox(height: 16),
                  const Text('Aucune notification', style: TextStyle(color: AppColors.grayText, fontSize: 16)),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () => provider.fetchNotifications(),
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: provider.notifications.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final notification = provider.notifications[index];
                return _NotificationCard(notification: notification);
              },
            ),
          );
        },
      ),
    );
  }
}

class _NotificationCard extends StatelessWidget {
  final NotificationModel notification;

  const _NotificationCard({required this.notification});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<NotificationProvider>(context, listen: false);
    final isUnread = !notification.isRead;
    
    return InkWell(
      onTap: () {
        if (isUnread) provider.markAsRead(notification.id);
        // Navigate or show data if needed
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isUnread ? AppColors.primaryTeal.withOpacity(0.05) : AppColors.cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isUnread ? AppColors.primaryTeal.withOpacity(0.2) : AppColors.borderColor,
            width: isUnread ? 1.5 : 1.0,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildIcon(),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        notification.title,
                        style: TextStyle(
                          fontWeight: isUnread ? FontWeight.bold : FontWeight.w600,
                          fontSize: 15,
                          color: Colors.black87,
                        ),
                      ),
                      Text(
                        _formatDate(notification.createdAt),
                        style: const TextStyle(fontSize: 11, color: AppColors.grayText),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    notification.body,
                    style: TextStyle(
                      fontSize: 13,
                      color: isUnread ? Colors.black54 : AppColors.grayText,
                      height: 1.4,
                    ),
                  ),
                  if (isUnread) ...[
                    const SizedBox(height: 8),
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: AppColors.primaryTeal,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIcon() {
    IconData iconData;
    Color iconColor;

    switch (notification.type) {
      case 'ATTENDANCE_RECORDED':
        iconData = Icons.check_circle_outline;
        iconColor = Colors.green;
        break;
      case 'SESSION_STARTED':
        iconData = Icons.event_available;
        iconColor = Colors.blue;
        break;
      case 'SESSION_CLOSED':
        iconData = Icons.lock_outline;
        iconColor = Colors.orange;
        break;
      case 'UNAUTHORIZED_ACCESS':
        iconData = Icons.warning_amber_rounded;
        iconColor = Colors.red;
        break;
      default:
        iconData = Icons.notifications_none;
        iconColor = AppColors.primaryTeal;
    }

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: iconColor.withOpacity(0.1),
        shape: BoxShape.circle,
      ),
      child: Icon(iconData, color: iconColor, size: 24),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h';
    } else {
      return DateFormat('dd/MM').format(date);
    }
  }
}
