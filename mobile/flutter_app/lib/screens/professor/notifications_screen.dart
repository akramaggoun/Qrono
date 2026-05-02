import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import 'package:provider/provider.dart';
import '../../providers/notification_provider.dart';
import '../../models/notification_model.dart';
import 'package:easy_localization/easy_localization.dart';

class ProfessorNotificationsScreen extends StatefulWidget {
  const ProfessorNotificationsScreen({super.key});

  @override
  State<ProfessorNotificationsScreen> createState() => _ProfessorNotificationsScreenState();
}

class _ProfessorNotificationsScreenState extends State<ProfessorNotificationsScreen> {
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
              padding: const EdgeInsets.all(16),
              itemCount: provider.notifications.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
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
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.notifications_none_outlined, size: 80, color: AppColors.grayText.withValues(alpha: 0.5)),
          const SizedBox(height: 16),
          Text('no_notifications_yet'.tr(), style: const TextStyle(color: AppColors.grayText)),
        ],
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
    
    Color indicatorColor;
    switch (notification.type.toUpperCase()) {
      case 'SUCCESS': indicatorColor = Colors.green; break;
      case 'WARNING': indicatorColor = Colors.orange; break;
      default: indicatorColor = AppColors.primaryTeal;
    }

    return InkWell(
      onTap: () {
        if (isUnread) provider.markAsRead(notification.id);
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isUnread ? AppColors.primaryTeal.withValues(alpha: 0.3) : AppColors.borderColor, width: 0.5),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 10,
              height: 10,
              margin: const EdgeInsets.only(top: 5),
              decoration: BoxDecoration(
                color: isUnread ? indicatorColor : Colors.transparent,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    notification.localizedTitle,
                    style: TextStyle(fontWeight: isUnread ? FontWeight.bold : FontWeight.w600, fontSize: 16, color: Colors.black87),
                  ),
                  const SizedBox(height: 5),
                  Text(notification.localizedBody, style: const TextStyle(color: Colors.black54, fontSize: 14)),
                  const SizedBox(height: 10),
                  Text(_formatDate(notification.createdAt), style: const TextStyle(color: AppColors.grayText, fontSize: 11)),
                ],
              ),
            ),
          ],
        ),
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
