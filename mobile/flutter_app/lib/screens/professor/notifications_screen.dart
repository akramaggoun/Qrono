import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

class ProfessorNotificationsScreen extends StatefulWidget {
  const ProfessorNotificationsScreen({super.key});

  @override
  State<ProfessorNotificationsScreen> createState() => _ProfessorNotificationsScreenState();
}

class _ProfessorNotificationsScreenState extends State<ProfessorNotificationsScreen> {
  final List<Map<String, dynamic>> _notifications = [
    {
      'title': 'Session Terminée',
      'body': 'Votre session au Labo 01 avec le Groupe L3 CNS a été fermée automatiquement.',
      'time': 'Il y a 30 min',
      'type': 'success',
      'isRead': false,
    },
    {
      'title': 'Rappel Session',
      'body': 'N\'oubliez pas de lancer votre session de TP à 14:00 (G2).',
      'time': 'Dans 2 heures',
      'type': 'warning',
      'isRead': false,
    },
    {
      'title': 'Message Admin',
      'body': 'Le Labo 04 sera fermé demain pour maintenance.',
      'time': 'Hier',
      'type': 'info',
      'isRead': true,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Notifications Professeur'),
      ),
      body: _notifications.isEmpty
          ? _buildEmptyState()
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: _notifications.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) => _buildNotificationCard(_notifications[index]),
            ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.notifications_none_outlined, size: 80, color: AppColors.grayText.withOpacity(0.5)),
          const SizedBox(height: 16),
          const Text('Pas de nouvelles notifications.', style: TextStyle(color: AppColors.grayText)),
        ],
      ),
    );
  }

  Widget _buildNotificationCard(Map<String, dynamic> item) {
    Color indicatorColor;
    switch (item['type']) {
      case 'success': indicatorColor = Colors.green; break;
      case 'warning': indicatorColor = Colors.orange; break;
      default: indicatorColor = AppColors.primaryTeal;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderColor, width: 0.5),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Cercle indicateur de statut
          Container(
            width: 10,
            height: 10,
            margin: const EdgeInsets.only(top: 5),
            decoration: BoxDecoration(
              color: item['isRead'] ? Colors.transparent : indicatorColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item['title'],
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87),
                ),
                const SizedBox(height: 5),
                Text(item['body'], style: const TextStyle(color: Colors.black54, fontSize: 14)),
                const SizedBox(height: 10),
                Text(item['time'], style: const TextStyle(color: AppColors.grayText, fontSize: 11)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
