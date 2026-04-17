import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';

class ConfirmPresenceScreen extends StatelessWidget {
  final Map<String, dynamic> attendanceData;

  const ConfirmPresenceScreen({super.key, required this.attendanceData});

  @override
  Widget build(BuildContext context) {
    final session = attendanceData['session'] ?? {};
    final checkInAt = attendanceData['checkInAt'] != null
        ? DateTime.parse(attendanceData['checkInAt'])
        : DateTime.now();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Column(
            children: [
              const Spacer(),
              
              // ── SUCCESS MODULE ─────────────────────────────────────
              Container(
                padding: const EdgeInsets.all(40),
                decoration: BoxDecoration(
                  color: AppColors.success.withOpacity(0.05),
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.success.withOpacity(0.1), width: 2),
                ),
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(colors: [AppColors.success, Color(0xFF34D399)], begin: Alignment.topLeft, end: Alignment.bottomRight),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.check_rounded, color: Colors.white, size: 64),
                ),
              ),
              const SizedBox(height: 32),
              const Text(
                'Attendance Verified',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: AppColors.textPrimary),
              ),
              const SizedBox(height: 12),
              const Text(
                'Your presence has been successfully recorded for this session.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textSecondary, fontSize: 14, height: 1.5, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 48),

              // ── SESSION DETAILS ─────────────────────────────────────
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: AppColors.softShadow,
                  border: Border.all(color: AppColors.border.withOpacity(0.5)),
                ),
                child: Column(
                  children: [
                    _buildPremiumRow(Icons.book_rounded, 'SUBJECT', session['courseName'] ?? 'Academic Session'),
                    const Padding(padding: EdgeInsets.symmetric(vertical: 16), child: Divider(height: 1)),
                    _buildPremiumRow(Icons.location_on_rounded, 'LOCATION', session['laboratory'] ?? 'Campus Hall'),
                    const Padding(padding: EdgeInsets.symmetric(vertical: 16), child: Divider(height: 1)),
                    _buildPremiumRow(Icons.access_time_filled_rounded, 'TIMESTAMP', DateFormat('HH:mm:ss').format(checkInAt)),
                  ],
                ),
              ),
              
              const Spacer(),

              // ── ACTION BUTTON ─────────────────────────────────────
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  ),
                  child: const Text(
                    'BACK TO DASHBOARD',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, letterSpacing: 1),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPremiumRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(12)),
          child: Icon(icon, color: AppColors.primary, size: 20),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontSize: 10, color: AppColors.textLight, fontWeight: FontWeight.w800, letterSpacing: 1)),
              const SizedBox(height: 2),
              Text(value, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: AppColors.textPrimary)),
            ],
          ),
        ),
      ],
    );
  }
}
