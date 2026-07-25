import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../core/router/route_names.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/loading_widget.dart';
import '../../models/attendance_model.dart';
import '../../models/activity_model.dart';
import '../../models/result_model.dart';
import '../activities/activities_provider.dart';
import '../activities/activity_form_page.dart';
import '../attendance/attendance_provider.dart';
import '../results/results_provider.dart';
import '../students/students_provider.dart';

// Weights for total score calculation (must sum to 100)
const _examWeights = {
  ExamType.midterm:    25.0,
  ExamType.final_:     35.0,
  ExamType.quiz:       15.0,
  ExamType.assignment: 15.0,
  ExamType.project:    10.0,
};

class StudentDetailPage extends ConsumerStatefulWidget {
  final String studentId;
  final String studentName;
  final String? studentNumber;

  const StudentDetailPage({
    super.key,
    required this.studentId,
    required this.studentName,
    this.studentNumber,
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
    _tabController = TabController(length: 4, vsync: this);
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
                                  if (widget.studentNumber != null)
                                    Text(
                                      'Student ID: ${widget.studentNumber}',
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
              labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
              isScrollable: true,
              tabAlignment: TabAlignment.start,
              tabs: const [
                Tab(text: 'Attendance'),
                Tab(text: 'Marks'),
                Tab(text: 'Log'),
                Tab(text: 'Results'),
              ],
            ),
          ),
        ],
        body: TabBarView(
          controller: _tabController,
          children: [
            _AttendanceTab(studentId: widget.studentId),
            _MarksTab(studentId: widget.studentId),
            _StudentLogTab(
              studentId: widget.studentId,
              studentName: widget.studentName,
              studentNumber: widget.studentNumber,
            ),
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

class _MarksTab extends ConsumerWidget {
  final String studentId;
  const _MarksTab({required this.studentId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final resultsAsync = ref.watch(studentResultsProvider(studentId));

    return resultsAsync.when(
      data: (results) {
        if (results.isEmpty) {
          return const Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.bar_chart_rounded, size: 48, color: AppColors.textHint),
                SizedBox(height: 12),
                Text('No marks yet', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                SizedBox(height: 4),
                Text('Results will appear here once entered by the teacher.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
              ],
            ),
          );
        }

        // Group by subject name
        final bySubject = <String, List<Result>>{};
        for (final r in results) {
          final key = r.subjectName.isNotEmpty ? r.subjectName : 'General';
          bySubject.putIfAbsent(key, () => []).add(r);
        }

        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
          children: [
            // Legend row
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primaryLight,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline_rounded, size: 14, color: AppColors.primary),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Total = Mid(25%) + Final(35%) + Quiz(15%) + Assign(15%) + Project(10%). '
                      '"~" means some assessments are still pending.',
                      style: TextStyle(fontSize: 11, color: AppColors.primary),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            ...bySubject.entries.map((e) => _SubjectMarksCard(
                  subjectName: e.key,
                  results: e.value,
                )),
          ],
        );
      },
      loading: () => const ShimmerList(count: 3, itemHeight: 180),
      error: (_, __) => const Center(child: Text('Could not load marks')),
    );
  }
}

class _SubjectMarksCard extends StatelessWidget {
  final String subjectName;
  final List<Result> results;
  const _SubjectMarksCard({required this.subjectName, required this.results});

  // Average score for an exam type as a percentage (0-100)
  double? _avgPct(ExamType type) {
    final filtered = results.where((r) => r.examType == type && r.percentage != null).toList();
    if (filtered.isEmpty) return null;
    return filtered.map((r) => r.percentage!).reduce((a, b) => a + b) / filtered.length;
  }

  // Weighted running total out of 100.
  // Returns a value even if some exam types are missing (based on weight covered).
  // Returns null only if NO exams have been entered at all.
  double? _total() {
    double total = 0;
    double weightCovered = 0;
    for (final entry in _examWeights.entries) {
      final pct = _avgPct(entry.key);
      if (pct != null) {
        total += (pct / 100) * entry.value;
        weightCovered += entry.value;
      }
    }
    if (weightCovered == 0) return null;
    // Scale to 100 based on weight covered so far
    return (total / weightCovered) * 100;
  }

  // True only when all exam types have at least one entry
  bool get _isComplete =>
      _examWeights.keys.every((t) => _avgPct(t) != null);

  Color _gradeColor(double pct) {
    if (pct >= 90) return AppColors.gradeA;
    if (pct >= 80) return AppColors.gradeB;
    if (pct >= 70) return AppColors.gradeC;
    if (pct >= 60) return AppColors.gradeD;
    return AppColors.gradeF;
  }

  String _gradeLabel(double pct) {
    if (pct >= 95) return 'A+';
    if (pct >= 90) return 'A';
    if (pct >= 85) return 'A-';
    if (pct >= 80) return 'B+';
    if (pct >= 75) return 'B';
    if (pct >= 70) return 'B-';
    if (pct >= 65) return 'C+';
    if (pct >= 60) return 'C';
    if (pct >= 50) return 'D';
    return 'F';
  }

  @override
  Widget build(BuildContext context) {
    final total = _total();
    final isComplete = _isComplete;
    final totalColor = total != null ? _gradeColor(total) : AppColors.textSecondary;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Subject header + total
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: const BoxDecoration(
              color: AppColors.secondaryLight,
              borderRadius: BorderRadius.vertical(top: Radius.circular(14)),
            ),
            child: Row(
              children: [
                const Icon(Icons.book_outlined, size: 16, color: AppColors.secondary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(subjectName,
                      style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                          color: AppColors.secondary)),
                ),
                // Total score badge
                if (total != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: totalColor,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '${total.toStringAsFixed(1)}/100',
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              fontSize: 13),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          isComplete ? _gradeLabel(total) : '~',
                          style: const TextStyle(
                              color: Colors.white70,
                              fontWeight: FontWeight.w600,
                              fontSize: 11),
                        ),
                      ],
                    ),
                  )
                else
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceVariant,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      'No results yet',
                      style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 11,
                          fontWeight: FontWeight.w600),
                    ),
                  ),
              ],
            ),
          ),

          // Marks rows for each exam type
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: ExamType.values.map((type) {
                final pct = _avgPct(type);
                final weight = _examWeights[type]!;
                final color = pct != null ? _gradeColor(pct) : AppColors.textHint;
                final typeResults = results.where((r) => r.examType == type).toList();

                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: pct != null
                        ? color.withValues(alpha: 0.06)
                        : AppColors.surfaceVariant.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                        color: pct != null
                            ? color.withValues(alpha: 0.2)
                            : AppColors.border.withValues(alpha: 0.5)),
                  ),
                  child: Row(
                    children: [
                      // Exam type label + weight
                      SizedBox(
                        width: 90,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(type.label,
                                style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13,
                                    color: pct != null ? color : AppColors.textSecondary)),
                            Text('${weight.toInt()}% weight',
                                style: const TextStyle(
                                    fontSize: 10, color: AppColors.textHint)),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Score entries
                      Expanded(
                        child: pct != null
                            ? Wrap(
                                spacing: 6,
                                runSpacing: 4,
                                children: typeResults.map((r) {
                                  final rColor = r.percentage != null
                                      ? _gradeColor(r.percentage!)
                                      : AppColors.textSecondary;
                                  return Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: rColor.withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      r.marksObtained != null && r.totalMarks != null
                                          ? '${r.marksObtained!.toStringAsFixed(0)}/${r.totalMarks!.toStringAsFixed(0)}'
                                          : r.grade ?? '—',
                                      style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w700,
                                          color: rColor),
                                    ),
                                  );
                                }).toList(),
                              )
                            : const Text('Not entered yet',
                                style: TextStyle(
                                    fontSize: 12, color: AppColors.textHint,
                                    fontStyle: FontStyle.italic)),
                      ),
                      // Average % for this type
                      if (pct != null)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '${pct.toStringAsFixed(1)}%',
                            style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: color),
                          ),
                        ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
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

// ─── STUDENT LOG TAB ────────────────────────────────────────────────────────
// Shows behavior/participation logs for this specific student.
// Teacher can add a new log; it auto-notifies the parent.

class _StudentLogTab extends ConsumerStatefulWidget {
  final String studentId;
  final String studentName;
  final String? studentNumber;
  const _StudentLogTab({
    required this.studentId,
    required this.studentName,
    this.studentNumber,
  });

  @override
  ConsumerState<_StudentLogTab> createState() => _StudentLogTabState();
}

class _StudentLogTabState extends ConsumerState<_StudentLogTab> {
  @override
  Widget build(BuildContext context) {
    final logsAsync = ref.watch(studentLogsProvider(widget.studentId));
    final assignmentsAsync = ref.watch(teacherAssignmentsProvider);

    return Scaffold(
      floatingActionButton: assignmentsAsync.when(
        data: (assignments) {
          final assignment = assignments.isNotEmpty ? assignments.first : null;
          if (assignment == null) return const SizedBox.shrink();
          return FloatingActionButton.extended(
            heroTag: 'add_log',
            backgroundColor: AppColors.warning,
            onPressed: () async {
              final result = await Navigator.push<bool>(
                context,
                MaterialPageRoute(
                  builder: (_) => ActivityFormPage(
                    classId: assignment.classId,
                    className: assignment.className,
                    academicYearId: assignment.academicYearId,
                    studentId: widget.studentId,
                    studentName: widget.studentName,
                  ),
                ),
              );
              if (result == true) {
                ref.invalidate(studentLogsProvider(widget.studentId));
              }
            },
            icon: const Icon(Icons.add_rounded, color: Colors.white),
            label: const Text('Add Log',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
          );
        },
        loading: () => const SizedBox.shrink(),
        error: (_, __) => const SizedBox.shrink(),
      ),
      body: logsAsync.when(
        data: (logs) {
          if (logs.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: const BoxDecoration(
                      color: AppColors.warningLight,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.psychology_rounded,
                        size: 40, color: AppColors.warning),
                  ),
                  const SizedBox(height: 16),
                  const Text('No logs yet',
                      style: TextStyle(
                          fontWeight: FontWeight.w700, fontSize: 16)),
                  const SizedBox(height: 6),
                  Text(
                    'Tap "Add Log" to record a behavior,\nparticipation, or note for ${widget.studentName.split(' ').first}.',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        color: AppColors.textSecondary, fontSize: 13),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
            itemCount: logs.length,
            itemBuilder: (ctx, i) => _LogCard(log: logs[i]),
          );
        },
        loading: () => const ShimmerList(count: 4, itemHeight: 90),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }
}

class _LogCard extends StatelessWidget {
  final Activity log;
  const _LogCard({required this.log});

  (Color, IconData) _typeStyle(String type) {
    return switch (type.toLowerCase()) {
      'behavior' => (AppColors.warning, Icons.psychology_rounded),
      'participation' => (AppColors.success, Icons.record_voice_over_rounded),
      'achievement' => (AppColors.gradeA, Icons.emoji_events_rounded),
      'concern' => (AppColors.error, Icons.warning_amber_rounded),
      'counseling' => (AppColors.info, Icons.support_agent_rounded),
      'discipline' => (AppColors.error, Icons.gavel_rounded),
      'health' => (AppColors.secondary, Icons.health_and_safety_outlined),
      _ => (AppColors.primary, Icons.event_note_rounded),
    };
  }

  String _prettyType(String t) => t
      .replaceAll('_', ' ')
      .split(' ')
      .map((w) =>
          w.isNotEmpty ? '${w[0].toUpperCase()}${w.substring(1)}' : '')
      .join(' ');

  @override
  Widget build(BuildContext context) {
    final (color, icon) = _typeStyle(log.activityType);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.25)),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        _prettyType(log.activityType),
                        style: TextStyle(
                            fontSize: 10,
                            color: color,
                            fontWeight: FontWeight.w700),
                      ),
                    ),
                    const Spacer(),
                    Text(
                      DateFormat('MMM d, yyyy').format(log.activityDate),
                      style: const TextStyle(
                          color: AppColors.textSecondary, fontSize: 11),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  log.title,
                  style: const TextStyle(
                      fontWeight: FontWeight.w700, fontSize: 14),
                ),
                if (log.description != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    log.description!,
                    style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                        height: 1.4),
                  ),
                ],
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.person_outline_rounded,
                        size: 12, color: AppColors.textHint),
                    const SizedBox(width: 4),
                    Text(
                      'Logged by ${log.organizerName}',
                      style: const TextStyle(
                          fontSize: 11, color: AppColors.textHint),
                    ),
                    const SizedBox(width: 8),
                    const Icon(Icons.send_rounded,
                        size: 11, color: AppColors.textHint),
                    const SizedBox(width: 3),
                    const Text(
                      'Parent notified',
                      style: TextStyle(
                          fontSize: 11, color: AppColors.textHint),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
