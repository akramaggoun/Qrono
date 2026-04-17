import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/session_provider.dart';

class MySchedulesScreen extends StatefulWidget {
  const MySchedulesScreen({super.key});

  @override
  State<MySchedulesScreen> createState() => _MySchedulesScreenState();
}

class _MySchedulesScreenState extends State<MySchedulesScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<SessionProvider>(context, listen: false).fetchSchedules();
    });
  }

  static const List<String> _dayNames = [
    '', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'
  ];

  String _getDayName(int? day) {
    if (day == null || day < 1 || day > 7) return '';
    return _dayNames[day];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        centerTitle: true,
        title: const Column(
          children: [
            Text('PLANNING & SCHEDULE', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, letterSpacing: 1)),
            Text('Your weekly academic assignments', style: TextStyle(fontSize: 10, color: Colors.white70, fontWeight: FontWeight.w400)),
          ],
        ),
      ),
      body: Consumer<SessionProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading && provider.schedules.isEmpty) {
            return const Center(child: CircularProgressIndicator(color: AppColors.primary));
          }

          if (provider.schedules.isEmpty) {
            return _buildEmptyState();
          }

          // Group by day of the week
          final Map<int, List<dynamic>> byDay = {};
          for (final s in provider.schedules) {
            final day = s.dayOfWeek ?? 0;
            byDay.putIfAbsent(day, () => []).add(s);
          }
          final sortedDays = byDay.keys.toList()..sort();

          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
            itemCount: sortedDays.length,
            itemBuilder: (context, i) {
              final day = sortedDays[i];
              final slots = byDay[day]!;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildDayHeader(_getDayName(day)),
                  const SizedBox(height: 12),
                  ...slots.map((s) => _buildScheduleCard(s)),
                  const SizedBox(height: 24),
                ],
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.05), shape: BoxShape.circle),
            child: const Icon(Icons.calendar_month_rounded, size: 52, color: AppColors.textLight),
          ),
          const SizedBox(height: 24),
          const Text('No classes assigned', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: AppColors.textPrimary)),
          const SizedBox(height: 8),
          const Text('Please contact the administration for your schedule.', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
        ],
      ),
    );
  }

  Widget _buildDayHeader(String day) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(12),
        boxShadow: AppColors.activeShadow,
      ),
      child: Text(
        day.toUpperCase(),
        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 2),
      ),
    );
  }

  Widget _buildScheduleCard(dynamic s) {
    final isActive = s.isActive ?? true;
    final startTime = s.startTime ?? '--:--';
    final endTime = s.endTime ?? '--:--';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppColors.softShadow,
        border: Border.all(color: AppColors.border.withOpacity(0.5)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: AppColors.accent.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                  child: const Icon(Icons.book_rounded, color: AppColors.accent, size: 20),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(s.name, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15, color: AppColors.textPrimary)),
                      if (s.groupName != null)
                        Text('Group: ${s.groupName}', style: const TextStyle(fontSize: 11, color: AppColors.textLight, fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
                _statusIndicator(isActive),
              ],
            ),
            const Padding(padding: EdgeInsets.symmetric(vertical: 16), child: Divider(height: 1)),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.access_time_filled_rounded, size: 14, color: AppColors.primary),
                    const SizedBox(width: 6),
                    Text('$startTime - $endTime', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: AppColors.textPrimary)),
                  ],
                ),
                if (s.labName != null)
                  Row(
                    children: [
                      const Icon(Icons.location_on_rounded, size: 14, color: AppColors.textLight),
                      const SizedBox(width: 4),
                      Text(s.labName!, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, fontWeight: FontWeight.w700)),
                    ],
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _statusIndicator(bool active) {
    return Container(
      width: 10,
      height: 10,
      decoration: BoxDecoration(color: active ? AppColors.success : AppColors.danger, shape: BoxShape.circle, boxShadow: [
        BoxShadow(color: (active ? AppColors.success : AppColors.danger).withOpacity(0.3), blurRadius: 4, spreadRadius: 1)
      ]),
    );
  }
}
