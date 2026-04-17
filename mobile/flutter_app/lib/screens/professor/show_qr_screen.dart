import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';
import '../../models/session_model.dart';
import '../../providers/session_provider.dart';

class ShowQrScreen extends StatefulWidget {
  final SessionModel session;
  const ShowQrScreen({super.key, required this.session});

  @override
  State<ShowQrScreen> createState() => _ShowQrScreenState();
}

class _ShowQrScreenState extends State<ShowQrScreen> {
  Timer? _timer;
  Duration _timeLeft = Duration.zero;

  @override
  void initState() {
    super.initState();
    _calculateTimeLeft();
    _startTimer();
  }

  void _calculateTimeLeft() {
    final now = DateTime.now();
    setState(() {
      _timeLeft = widget.session.endTime.isAfter(now)
          ? widget.session.endTime.difference(now)
          : Duration.zero;
    });
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_timeLeft.inSeconds > 0) {
        setState(() => _timeLeft -= const Duration(seconds: 1));
      } else {
        _timer?.cancel();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String _formatDuration(Duration d) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(d.inHours)}:${two(d.inMinutes.remainder(60))}:${two(d.inSeconds.remainder(60))}';
  }

  void _closeSession() async {
    final sessionProvider = Provider.of<SessionProvider>(context, listen: false);
    final success = await sessionProvider.closeSession(widget.session.id!);

    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Session closed successfully.'), backgroundColor: AppColors.success));
        Navigator.of(context).pop();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Error closing session.'), backgroundColor: AppColors.danger));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isActive = _timeLeft.inSeconds > 0;
    final String qrData = widget.session.qrToken ?? 'ERROR: NO TOKEN';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        centerTitle: true,
        title: const Column(
          children: [
            Text('PRESENCE QR CODE', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, letterSpacing: 1)),
            Text('Students can now register their attendance', style: TextStyle(fontSize: 10, color: Colors.white70, fontWeight: FontWeight.w400)),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 40),
        child: Column(
          children: [
            _buildStatusBadge(isActive),
            const SizedBox(height: 24),
            _buildSessionInfo(),
            const SizedBox(height: 24),
            _buildCountdownModule(),
            const SizedBox(height: 32),
            _buildQrModule(qrData),
            const SizedBox(height: 48),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _closeSession,
                icon: const Icon(Icons.stop_circle_rounded, size: 20),
                label: const Text('TERMINATE SESSION NOW', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1, fontSize: 13)),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.danger,
                  side: const BorderSide(color: AppColors.danger, width: 2),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(bool isActive) {
    final color = isActive ? AppColors.success : AppColors.danger;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3), width: 1.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 10, height: 10,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle, boxShadow: [BoxShadow(color: color.withOpacity(0.5), blurRadius: 8, spreadRadius: 2)]),
          ),
          const SizedBox(width: 12),
          Text(
            isActive ? 'BROADCASTING LIVE' : 'SESSION EXPIRED',
            style: TextStyle(color: color, fontWeight: FontWeight.w900, fontSize: 12, letterSpacing: 1.5),
          ),
        ],
      ),
    );
  }

  Widget _buildSessionInfo() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), boxShadow: AppColors.softShadow),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(widget.session.courseName, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: AppColors.textPrimary)),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.schedule_rounded, size: 16, color: AppColors.primary),
              const SizedBox(width: 8),
              Text(
                '${DateFormat('HH:mm').format(widget.session.startTime)} - ${DateFormat('HH:mm').format(widget.session.endTime)}',
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textSecondary),
              ),
              const Spacer(),
              if (widget.session.groupName != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(8)),
                  child: Text(widget.session.groupName!, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: AppColors.textLight)),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCountdownModule() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [AppColors.primary, AppColors.primary.withBlue(200)]),
        borderRadius: BorderRadius.circular(24),
        boxShadow: AppColors.activeShadow,
      ),
      child: Column(
        children: [
          const Text('REMAINING TIME', style: TextStyle(fontSize: 10, letterSpacing: 2.5, color: Colors.white70, fontWeight: FontWeight.w900)),
          const SizedBox(height: 8),
          Text(
            _formatDuration(_timeLeft),
            style: const TextStyle(fontSize: 42, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 2, fontFeatures: [FontFeature.tabularFigures()]),
          ),
        ],
      ),
    );
  }

  Widget _buildQrModule(String data) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(32),
        boxShadow: AppColors.softShadow,
        border: Border.all(color: AppColors.border.withOpacity(0.5)),
      ),
      child: Column(
        children: [
          QrImageView(
            data: data,
            version: QrVersions.auto,
            size: 240.0,
            eyeStyle: const QrEyeStyle(eyeShape: QrEyeShape.square, color: AppColors.primary),
            dataModuleStyle: const QrDataModuleStyle(dataModuleShape: QrDataModuleShape.square, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 24),
          const Text(
            'STUDENTS: PLEASE SCAN THIS CODE TO REGISTER PRESENCE',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 11, letterSpacing: 1.2, fontWeight: FontWeight.w900, color: AppColors.textLight, height: 1.5),
          ),
          const SizedBox(height: 8),
          const Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.textLight, size: 20),
        ],
      ),
    );
  }
}
