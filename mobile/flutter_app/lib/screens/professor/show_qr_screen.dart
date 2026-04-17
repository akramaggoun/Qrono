import 'dart:convert';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:provider/provider.dart';
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
    if (widget.session.endTime.isAfter(now)) {
      setState(() {
        _timeLeft = widget.session.endTime.difference(now);
      });
    } else {
      setState(() {
        _timeLeft = Duration.zero;
      });
    }
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_timeLeft.inSeconds > 0) {
        setState(() {
          _timeLeft = _timeLeft - const Duration(seconds: 1);
        });
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

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    return "${twoDigits(duration.inHours)}:$twoDigitMinutes:$twoDigitSeconds";
  }

  void _handleCloseSession() async {
    final sessionProvider = Provider.of<SessionProvider>(context, listen: false);
    final success = await sessionProvider.closeSession(widget.session.id!); // UML Step 7

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Session fermée avec succès.'),
        backgroundColor: Colors.green,
      ));
      Navigator.of(context).pop();
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Erreur lors de la fermeture de la session.'),
        backgroundColor: Colors.redAccent,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final Map<String, dynamic> qrPayload = {
      'course_name': widget.session.courseName,
      'lab_id': widget.session.labId,
      'group_id': widget.session.groupId,
      'professor_id': widget.session.professorId,
      'start_time': widget.session.startTime.toIso8601String(),
      'end_time': widget.session.endTime.toIso8601String(),
      'session_id': widget.session.id,
    };

    final String qrData = jsonEncode(qrPayload);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Code QR de la Session'),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(30.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: _timeLeft.inSeconds > 0 ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _timeLeft.inSeconds > 0 ? Icons.wifi_tethering : Icons.portable_wifi_off, 
                      color: _timeLeft.inSeconds > 0 ? Colors.green : Colors.red, 
                      size: 16
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _timeLeft.inSeconds > 0 ? 'SESSION ACTIVE' : 'SESSION EXPIRÉE', 
                      style: TextStyle(
                        color: _timeLeft.inSeconds > 0 ? Colors.green : Colors.red, 
                        fontWeight: FontWeight.bold, 
                        fontSize: 12
                      )
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              
              Text(
                widget.session.courseName,
                style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.black87),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              
              // IHM: Countdown Timer (UML Step 6)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.primaryTeal.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    const Text('TEMPS RESTANT', style: TextStyle(fontSize: 10, letterSpacing: 1, color: AppColors.grayText)),
                    Text(
                      _formatDuration(_timeLeft),
                      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.primaryTeal, fontFeatures: [FontFeature.tabularFigures()]),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 30),

              Container(
                padding: const EdgeInsets.all(25),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(color: AppColors.borderColor, width: 1),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.06),
                      blurRadius: 30,
                      offset: const Offset(0, 15),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    QrImageView(
                      data: qrData,
                      version: QrVersions.auto,
                      size: 260.0,
                      eyeStyle: const QrEyeStyle(
                        eyeShape: QrEyeShape.square,
                        color: AppColors.primaryTeal,
                      ),
                      dataModuleStyle: const QrDataModuleStyle(
                        dataModuleShape: QrDataModuleShape.square,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'SCANNEZ POUR MARQUER LA PRÉSENCE',
                      style: TextStyle(
                        fontSize: 10,
                        letterSpacing: 1.2,
                        fontWeight: FontWeight.bold,
                        color: AppColors.grayText,
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 50),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildTimeInfo(Icons.login, 'Début: ${TimeOfDay.fromDateTime(widget.session.startTime).format(context)}'),
                  const SizedBox(width: 30),
                  _buildTimeInfo(Icons.logout, 'Fin: ${TimeOfDay.fromDateTime(widget.session.endTime).format(context)}'),
                ],
              ),
              
              const SizedBox(height: 40),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _handleCloseSession,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    backgroundColor: Colors.redAccent.withOpacity(0.1),
                    foregroundColor: Colors.redAccent,
                    elevation: 0,
                  ),
                  child: const Text('ARRÊTER LA SESSION', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTimeInfo(IconData icon, String text) {
    return Column(
      children: [
        Icon(icon, color: AppColors.primaryTeal, size: 20),
        const SizedBox(height: 5),
        Text(text, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.black87)),
      ],
    );
  }
}
