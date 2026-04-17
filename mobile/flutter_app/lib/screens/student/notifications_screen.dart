import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final List<Map<String, dynamic>> _notifications = [
    {
      'title': 'Présence Confirmée',
      'body': 'Votre présence au Labo Informatique 01 a été validée.',
      'time': 'Il y a 10 min',
      'type': 'success',
      'isRead': false,
    },
    {
      'title': 'Nouvelle Session',
      'body': 'Dr. Benahmed vient de lancer une session au Labo 03.',
      'time': 'Il y a 1 heure',
      'type': 'info',
      'isRead': false,
    },
    {
      'title': 'Alerte Absence',
      'body': 'Vous avez été marqué absent au TP de Physique hier.',
      'time': 'Hier à 16:00',
      'type': 'warning',
      'isRead': true,
    },
    {
      'title': 'Mise à jour Système',
      'body': 'L\'application Qrono a été mise à jour avec succès.',
      'time': '2 jours',
      'type': 'info',
      'isRead': true,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          TextButton(
            onPressed: () {
              // Marquer tout comme lu
              setState(() {
                for (var n in _notifications) {
                  n['isRead'] = true;
                }
              });
            },
            child: const Text('Tout lire', style: TextStyle(color: AppColors.primaryTeal)),
          ),
        ],
      ),
      body: _notifications.isEmpty
          ? _buildEmptyState()
          : ListView.separated(
              padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
              itemCount: _notifications.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final item = _notifications[index];
                return _buildNotificationTile(item);
              },
            ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.notifications_off_outlined, size: 80, color: AppColors.grayText.withOpacity(0.5)),
          const SizedBox(height: 16),
          const Text(
            'Aucune notification pour le moment',
            style: TextStyle(color: AppColors.grayText, fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationTile(Map<String, dynamic> item) {
    Color iconColor;
    IconData iconData;

    switch (item['type']) {
      case 'success':
        iconColor = Colors.green;
        iconData = Icons.check_circle_outline;
        break;
      case 'warning':
        iconColor = Colors.orange;
        iconData = Icons.error_outline;
        break;
      default:
        iconColor = AppColors.primaryTeal;
        iconData = Icons.info_outline;
    }

    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: item['isRead'] ? AppColors.borderColor : AppColors.primaryTeal.withOpacity(0.3),
          width: 0.5,
        ),
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
                item['title'],
                style: TextStyle(
                  fontWeight: item['isRead'] ? FontWeight.w600 : FontWeight.bold,
                  fontSize: 15,
                  color: Colors.black87,
                ),
              ),
            ),
            if (!item['isRead'])
              const CircleAvatar(radius: 4, backgroundColor: AppColors.primaryTeal),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              item['body'],
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 13, color: Colors.black54),
            ),
            const SizedBox(height: 6),
            Text(
              item['time'],
              style: const TextStyle(fontSize: 11, color: AppColors.grayText),
            ),
          ],
        ),
        onTap: () {
          setState(() {
            item['isRead'] = true;
          });
          // Action lors de l'ouverture
        },
      ),
    );
  }
}
