import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../core/router/route_names.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/loading_widget.dart';
import '../../models/attendance_model.dart';
import '../../models/result_model.dart';
import '../attendance/attendance_provider.dart';
import '../results/results_provider.dart';
import '../students/students_provider.dart';

class StudentDetailPage extends ConsumerStatefulWidget {
  final String studentId;
  final String studentName;

  const StudentDetailPage({
    super.key,
    required this.studentId,
    required this.studentName,
  });

  @override
  ConsumerState<StudentDetailPage> createState() => _StudentDetailPageState();
}

class _StudentDetailPageState extends ConsumerState<StudentDetailPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final attendanceSummaryAsync =
        ref.watch(studentAttendanceSummaryProvider(widget.studentId));

    return Scaffold(
      body: NestedScrollView(
        headerSliverBuilder: (context, _) => [
          SliverAppBar(
            expandedHeight: 220,
            pinned: true,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
              onPressed: () => context.canPop() ? context.pop() : context.go(RouteNames.teacherStudents),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF1D4ED8), Color(0xFF7C3AED)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 60, 20, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 60,
                              height: 60,
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.2),
                                shape: BoxShape.circle,
                                border: Border.all(
                                    color: Colors.white.withValues(alpha: 0.4),
                                    width: 2),
                              ),
                              child: Center(
                                child: Text(
                                  widget.studentName
                                      .substring(0, 1)
                                      .toUpperCase(),
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w800,
                                      fontSize: 24),
                                ),
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    widget.studentName,
                                    style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w800,
                                        fontSize: 18),
                                  ),
                                  Text(
                                    'ID: ${widget.studentId}',
                                    style: const TextStyle(
                                        color: Colors.white70, fontSize: 13),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        // Quick stats
                        attendanceSummaryAsync.when(
                          data: (summary) {
                            final total =
                                summary.values.fold(0, (a, b) => a + b);
                            final present = summary['present'] ?? 0;
                            final rate = total > 0
                                ? (present / total * 100).toStringAsFixed(0)
                                : '0';
                            return Row(
                              children: [
                                _HeaderStat('$rate%', 'Attendance'),
                                _HeaderStat('${summary['present'] ?? 0}',
                                    'Present'),
                                _HeaderStat(
                                    '${summary['absent'] ?? 0}', 'Absent'),
                                _HeaderStat(
                                    '${summary['late'] ?? 0}', 'Late'),
                              ],
                            );
                          },
                          loading: () => const SizedBox.shrink(),
                          error: (_, __) => const SizedBox.shrink(),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            bottom: TabBar(
              controller: _tabController,
              indicatorColor: Colors.white,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white60,
              labelStyle: const TextStyle(fontWeight: FontWeight.w600),
              tabs: const [
                Tab(text: 'Attendance'),
                Tab(text: 'Results'),
              ],
            ),
          ),
        ],
        body: TabBarView(
          controller: _tabController,
          children: [
            _AttendanceTab(studentId: widget.studentId),
            _ResultsTab(studentId: widget.studentId),
          ],
        ),
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton.small(
            heroTag: 'result',
            backgroundColor: AppColors.secondary,
            tooltip: 'Add Result',
            onPressed: () {
              final assignmentsAsync = ref.read(teacherAssignmentsProvider);
              assignmentsAsync.whenData((assignments) {
                if (assignments.isNotEmpty) {
                  _showAssignmentPicker(context, assignments, 'result');
                }
              });
            },
            child: const Icon(Icons.grade_outlined, color: Colors.white),
          ),
          const SizedBox(height: 8),
          FloatingActionButton(
            heroTag: 'attendance',
            backgroundColor: AppColors.primary,
            tooltip: 'Mark Attendance',
            onPressed: () {
              final assignmentsAsync = ref.read(teacherAssignmentsProvider);
              assignmentsAsync.whenData((assignments) {
                if (assignments.isNotEmpty) {
                  _showAssignmentPicker(context, assignments, 'attendance');
                }
              });
            },
            child: const Icon(Icons.fact_check_outlined, color: Colors.white),
          ),
        ],
      ),
    );
  }

  void _showAssignmentPicker(
      BuildContext context, List<dynamic> assignments, String action) {
    final seen = <String>{};
    final uniqueClasses =
        assignments.where((a) => seen.add(a.classId)).toList();

    if (uniqueClasses.length == 1) {
      _navigate(context, uniqueClasses.first, action);
      return;
    }

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => _ClassPickerSheet(
        classes: uniqueClasses,
        action: action,
        onSelect: (a) {
          Navigator.pop(context);
          _navigate(context, a, action);
        },
      ),
    );
  }

  void _navigate(BuildContext context, dynamic assignment, String action) {
    if (action == 'attendance') {
      context.push(RouteNames.teacherAttendanceMark, extra: {
        'classId': assignment.classId,
        'className': assignment.className,
        'assignmentId': assignment.id,
      });
    } else {
      context.push(RouteNames.teacherResultAdd, extra: {
        'assignmentId': assignment.id,
        'className': assignment.className,
        'subjectName': assignment.subjectName,
        'preselectedStudentId': widget.studentId,
      });
    }
  }
}

class _ClassPickerSheet extends StatelessWidget {
  final List<dynamic> classes;
  final String action;
  final void Function(dynamic) onSelect;
  const _ClassPickerSheet(
      {required this.classes, required this.action, required this.onSelect});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              action == 'attendance' ? 'Select Class for Attendance' : 'Select Class-Subject',
              style:
                  const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
            ),
            const SizedBox(height: 16),
            ...classes.map((a) => ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.class_, color: AppColors.primary, size: 18),
                  ),
                  title: Text(a.className,
                      style: const TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: action == 'result'
                      ? Text(a.subjectName,
                          style: const TextStyle(fontSize: 12))
                      : null,
                  trailing: const Icon(Icons.arrow_forward_ios_rounded,
                      size: 14),
                  onTap: () => onSelect(a),
                )),
            const SizedBox(height: 8),
          ],
        ),
      );
}

class _HeaderStat extends StatelessWidget {
  final String value;
  final String label;
  const _HeaderStat(this.value, this.label);

  @override
  Widget build(BuildContext context) => Expanded(
        child: Column(
          children: [
            Text(value,
                style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 18)),
            Text(label,
                style: const TextStyle(color: Colors.white70, fontSize: 10)),
          ],
        ),
      );
}

class _AttendanceTab extends ConsumerWidget {
  final String studentId;
  const _AttendanceTab({required this.studentId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recentAttendanceAsync = ref.watch(studentAttendanceProvider(studentId));

    return recentAttendanceAsync.when(
      data: (records) {
        if (records.isEmpty) {
          return const Center(
            child: Text('No attendance records',
                style: TextStyle(color: AppColors.textSecondary)),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
          itemCount: records.length,
          itemBuilder: (ctx, i) {
            final a = records[i];
            final color = switch (a.status.value) {
              'present' => AppColors.attendancePresent,
              'absent' => AppColors.attendanceAbsent,
              'late' => AppColors.attendanceLate,
              _ => AppColors.attendanceExcused,
            };
            final bg = switch (a.status.value) {
              'present' => AppColors.attendancePresentLight,
              'absent' => AppColors.attendanceAbsentLight,
              'late' => AppColors.attendanceLateLight,
              _ => AppColors.attendanceExcusedLight,
            };
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: bg,
                borderRadius: BorderRadius.circular(12),
                border:
                    Border.all(color: color.withValues(alpha: 0.25)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      switch (a.status.value) {
                        'present' => Icons.check_circle_outline_rounded,
                        'absent' => Icons.cancel_outlined,
                        'late' => Icons.access_time_rounded,
                        _ => Icons.info_outline_rounded,
                      },
                      color: color,
                      size: 14,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          DateFormat('EEEE, MMMM d, yyyy').format(a.date),
                          style: const TextStyle(
                              fontWeight: FontWeight.w500, fontSize: 13),
                        ),
                        if (a.notes != null)
                          Text(a.notes!,
                              style: const TextStyle(
                                  fontSize: 11,
                                  color: AppColors.textSecondary)),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      a.status.label,
                      style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                          color: color),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
      loading: () => const ShimmerList(count: 5, itemHeight: 56),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}

class _ResultsTab extends ConsumerWidget {
  final String studentId;
  const _ResultsTab({required this.studentId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final resultsAsync = ref.watch(studentResultsProvider(studentId));

    return resultsAsync.when(
      data: (results) {
        if (results.isEmpty) {
          return const Center(
            child: Text('No results yet',
                style: TextStyle(color: AppColors.textSecondary)),
          );
        }

        final bySubject = <String, List<Result>>{};
        for (final r in results) {
          bySubject.putIfAbsent(r.subjectName, () => []).add(r);
        }

        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
          children: bySubject.entries.map((e) {
            final avg = e.value
                    .where((r) => r.percentage != null)
                    .isNotEmpty
                ? e.value
                        .where((r) => r.percentage != null)
                        .map((r) => r.percentage!)
                        .reduce((a, b) => a + b) /
                    e.value.where((r) => r.percentage != null).length
                : null;

            final subjectColor = avg == null
                ? AppColors.textSecondary
                : avg >= 90
                    ? AppColors.gradeA
                    : avg >= 80
                        ? AppColors.gradeB
                        : avg >= 70
                            ? AppColors.gradeC
                            : avg >= 60
                                ? AppColors.gradeD
                                : AppColors.gradeF;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: subjectColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                        color: subjectColor.withValues(alpha: 0.2)),
                  ),
                  child: Row(
                    children: [
                      Text(e.key,
                          style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                              color: subjectColor)),
                      const Spacer(),
                      if (avg != null)
                        Text('Avg: ${avg.toStringAsFixed(1)}%',
                            style: TextStyle(
                                fontSize: 12,
                                color: subjectColor,
                                fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
                ...e.value.map((r) {
                  final pct = r.percentage;
                  final color = pct == null
                      ? AppColors.textSecondary
                      : pct >= 90
                          ? AppColors.gradeA
                          : pct >= 80
                              ? AppColors.gradeB
                              : pct >= 70
                                  ? AppColors.gradeC
                                  : pct >= 60
                                      ? AppColors.gradeD
                                      : AppColors.gradeF;

                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardTheme.color,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(r.examType.label,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13)),
                              Text(
                                  DateFormat('MMM d, yyyy')
                                      .format(r.examDate),
                                  style: const TextStyle(
                                      color: AppColors.textSecondary,
                                      fontSize: 11)),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(r.displayScore,
                                style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 15,
                                    color: color)),
                            if (r.grade != null)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: color.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(r.grade!,
                                    style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                        color: color)),
                              ),
                          ],
                        ),
                      ],
                    ),
                  );
                }),
                const SizedBox(height: 8),
              ],
            );
          }).toList(),
        );
      },
      loading: () => const ShimmerList(count: 3, itemHeight: 70),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}
