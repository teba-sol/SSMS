import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../../models/announcement_model.dart';

class PriorityBadge extends StatelessWidget {
  final AnnouncementPriority priority;
  const PriorityBadge({super.key, required this.priority});

  @override
  Widget build(BuildContext context) {
    final (color, bg, icon) = switch (priority) {
      AnnouncementPriority.urgent => (AppColors.error, AppColors.errorLight, Icons.priority_high_rounded),
      AnnouncementPriority.high => (AppColors.warning, AppColors.warningLight, Icons.keyboard_arrow_up_rounded),
      AnnouncementPriority.normal => (AppColors.primary, AppColors.primaryLight, Icons.remove_rounded),
      AnnouncementPriority.low => (AppColors.textSecondary, AppColors.surfaceVariant, Icons.keyboard_arrow_down_rounded),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 3),
          Text(priority.label,
              style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: color)),
        ],
      ),
    );
  }
}

class AttendanceBadge extends StatelessWidget {
  final String status;
  const AttendanceBadge({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final (color, bg, label) = switch (status) {
      'present' => (AppColors.attendancePresent, AppColors.attendancePresentLight, 'Present'),
      'absent' => (AppColors.attendanceAbsent, AppColors.attendanceAbsentLight, 'Absent'),
      'late' => (AppColors.attendanceLate, AppColors.attendanceLateLight, 'Late'),
      'excused' => (AppColors.attendanceExcused, AppColors.attendanceExcusedLight, 'Excused'),
      _ => (AppColors.textSecondary, AppColors.surfaceVariant, status),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
            fontSize: 12, fontWeight: FontWeight.w600, color: color),
      ),
    );
  }
}
