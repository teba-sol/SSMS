import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../core/router/route_names.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/loading_widget.dart';
import '../../core/widgets/empty_widget.dart';
import '../../core/widgets/app_card.dart';
import '../../models/attendance_model.dart';
import '../students/students_provider.dart';
import '../dashboard/parent_dashboard_page.dart';
import 'attendance_provider.dart';

class AttendancePage extends ConsumerWidget {
  final bool isParent;
  const AttendancePage({super.key, this.isParent = false});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return isParent ? const _ParentAttendanceView() : const _TeacherAttendanceView();
  }
}

// ── TEACHER VIEW ──────────────────────────────────────────────────────────────
class _TeacherAttendanceView extends ConsumerWidget {
  const _TeacherAttendanceView();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final assignmentsAsync = ref.watch(teacherAssignmentsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Attendance'),
        actions: [
          IconButton(
            onPressed: () => context.push(RouteNames.teacherNotifications),
            icon: const Icon(Icons.notifications_outlined),
          ),
        ],
      ),
      body: assignmentsAsync.when(
        data: (assignments) {
          if (assignments.isEmpty) {
            return EmptyWidget(
              title: 'No Classes Assigned',
              subtitle: 'You have no classes assigned for this academic year.',
              icon: Icons.class_,
            );
          }
          // Group by classId
          final seen = <String>{};
          final uniqueByClass = assignments
              .where((a) => seen.add(a.classId))
              .toList();
          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              const Text(
                'Select a class to mark or view attendance',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
              ),
              const SizedBox(height: 16),
              ...uniqueByClass.map((a) => _AttendanceClassCard(assignment: a)),
            ],
          );
        },
        loading: () => const ShimmerList(count: 3),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }
}

class _AttendanceClassCard extends StatelessWidget {
  final dynamic assignment;
  const _AttendanceClassCard({required this.assignment});

  @override
  Widget build(BuildContext context) {
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    return AppCard(
      padding: const EdgeInsets.all(16),
      onTap: () => context.push(RouteNames.teacherAttendanceMark, extra: {
        'classId': assignment.classId,
        'className': assignment.className,
        'assignmentId': assignment.id,
      }),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.class_,
                    color: AppColors.primary, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(assignment.className,
                        style: const TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 15)),
                    Text('Academic Year: ${assignment.academicYearName}',
                        style: const TextStyle(
                            color: AppColors.textSecondary, fontSize: 12)),
                  ],
                ),
              ),
              ElevatedButton.icon(
                onPressed: () => context.push(
                    RouteNames.teacherAttendanceMark,
                    extra: {
                      'classId': assignment.classId,
                      'className': assignment.className,
                      'assignmentId': assignment.id,
                    }),
                icon: const Icon(Icons.fact_check_outlined, size: 16),
                label: const Text('Mark'),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(80, 36),
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  textStyle: const TextStyle(fontSize: 12),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.today_outlined,
                  size: 14, color: AppColors.textSecondary),
              const SizedBox(width: 4),
              Text(
                'Today: ${DateFormat('EEE, MMM d').format(DateTime.now())}',
                style: const TextStyle(
                    color: AppColors.textSecondary, fontSize: 12),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── PARENT VIEW ──────────────────────────────────────────────────────────────
class _ParentAttendanceView extends ConsumerStatefulWidget {
  const _ParentAttendanceView();

  @override
  ConsumerState<_ParentAttendanceView> createState() =>
      _ParentAttendanceViewState();
}

class _ParentAttendanceViewState extends ConsumerState<_ParentAttendanceView> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  @override
  Widget build(BuildContext context) {
    final childrenAsync = ref.watch(parentChildrenProvider);
    final selectedIndex = ref.watch(selectedChildIndexProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Attendance')),
      body: childrenAsync.when(
        data: (children) {
          if (children.isEmpty) {
            return const EmptyWidget(
              title: 'No Students Linked',
              subtitle: 'Contact the school to link your child.',
              icon: Icons.child_care_rounded,
            );
          }
          return Column(
            children: [
              // Child selector tabs
              if (children.length > 1)
                Container(
                  color: Theme.of(context).scaffoldBackgroundColor,
                  child: SizedBox(
                    height: 50,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      itemCount: children.length,
                      itemBuilder: (ctx, i) {
                        final c = children[i];
                        final isSelected = i == selectedIndex;
                        return GestureDetector(
                          onTap: () => ref
                              .read(selectedChildIndexProvider.notifier)
                              .state = i,
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            margin: const EdgeInsets.only(right: 8),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 6),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppColors.secondary
                                  : AppColors.surfaceVariant,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: isSelected
                                  ? [
                                      BoxShadow(
                                          color: AppColors.secondary
                                              .withValues(alpha: 0.3),
                                          blurRadius: 8,
                                          offset: const Offset(0, 2))
                                    ]
                                  : [],
                            ),
                            child: Text(
                              c.student?.firstName ?? 'Child ${i + 1}',
                              style: TextStyle(
                                color: isSelected
                                    ? Colors.white
                                    : AppColors.textSecondary,
                                fontWeight: isSelected
                                    ? FontWeight.w600
                                    : FontWeight.normal,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              Expanded(
                child: Builder(builder: (ctx) {
                  final child = children.length > selectedIndex
                      ? children[selectedIndex]
                      : children.first;
                  return _AttendanceCalendarView(
                    studentId: child.studentId,
                    studentName: child.student?.fullName ?? '',
                    focusedDay: _focusedDay,
                    selectedDay: _selectedDay,
                    onDaySelected: (selected, focused) {
                      setState(() {
                        _selectedDay = selected;
                        _focusedDay = focused;
                      });
                    },
                    onPageChanged: (day) {
                      setState(() => _focusedDay = day);
                    },
                  );
                }),
              ),
            ],
          );
        },
        loading: () => const LoadingWidget(),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }
}

class _AttendanceCalendarView extends ConsumerWidget {
  final String studentId;
  final String studentName;
  final DateTime focusedDay;
  final DateTime? selectedDay;
  final Function(DateTime, DateTime) onDaySelected;
  final Function(DateTime) onPageChanged;

  const _AttendanceCalendarView({
    required this.studentId,
    required this.studentName,
    required this.focusedDay,
    this.selectedDay,
    required this.onDaySelected,
    required this.onPageChanged,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final attendanceAsync = ref.watch(studentAttendanceProvider(studentId));
    final summaryAsync = ref.watch(studentAttendanceSummaryProvider(studentId));

    return attendanceAsync.when(
      data: (records) {
        // Build map for calendar
        final attendanceMap = <DateTime, AttendanceStatus>{};
        for (final r in records) {
          final day = DateTime(r.date.year, r.date.month, r.date.day);
          attendanceMap[day] = r.status;
        }

        return SingleChildScrollView(
          child: Column(
            children: [
              // Summary chips
              summaryAsync.when(
                data: (summary) {
                  final total = summary.values.fold(0, (a, b) => a + b);
                  final present = summary['present'] ?? 0;
                  final rate = total > 0
                      ? (present / total * 100).toStringAsFixed(1)
                      : '0';
                  return Container(
                    margin: const EdgeInsets.all(16),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF7C3AED), Color(0xFF9333EA)],
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      children: [
                        Text(
                          '$rate%',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 36,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const Text('Attendance Rate',
                            style: TextStyle(
                                color: Colors.white70, fontSize: 13)),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _SummaryChip('Present', summary['present'] ?? 0, AppColors.attendancePresent),
                            _SummaryChip('Absent', summary['absent'] ?? 0, AppColors.attendanceAbsent),
                            _SummaryChip('Late', summary['late'] ?? 0, AppColors.attendanceLate),
                            _SummaryChip('Excused', summary['excused'] ?? 0, AppColors.attendanceExcused),
                          ],
                        ),
                      ],
                    ),
                  );
                },
                loading: () => const SizedBox(height: 8),
                error: (_, __) => const SizedBox.shrink(),
              ),

              // Calendar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: TableCalendar(
                  firstDay: DateTime.utc(2024, 1, 1),
                  lastDay: DateTime.utc(2027, 12, 31),
                  focusedDay: focusedDay,
                  selectedDayPredicate: (d) =>
                      selectedDay != null && isSameDay(selectedDay, d),
                  onDaySelected: onDaySelected,
                  onPageChanged: onPageChanged,
                  calendarStyle: CalendarStyle(
                    defaultTextStyle: const TextStyle(fontSize: 13),
                    todayDecoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    todayTextStyle: const TextStyle(
                        color: AppColors.primary, fontWeight: FontWeight.w700),
                    selectedDecoration: const BoxDecoration(
                      color: AppColors.secondary,
                      shape: BoxShape.circle,
                    ),
                    markerDecoration: const BoxDecoration(),
                  ),
                  calendarBuilders: CalendarBuilders(
                    defaultBuilder: (context, day, focused) {
                      final key = DateTime(day.year, day.month, day.day);
                      final status = attendanceMap[key];
                      if (status == null) return null;
                      final color = switch (status) {
                        AttendanceStatus.present => AppColors.attendancePresent,
                        AttendanceStatus.absent => AppColors.attendanceAbsent,
                        AttendanceStatus.late => AppColors.attendanceLate,
                        AttendanceStatus.excused => AppColors.attendanceExcused,
                      };
                      return Container(
                        margin: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                          border: Border.all(color: color, width: 1.5),
                        ),
                        child: Center(
                          child: Text(
                            '${day.day}',
                            style: TextStyle(
                              color: color,
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                  headerStyle: const HeaderStyle(
                    formatButtonVisible: false,
                    titleCentered: true,
                    titleTextStyle: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),

              // Legend
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _LegendItem('Present', AppColors.attendancePresent),
                    _LegendItem('Absent', AppColors.attendanceAbsent),
                    _LegendItem('Late', AppColors.attendanceLate),
                    _LegendItem('Excused', AppColors.attendanceExcused),
                  ],
                ),
              ),
              const SizedBox(height: 80),
            ],
          ),
        );
      },
      loading: () => const LoadingWidget(),
      error: (e, _) => Center(child: Text('Error: $e')),
    );
  }
}

class _SummaryChip extends StatelessWidget {
  final String label;
  final int value;
  final Color color;
  const _SummaryChip(this.label, this.value, this.color);

  @override
  Widget build(BuildContext context) => Column(
        children: [
          Text('$value',
              style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 18)),
          Text(label,
              style: const TextStyle(color: Colors.white70, fontSize: 11)),
        ],
      );
}

class _LegendItem extends StatelessWidget {
  final String label;
  final Color color;
  const _LegendItem(this.label, this.color);

  @override
  Widget build(BuildContext context) => Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 4),
          Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
        ],
      );
}
