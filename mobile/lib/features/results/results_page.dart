import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../core/router/route_names.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/loading_widget.dart';
import '../../core/widgets/empty_widget.dart';
import '../../core/widgets/app_card.dart';
import '../../models/result_model.dart';
import '../students/students_provider.dart';
import '../dashboard/parent_dashboard_page.dart';
import 'results_provider.dart';
class ResultsPage extends ConsumerWidget {
  final bool isParent;
  const ResultsPage({super.key, this.isParent = false});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return isParent ? const _ParentResultsView() : const _TeacherResultsView();
  }
}

// ─── TEACHER RESULTS ─────────────────────────────────────────────────────────
class _TeacherResultsView extends ConsumerStatefulWidget {
  const _TeacherResultsView();

  @override
  ConsumerState<_TeacherResultsView> createState() =>
      _TeacherResultsViewState();
}

class _TeacherResultsViewState extends ConsumerState<_TeacherResultsView> {
  String? _selectedAssignmentId;

  @override
  Widget build(BuildContext context) {
    final assignmentsAsync = ref.watch(teacherAssignmentsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Results')),
      body: assignmentsAsync.when(
        data: (assignments) {
          if (assignments.isEmpty) {
            return const EmptyWidget(
              title: 'No Assignments',
              subtitle: 'You have no class-subject assignments.',
              icon: Icons.assignment_outlined,
            );
          }

          return Column(
            children: [
              // Subject/class filter tabs
              Container(
                color: Theme.of(context).scaffoldBackgroundColor,
                child: SizedBox(
                  height: 50,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 8),
                    itemCount: assignments.length,
                    itemBuilder: (ctx, i) {
                      final a = assignments[i];
                      final isSelected = _selectedAssignmentId == a.id ||
                          (_selectedAssignmentId == null && i == 0);
                      return GestureDetector(
                        onTap: () => setState(
                            () => _selectedAssignmentId = a.id),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          margin: const EdgeInsets.only(right: 8),
                          padding: const EdgeInsets.symmetric(horizontal: 14),
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
                          child: Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  a.subjectName,
                                  style: TextStyle(
                                    color: isSelected
                                        ? Colors.white
                                        : AppColors.textSecondary,
                                    fontWeight: isSelected
                                        ? FontWeight.w700
                                        : FontWeight.normal,
                                    fontSize: 12,
                                  ),
                                ),
                                Text(
                                  a.className,
                                  style: TextStyle(
                                    color: isSelected
                                        ? Colors.white70
                                        : AppColors.textHint,
                                    fontSize: 9,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),

              // Selected assignment content
              Expanded(
                child: Builder(builder: (_) {
                  final selected = _selectedAssignmentId != null
                      ? assignments.firstWhere(
                          (a) => a.id == _selectedAssignmentId,
                          orElse: () => assignments.first)
                      : assignments.first;
                  return _AssignmentResultsView(assignment: selected);
                }),
              ),
            ],
          );
        },
        loading: () => const ShimmerList(count: 4),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }
}

class _AssignmentResultsView extends ConsumerWidget {
  final dynamic assignment;
  const _AssignmentResultsView({required this.assignment});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final resultsAsync = ref.watch(assignmentResultsProvider(assignment.id));

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push(RouteNames.teacherResultAdd, extra: {
          'assignmentId': assignment.id,
          'className': assignment.className,
          'subjectName': assignment.subjectName,
        }),
        backgroundColor: AppColors.secondary,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: const Text('Add Result',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
      ),
      body: resultsAsync.when(
        data: (results) {
          if (results.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.bar_chart_rounded,
                      size: 48, color: AppColors.textHint),
                  const SizedBox(height: 12),
                  const Text('No results yet',
                      style: TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 15)),
                  const SizedBox(height: 4),
                  Text(
                      'Add results for ${assignment.subjectName} — ${assignment.className}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          color: AppColors.textSecondary, fontSize: 13)),
                ],
              ),
            );
          }

          // Group by student
          final byStudent = <String, List<Result>>{};
          for (final r in results) {
            byStudent
                .putIfAbsent(r.studentName, () => [])
                .add(r);
          }

          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
            itemCount: byStudent.length,
            itemBuilder: (ctx, i) {
              final entry = byStudent.entries.elementAt(i);
              final studentResults = entry.value;
              final avg = studentResults
                      .where((r) => r.percentage != null)
                      .isNotEmpty
                  ? studentResults
                          .where((r) => r.percentage != null)
                          .map((r) => r.percentage!)
                          .reduce((a, b) => a + b) /
                      studentResults
                          .where((r) => r.percentage != null)
                          .length
                  : null;

              final color = avg == null
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

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardTheme.color,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.border),
                ),
                child: ExpansionTile(
                  tilePadding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                  leading: CircleAvatar(
                    radius: 20,
                    backgroundColor: color.withValues(alpha: 0.15),
                    child: Text(
                      entry.key.isNotEmpty
                          ? entry.key.substring(0, 1).toUpperCase()
                          : '?',
                      style: TextStyle(
                          color: color,
                          fontWeight: FontWeight.w700,
                          fontSize: 16),
                    ),
                  ),
                  title: Text(entry.key,
                      style: const TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 14)),
                  subtitle: avg != null
                      ? Text('Avg: ${avg.toStringAsFixed(1)}%',
                          style: TextStyle(fontSize: 12, color: color))
                      : null,
                  trailing: avg != null
                      ? Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            '${avg.toStringAsFixed(0)}%',
                            style: TextStyle(
                                color: color,
                                fontWeight: FontWeight.w700,
                                fontSize: 13),
                          ),
                        )
                      : null,
                  children: studentResults.map((r) {
                    final pct = r.percentage;
                    final rc = pct == null
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
                    return ListTile(
                      dense: true,
                      contentPadding:
                          const EdgeInsets.symmetric(horizontal: 16),
                      leading: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: rc.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(r.examType.label,
                            style: TextStyle(
                                fontSize: 11,
                                color: rc,
                                fontWeight: FontWeight.w600)),
                      ),
                      title: Text(r.displayScore,
                          style: TextStyle(
                              fontWeight: FontWeight.w700,
                              color: rc,
                              fontSize: 14)),
                      trailing: r.grade != null
                          ? Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: rc.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(r.grade!,
                                  style: TextStyle(
                                      color: rc,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 13)),
                            )
                          : null,
                    );
                  }).toList(),
                ),
              );
            },
          );
        },
        loading: () => const ShimmerList(count: 4),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }
}

// ─── PARENT RESULTS ──────────────────────────────────────────────────────────
class _ParentResultsView extends ConsumerWidget {
  const _ParentResultsView();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final childrenAsync = ref.watch(parentChildrenProvider);
    final selectedIndex = ref.watch(selectedChildIndexProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Academic Results')),
      body: childrenAsync.when(
        data: (children) {
          if (children.isEmpty) {
            return const EmptyWidget(
              title: 'No Students Linked',
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
                child: Builder(builder: (_) {
                  final child = children.length > selectedIndex
                      ? children[selectedIndex]
                      : children.first;
                  return _StudentResultsView(studentId: child.studentId);
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

class _StudentResultsView extends ConsumerWidget {
  final String studentId;
  const _StudentResultsView({required this.studentId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final resultsAsync = ref.watch(studentResultsProvider(studentId));

    return resultsAsync.when(
      data: (results) {
        if (results.isEmpty) {
          return const EmptyWidget(
            title: 'No Results Yet',
            subtitle: 'Results will appear here when uploaded by teachers.',
            icon: Icons.bar_chart_rounded,
          );
        }

        // Group by subject
        final bySubject = <String, List<Result>>{};
        for (final r in results) {
          bySubject.putIfAbsent(r.subjectName, () => []).add(r);
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Bar chart of subject averages
              if (bySubject.length > 1) _SubjectAveragesChart(bySubject: bySubject),
              const SizedBox(height: 20),
              // Results by subject
              ...bySubject.entries.map((e) => _SubjectSection(
                    subjectName: e.key,
                    results: e.value,
                  )),
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

class _SubjectAveragesChart extends StatelessWidget {
  final Map<String, List<Result>> bySubject;
  const _SubjectAveragesChart({required this.bySubject});

  @override
  Widget build(BuildContext context) {
    final subjects = bySubject.keys.toList();
    final averages = subjects.map((s) {
      final results = bySubject[s]!.where((r) => r.percentage != null).toList();
      if (results.isEmpty) return 0.0;
      return results.map((r) => r.percentage!).reduce((a, b) => a + b) / results.length;
    }).toList();

    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Subject Averages',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
          const SizedBox(height: 16),
          SizedBox(
            height: 200,
            child: BarChart(
              BarChartData(
                borderData: FlBorderData(show: false),
                gridData: const FlGridData(drawVerticalLine: false),
                titlesData: FlTitlesData(
                  leftTitles: const AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 36,
                    ),
                  ),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (val, meta) {
                        final i = val.toInt();
                        if (i < 0 || i >= subjects.length) return const SizedBox.shrink();
                        final name = subjects[i];
                        return Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            name.length > 6 ? name.substring(0, 6) : name,
                            style: const TextStyle(fontSize: 10),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                barGroups: List.generate(subjects.length, (i) {
                  final avg = averages[i];
                  final color = avg >= 90 ? AppColors.gradeA
                      : avg >= 80 ? AppColors.gradeB
                      : avg >= 70 ? AppColors.gradeC
                      : avg >= 60 ? AppColors.gradeD
                      : AppColors.gradeF;
                  return BarChartGroupData(
                    x: i,
                    barRods: [
                      BarChartRodData(
                        toY: avg,
                        color: color,
                        width: 24,
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                      ),
                    ],
                  );
                }),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SubjectSection extends StatelessWidget {
  final String subjectName;
  final List<Result> results;
  const _SubjectSection({required this.subjectName, required this.results});

  @override
  Widget build(BuildContext context) {
    final avg = results.where((r) => r.percentage != null).isNotEmpty
        ? results.where((r) => r.percentage != null).map((r) => r.percentage!).reduce((a, b) => a + b) /
            results.where((r) => r.percentage != null).length
        : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.secondaryLight,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                subjectName,
                style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    color: AppColors.secondary),
              ),
            ),
            if (avg != null) ...[
              const SizedBox(width: 8),
              Text(
                'Avg: ${avg.toStringAsFixed(1)}%',
                style: const TextStyle(
                    color: AppColors.textSecondary, fontSize: 12),
              ),
            ],
          ],
        ),
        const SizedBox(height: 8),
        ...results.map((r) => _ResultTile(result: r)),
        const SizedBox(height: 16),
      ],
    );
  }
}

class _ResultTile extends StatelessWidget {
  final Result result;
  const _ResultTile({required this.result});

  @override
  Widget build(BuildContext context) {
    final pct = result.percentage;
    final (color, bg) = pct == null
        ? (AppColors.textSecondary, AppColors.surfaceVariant)
        : pct >= 90
            ? (AppColors.gradeA, AppColors.successLight)
            : pct >= 80
                ? (AppColors.gradeB, AppColors.infoLight)
                : pct >= 70
                    ? (AppColors.gradeC, AppColors.warningLight)
                    : pct >= 60
                        ? (AppColors.gradeD, AppColors.warningLight)
                        : (AppColors.gradeF, AppColors.errorLight);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  result.examType.label,
                  style: const TextStyle(
                      fontWeight: FontWeight.w600, fontSize: 13),
                ),
                Text(
                  DateFormat('MMM d, yyyy').format(result.examDate),
                  style: const TextStyle(
                      color: AppColors.textSecondary, fontSize: 12),
                ),
                if (result.remarks != null)
                  Text(result.remarks!,
                      style: const TextStyle(
                          color: AppColors.textSecondary, fontSize: 11)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                result.displayScore,
                style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                    color: color),
              ),
              if (pct != null)
                Text(
                  '${pct.toStringAsFixed(1)}%',
                  style: TextStyle(
                      fontSize: 12, color: color, fontWeight: FontWeight.w500),
                ),
              if (result.grade != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    result.grade!,
                    style: TextStyle(
                        fontSize: 12, fontWeight: FontWeight.w700, color: color),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
