import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

import 'package:easy_localization/easy_localization.dart';

class ConfirmPresenceScreen extends StatelessWidget {
  final Map<String, dynamic> attendanceData;

  const ConfirmPresenceScreen({
    super.key,
    required this.attendanceData,
  });

  @override
  Widget build(BuildContext context) {
    final session = attendanceData['session'] ?? {};
    final checkInAt = attendanceData['checkInAt'] != null 
        ? DateTime.parse(attendanceData['checkInAt']).toLocal() 
        : DateTime.now();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('scan_success'.tr()),
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
            Text(
              'presence_saved'.tr(),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: AppColors.primaryTeal,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'presence_validated'.tr(),
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
                  BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 5)),
                ],
              ),
              child: Column(
                children: [
                  _buildDetailRow(Icons.book_outlined, 'subject'.tr(), session['courseName'] ?? 'unknown'.tr()),
                  const Divider(height: 30),
                  _buildDetailRow(Icons.science_outlined, 'laboratory'.tr(), session['laboratory'] ?? 'not_specified'.tr()),
                  const Divider(height: 30),
                  _buildDetailRow(Icons.groups_outlined, 'group'.tr(), session['group'] ?? 'entire_group'.tr()),
                  const Divider(height: 30),
                  _buildDetailRow(Icons.access_time, 'entry_time'.tr(), DateFormat('HH:mm:ss').format(checkInAt)),
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
              child: Text(
                'back_to_dashboard'.tr(),
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

