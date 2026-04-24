import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../mock/schedule_mock_data.dart';
import 'package:easy_localization/easy_localization.dart';

class ScheduleGrid extends StatelessWidget {
  final bool isAdmin;
  final List<Map<String, dynamic>> sessions;
  final Function(int dayIndex, int slotIndex) onEmptyCellTap;
  final Function(Map<String, dynamic> session) onFilledCellTap;
  final Function(Map<String, dynamic> session)? onRemoveSession;

  const ScheduleGrid({
    super.key,
    required this.isAdmin,
    required this.sessions,
    required this.onEmptyCellTap,
    required this.onFilledCellTap,
    this.onRemoveSession,
  });

  @override
  Widget build(BuildContext context) {
    const double cellWidth = 140.0;
    const double cellHeight = 90.0;
    const double headerHeight = 40.0;
    const double dayWidth = 60.0;

    int todayIndex = _getTodayIndex();

    return SingleChildScrollView(
      scrollDirection: Axis.vertical,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Padding(
          padding: const EdgeInsets.only(bottom: 20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Row (Time Slots)
              Row(
                children: [
                  SizedBox(
                    width: dayWidth,
                    height: headerHeight,
                    child: const Center(
                      child: Icon(Icons.calendar_today, size: 20, color: AppColors.grayText),
                    ),
                  ),
                  ...List.generate(ScheduleMockData.timeSlots.length, (slotIndex) {
                    return SizedBox(
                      width: cellWidth,
                      height: headerHeight,
                      child: Center(
                        child: Text(
                          ScheduleMockData.timeSlots[slotIndex],
                          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87, fontSize: 13),
                        ),
                      ),
                    );
                  }),
                ],
              ),
              
              // Days Rows
              ...List.generate(ScheduleMockData.weekDays.length, (dayIndex) {
                bool isTodayRow = (!isAdmin && dayIndex == todayIndex);

                return Row(
                  children: [
                    // Day column
                    SizedBox(
                      width: dayWidth,
                      height: cellHeight,
                      child: Center(
                        child: Text(
                          ScheduleMockData.weekDays[dayIndex].toLowerCase().tr().substring(0, 3), 
                          style: TextStyle(
                            fontWeight: isTodayRow ? FontWeight.bold : FontWeight.w500,
                            color: isTodayRow ? AppColors.primaryTeal : AppColors.grayText,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                    
                    // Time slot cells
                    ...List.generate(ScheduleMockData.timeSlots.length, (slotIndex) {
                      // Check if session exists in this slot
                      final session = _getSessionAt(dayIndex, slotIndex);
                      bool isFilled = session != null;

                      return Container(
                        width: cellWidth,
                        height: cellHeight,
                        padding: const EdgeInsets.all(4.0),
                        decoration: BoxDecoration(
                          border: Border(
                            left: BorderSide(color: AppColors.borderColor.withOpacity(0.5)),
                            top: BorderSide(color: AppColors.borderColor.withOpacity(0.5)),
                            bottom: dayIndex == ScheduleMockData.weekDays.length - 1 
                                ? BorderSide(color: AppColors.borderColor.withOpacity(0.5)) : BorderSide.none,
                            right: slotIndex == ScheduleMockData.timeSlots.length - 1 
                                ? BorderSide(color: AppColors.borderColor.withOpacity(0.5)) : BorderSide.none,
                          ),
                          color: isTodayRow ? AppColors.primaryTeal.withOpacity(0.05) : Colors.transparent,
                        ),
                        child: isFilled
                            ? _buildFilledCell(session)
                            : _buildEmptyCell(dayIndex, slotIndex),
                      );
                    }),
                  ],
                );
              }),
            ],
          ),
        ),
      ),
    );
  }

  int _getTodayIndex() {
    int weekday = DateTime.now().weekday;
    // Dart DateTime: 1=Mon, 7=Sun.
    // Our grid: 0=Sun, 1=Mon, 2=Tue, 3=Wed, 4=Thu.
    if (weekday == 7) return 0; // Sun
    if (weekday >= 1 && weekday <= 4) return weekday; // Mon-Thu
    return -1; // Fri/Sat not in grid
  }

  Map<String, dynamic>? _getSessionAt(int dayIndex, int slotIndex) {
    try {
      return sessions.firstWhere(
        (s) => s['dayIndex'] == dayIndex && s['slotIndex'] == slotIndex,
      );
    } catch (_) {
      return null;
    }
  }

  Widget _buildEmptyCell(int dayIndex, int slotIndex) {
    if (!isAdmin) {
      return Container(
        decoration: BoxDecoration(
          color: AppColors.cardColor.withOpacity(0.4),
          borderRadius: BorderRadius.circular(6),
        ),
      );
    }
    
    return GestureDetector(
      onTap: () => onEmptyCellTap(dayIndex, slotIndex),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.cardColor,
          border: Border.all(color: AppColors.borderColor),
          borderRadius: BorderRadius.circular(6),
        ),
        child: const Center(
          child: Icon(Icons.add, color: AppColors.primaryTeal, size: 24),
        ),
      ),
    );
  }

  Widget _buildFilledCell(Map<String, dynamic> session) {
    return GestureDetector(
      onTap: () => onFilledCellTap(session),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.primaryTeal.withOpacity(0.1),
          border: Border.all(color: AppColors.primaryTeal.withOpacity(0.3)),
          borderRadius: BorderRadius.circular(6),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 6.0, vertical: 4.0),
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  session['course'],
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.black87),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  '${session['groupName']}',
                  style: const TextStyle(color: AppColors.grayText, fontSize: 11),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '${session['labName']}',
                  style: const TextStyle(color: AppColors.grayText, fontSize: 11),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
            if (isAdmin && onRemoveSession != null)
              Positioned(
                top: -4,
                right: -4,
                child: GestureDetector(
                  onTap: () => onRemoveSession!(session),
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: const BoxDecoration(
                      color: Colors.white70,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.close, size: 14, color: Colors.redAccent),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
