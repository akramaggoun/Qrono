import 'dart:async';
import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:easy_localization/easy_localization.dart';

class QrCodeDisplayScreen extends StatefulWidget {
  final Map<String, dynamic> session;

  const QrCodeDisplayScreen({super.key, required this.session});

  @override
  State<QrCodeDisplayScreen> createState() => _QrCodeDisplayScreenState();
}

class _QrCodeDisplayScreenState extends State<QrCodeDisplayScreen> {
  late Timer _timer;
  late DateTime _endTime;
  Duration _timeRemaining = Duration.zero;
  String _qrData = '';

  @override
  void initState() {
    super.initState();
    _generateQrData();
    _calculateEndTime();
    _startTimer();
  }

  void _generateQrData() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    setState(() {
      _qrData = 'QRONO-SESSION-${widget.session['id']}-$timestamp';
    });
  }

  void _calculateEndTime() {
    final now = DateTime.now();
    final endTimeParts = widget.session['endTime'].split(':');
    _endTime = DateTime(
      now.year,
      now.month,
      now.day,
      int.parse(endTimeParts[0]),
      int.parse(endTimeParts[1]),
    );

    if (_endTime.isBefore(now)) {
       // if we somehow started a session after it's supposed to end, just give it 5 mins
      _endTime = now.add(const Duration(minutes: 5));
    }
  }

  void _startTimer() {
    _updateTimeRemaining();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _updateTimeRemaining();
    });
  }

  void _updateTimeRemaining() {
    final now = DateTime.now();
    if (now.isAfter(_endTime)) {
      _timer.cancel();
      setState(() {
        _timeRemaining = Duration.zero;
      });
      _autoCloseSession();
    } else {
      setState(() {
        _timeRemaining = _endTime.difference(now);
      });
    }
  }

  void _autoCloseSession() {
    if (mounted) {
       _showEndSessionDialog(autoEnd: true);
    }
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = twoDigits(duration.inHours);
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return "$hours:$minutes:$seconds";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(widget.session['course'], style: const TextStyle(color: Colors.black87)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: AppColors.primaryTeal),
            onPressed: () {
              _generateQrData();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('qr_regenerated'.tr()), duration: const Duration(seconds: 2)),
              );
            },
            tooltip: 'regenerate_qr'.tr(),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              _buildSessionInfoCard(),
              const Spacer(),
              
              // Status Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.check_circle, color: Colors.green, size: 16),
                    const SizedBox(width: 8),
                    Text('status_active'.tr(), style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // QR Code
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 20, offset: const Offset(0, 10)),
                  ],
                ),
                child: QrImageView(
                  data: _qrData,
                  version: QrVersions.auto,
                  size: 250.0,
                ),
              ),
              
              const SizedBox(height: 30),
              
              // Timer
              Text(
                'ends_in'.tr(args: [_formatDuration(_timeRemaining)]),
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black87),
              ),
              
              const Spacer(),
              
              // Close Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => _showEndSessionDialog(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.redAccent,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                  child: Text('end_session_btn'.tr(), style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSessionInfoCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(widget.session['course'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.black87)),
              Text(widget.session['day'], style: const TextStyle(color: AppColors.primaryTeal, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.people, size: 16, color: AppColors.grayText),
              const SizedBox(width: 8),
              Text(widget.session['groupName'], style: const TextStyle(color: AppColors.grayText)),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(Icons.location_on, size: 16, color: AppColors.grayText),
              const SizedBox(width: 8),
              Text(widget.session['labName'], style: const TextStyle(color: AppColors.grayText)),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(color: AppColors.primaryTeal.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)),
            child: Text(
              '${widget.session['startTime']} - ${widget.session['endTime']}',
              style: const TextStyle(color: AppColors.primaryTeal, fontWeight: FontWeight.bold, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  void _showEndSessionDialog({bool autoEnd = false}) {
    showDialog(
      context: context,
      barrierDismissible: !autoEnd,
      builder: (ctx) => AlertDialog(
        title: Text(autoEnd ? 'session_ended'.tr() : 'end_session_prompt'.tr()),
        content: Text(autoEnd 
            ? 'session_scheduled_past'.tr(args: [
                widget.session['day']?.toString().toLowerCase().tr() ?? '',
                widget.session['startTime'] ?? '',
                widget.session['endTime'] ?? ''
              ]) 
            : 'end_session_desc'.tr()),
        actions: [
          if (!autoEnd)
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('keep_active'.tr(), style: const TextStyle(color: AppColors.grayText)),
            ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              elevation: 0,
            ),
            onPressed: () {
              Navigator.pop(ctx); // close dialog
              Navigator.pop(context); // close QR screen
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('session_ended_toast'.tr()), backgroundColor: AppColors.primaryTeal),
              );
            },
            child: Text(autoEnd ? 'got_it'.tr() : 'end_session_btn'.tr(), style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

