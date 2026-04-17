import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/presence_provider.dart';

import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

class ConfirmPresenceScreen extends StatelessWidget {
  final Map<String, dynamic> attendanceData;

  const ConfirmPresenceScreen({
    super.key,
    required this.attendanceData,
  });

  @override
  Widget build(BuildContext context) {
    final session = attendanceData['session'] ?? {};
    final checkInAt = DateTime.parse(attendanceData['check_in_at']);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Succès du Scan'),
        automaticallyImplyLeading: false,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 20),
            const Icon(Icons.check_circle, color: AppColors.primaryTeal, size: 100),
            const SizedBox(height: 20),
            const Text(
              'Présence Enregistrée ! ✅',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: AppColors.primaryTeal,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'Votre présence a été validée pour la session actuelle.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.grayText),
            ),
            const SizedBox(height: 40),

            // Card des détails de la session (Step 9)
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.cardColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.borderColor),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 5)),
                ],
              ),
              child: Column(
                children: [
                  _buildDetailRow(Icons.book_outlined, 'Matière', session['course_name'] ?? 'Inconnu'),
                  const Divider(height: 30),
                  _buildDetailRow(Icons.science_outlined, 'Laboratoire', session['laboratory'] ?? 'Non spécifié'),
                  const Divider(height: 30),
                  _buildDetailRow(Icons.groups_outlined, 'Groupe', session['group'] ?? 'Tout le groupe'),
                  const Divider(height: 30),
                  _buildDetailRow(Icons.access_time, 'Heure d\'entrée', DateFormat('HH:mm:ss').format(checkInAt)),
                ],
              ),
            ),

            const Spacer(),

            // Bouton de retour
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 18),
                backgroundColor: AppColors.primaryTeal,
              ),
              child: const Text(
                'RETOUR AU TABLEAU DE BORD',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, color: AppColors.primaryTeal, size: 24),
        const SizedBox(width: 15),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(fontSize: 12, color: AppColors.grayText)),
            Text(
              value,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
            ),
          ],
        ),
      ],
    );
  }
}
