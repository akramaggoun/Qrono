import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/notification_provider.dart';
import '../../models/notification_model.dart';
import 'package:intl/intl.dart';
import 'package:easy_localization/easy_localization.dart';

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
    const bgColor = Color(0xFFF8FAFB);
    const primaryColor = Color(0xFF1A1C1E);

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
            Text('message_center'.tr(), 
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: primaryColor)),
            Text('recent_alerts_updates'.tr(), 
              style: const TextStyle(fontSize: 12, color: Color(0xFF6C757D), fontWeight: FontWeight.w500)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Provider.of<NotificationProvider>(context, listen: false).markAllAsRead(),
            child: Text('read_all'.tr(), style: const TextStyle(color: AppColors.primaryTeal, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Consumer<NotificationProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading && provider.notifications.isEmpty) {
            return const Center(child: CircularProgressIndicator(color: AppColors.primaryTeal));
          }

          if (provider.notifications.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.notifications_off_rounded, size: 80, color: Colors.grey.withOpacity(0.2)),
                  const SizedBox(height: 16),
                  Text('no_notifications_yet'.tr(), 
                    style: const TextStyle(color: Color(0xFF9E9E9E), fontSize: 16, fontWeight: FontWeight.w500)),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () => provider.fetchNotifications(),
            color: AppColors.primaryTeal,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
              itemCount: provider.notifications.length,
              separatorBuilder: (context, index) => const SizedBox(height: 16),
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
    
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: isUnread ? AppColors.primaryTeal.withOpacity(0.08) : Colors.black.withOpacity(0.03),
            blurRadius: 12,
            offset: const Offset(0, 4)
          )
        ],
        border: isUnread ? Border.all(color: AppColors.primaryTeal.withOpacity(0.2), width: 1) : null,
      ),
      child: InkWell(
        onTap: () {
          if (isUnread) provider.markAsRead(notification.id);
        },
        borderRadius: BorderRadius.circular(22),
        child: Padding(
          padding: const EdgeInsets.all(18),
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
                        Expanded(
                          child: Text(
                            notification.title,
                            style: TextStyle(
                              fontWeight: isUnread ? FontWeight.w900 : FontWeight.w700,
                              fontSize: 15,
                              color: const Color(0xFF1A1C1E),
                            ),
                          ),
                        ),
                        Text(
                          _formatDate(notification.createdAt),
                          style: const TextStyle(fontSize: 11, color: Color(0xFF9E9E9E), fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      notification.body,
                      style: TextStyle(
                        fontSize: 12,
                        color: isUnread ? const Color(0xFF424242) : const Color(0xFF757575),
                        height: 1.5,
                        fontWeight: isUnread ? FontWeight.w500 : FontWeight.w400,
                      ),
                    ),
                    if (isUnread) ...[
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(color: AppColors.primaryTeal.withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
                        child: Text('new_badge'.tr(), style: const TextStyle(color: AppColors.primaryTeal, fontSize: 9, fontWeight: FontWeight.w900)),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIcon() {
    IconData iconData;
    Color iconColor;

    switch (notification.type) {
      case 'ATTENDANCE_RECORDED':
        iconData = Icons.verified_user_rounded;
        iconColor = Colors.green;
        break;
      case 'SESSION_STARTED':
        iconData = Icons.rocket_launch_rounded;
        iconColor = Colors.teal;
        break;
      case 'SESSION_CLOSED':
        iconData = Icons.door_back_door_rounded;
        iconColor = Colors.orange;
        break;
      case 'UNAUTHORIZED_ACCESS':
        iconData = Icons.gpp_bad_rounded;
        iconColor = Colors.redAccent;
        break;
      default:
        iconData = Icons.notifications_active_rounded;
        iconColor = AppColors.primaryTeal;
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: iconColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Icon(iconData, color: iconColor, size: 22),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inMinutes < 60) {
      return '${difference.inMinutes}${'mins_ago'.tr()}';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}${'hours_ago'.tr()}';
    } else {
      return DateFormat('MMM dd').format(date);
    }
  }
}
