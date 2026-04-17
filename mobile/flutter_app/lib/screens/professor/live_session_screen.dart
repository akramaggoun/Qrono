import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../core/constants/app_colors.dart';
import '../../models/schedule_model.dart';
import '../../models/session_model.dart';
import '../../providers/session_provider.dart';
import '../../providers/presence_provider.dart';

class LiveSessionScreen extends StatefulWidget {
  final ScheduleModel schedule;
  const LiveSessionScreen({super.key, required this.schedule});

  @override
  State<LiveSessionScreen> createState() => _LiveSessionScreenState();
}

class _LiveSessionScreenState extends State<LiveSessionScreen> with TickerProviderStateMixin {
  SessionModel? _activeSession;
  bool _initializing = true;
  Timer? _refreshTimer;
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _setupSession();
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _setupSession() async {
    setState(() => _initializing = true);
    final sessionProvider = Provider.of<SessionProvider>(context, listen: false);
    final presenceProvider = Provider.of<PresenceProvider>(context, listen: false);

    if (widget.schedule.groupId != null) {
      await presenceProvider.fetchGroupStudents(widget.schedule.groupId!);
    }

    await sessionProvider.fetchMySessions();
    SessionModel? existing;
    try {
      existing = sessionProvider.sessions.firstWhere((s) => s.status == SessionStatus.ACTIVE);
    } catch (_) {
      existing = null;
    }

    if (existing != null && existing.id != null) {
      setState(() {
        _activeSession = existing;
        _initializing = false;
      });
      _startAttendancePolling();
    } else {
      final now = DateTime.now();
      final newSession = await sessionProvider.createSession({
        'courseName': widget.schedule.name,
        'startTime': now.toIso8601String(),
        'endTime': now.add(const Duration(minutes: 90)).toIso8601String(),
        'groupId': widget.schedule.groupId,
        'labId': widget.schedule.labId,
        'scheduleId': widget.schedule.id,
      });

      if (newSession != null) {
        setState(() {
          _activeSession = newSession;
          _initializing = false;
        });
        _startAttendancePolling();
      } else {
        await sessionProvider.fetchMySessions();
        final recovered = sessionProvider.sessions.where((s) => s.status == SessionStatus.ACTIVE).toList();

        if (recovered.isNotEmpty) {
          if (mounted) {
            setState(() {
              _activeSession = recovered.first;
              _initializing = false;
            });
            _startAttendancePolling();
          }
        } else if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Error: ${sessionProvider.errorMessage ?? "Creation failed"}'),
            backgroundColor: AppColors.danger,
          ));
          Navigator.pop(context);
        }
      }
    }
  }

  void _startAttendancePolling() {
    _refreshTimer = Timer.periodic(const Duration(seconds: 4), (timer) {
      if (_activeSession?.id != null) {
        Provider.of<PresenceProvider>(context, listen: false).fetchSessionAttendance(_activeSession!.id!);
      }
    });
    Provider.of<PresenceProvider>(context, listen: false).fetchSessionAttendance(_activeSession!.id!);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          children: [
            Text(widget.schedule.name, style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w900, fontSize: 18)),
            const Text('LIVE BROADCAST', style: TextStyle(color: AppColors.primary, fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 2)),
          ],
        ),
        actions: const [
          SizedBox(width: 8),
        ],
      ),
      body: _initializing
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Column(
                children: [
                  _buildPulseQR(),
                  const SizedBox(height: 32),
                  _buildInfoCards(),
                  const SizedBox(height: 32),
                  _buildAttendanceModule(),
                  const SizedBox(height: 32),
                  if (_activeSession != null)
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _showEndSessionDialog,
                        icon: const Icon(Icons.power_settings_new_rounded),
                        label: const Text('END LIVE SESSION', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, letterSpacing: 1.5)),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 18),
                          backgroundColor: AppColors.danger,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          elevation: 0,
                        ),
                      ),
                    ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
    );
  }

  Widget _buildEndButton() {
    return _activeSession == null ? const SizedBox.shrink() : Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: ElevatedButton(
        onPressed: _showEndSessionDialog,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.danger.withOpacity(0.1),
          foregroundColor: AppColors.danger,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          padding: const EdgeInsets.symmetric(horizontal: 16),
        ),
        child: const Text('END SESSION', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900)),
      ),
    );
  }

  Widget _buildPulseQR() {
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        return Container(
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withOpacity(0.1 * _pulseController.value),
                blurRadius: 40 * _pulseController.value,
                spreadRadius: 20 * _pulseController.value,
              )
            ],
          ),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(40),
              boxShadow: AppColors.softShadow,
            ),
            child: _activeSession?.qrToken != null
                ? QrImageView(
                    data: _activeSession!.qrToken!,
                    version: QrVersions.auto,
                    size: 200,
                    eyeStyle: const QrEyeStyle(eyeShape: QrEyeShape.square, color: AppColors.primary),
                  )
                : const SizedBox(width: 200, height: 200, child: Center(child: CircularProgressIndicator())),
          ),
        );
      },
    );
  }

  Widget _buildInfoCards() {
    return Row(
      children: [
        _infoCard('LOCATION', widget.schedule.labName ?? 'N/A', Icons.location_on_rounded),
        const SizedBox(width: 16),
        _infoCard('GROUP', widget.schedule.groupName ?? 'N/A', Icons.groups_rounded),
      ],
    );
  }

  Widget _infoCard(String label, String value, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.border.withOpacity(0.5)),
        ),
        child: Column(
          children: [
            Icon(icon, color: AppColors.primary, size: 20),
            const SizedBox(height: 8),
            Text(label, style: const TextStyle(fontSize: 10, color: AppColors.textLight, fontWeight: FontWeight.w800)),
            Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: AppColors.textPrimary)),
          ],
        ),
      ),
    );
  }

  Widget _buildAttendanceModule() {
    return Consumer<PresenceProvider>(
      builder: (context, presence, child) {
        final total = presence.groupStudents.length;
        final present = presence.attendances.length;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('ATTENDANCE FEED', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: AppColors.textLight, letterSpacing: 1.5)),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(10)),
                  child: Text('$present / $total', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 12)),
                ),
              ],
            ),
            const SizedBox(height: 16),
            presence.groupStudents.isEmpty
              ? _buildEmptyState()
              : GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 2.8,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                  itemCount: presence.groupStudents.length,
                  itemBuilder: (context, index) {
                    final student = presence.groupStudents[index];
                    final name = student['user']?['name'] ?? 'Student';
                    final isPresent = presence.attendances.any((a) => a.studentId == student['id']);

                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: isPresent ? AppColors.success.withOpacity(0.05) : Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: isPresent ? AppColors.success : AppColors.border.withOpacity(0.5)),
                      ),
                      child: Row(
                        children: [
                          Icon(isPresent ? Icons.check_circle_rounded : Icons.radio_button_off_rounded, 
                               color: isPresent ? AppColors.success : AppColors.textLight, size: 16),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(name, maxLines: 1, overflow: TextOverflow.ellipsis, 
                                        style: TextStyle(fontSize: 12, fontWeight: isPresent ? FontWeight.w800 : FontWeight.w500)),
                          ),
                        ],
                      ),
                    );
                  },
                ),
          ],
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: AppColors.border)),
      child: const Column(
        children: [
          Icon(Icons.person_search_rounded, size: 40, color: AppColors.textLight),
          SizedBox(height: 16),
          Text('No students registered in this group.', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
        ],
      ),
    );
  }

  void _showEndSessionDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('End Live Session?', style: TextStyle(fontWeight: FontWeight.w900)),
        content: const Text('Closing this session will prevent further attendance logs for students.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('CANCEL')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            onPressed: () async {
              Navigator.pop(ctx);
              if (_activeSession?.id != null) {
                final provider = Provider.of<SessionProvider>(context, listen: false);
                final ok = await provider.closeSession(_activeSession!.id!);
                if (ok && mounted) {
                  Navigator.pop(context);
                } else if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text(provider.errorMessage ?? 'Failed to end session'),
                    backgroundColor: AppColors.danger,
                  ));
                }
              }
            },
            child: const Text('END SESSION'),
          ),
        ],
      ),
    );
  }
}
