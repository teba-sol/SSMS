import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/router/route_names.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/loading_widget.dart';
import '../../core/widgets/empty_widget.dart';
import '../../models/student_model.dart';
import 'students_provider.dart';

class StudentsPage extends ConsumerStatefulWidget {
  const StudentsPage({super.key});

  @override
  ConsumerState<StudentsPage> createState() => _StudentsPageState();
}

class _StudentsPageState extends ConsumerState<StudentsPage> {
  String _search = '';
  String? _selectedClassId;
  String? _selectedClassName;

  @override
  Widget build(BuildContext context) {
    final assignmentsAsync = ref.watch(teacherAssignmentsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('My Students'),
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: TextField(
              onChanged: (v) => setState(() => _search = v),
              decoration: InputDecoration(
                hintText: 'Search students...',
                prefixIcon: const Icon(Icons.search_rounded, size: 20),
                suffixIcon: _search.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded, size: 18),
                        onPressed: () => setState(() => _search = ''),
                      )
                    : null,
                isDense: true,
                fillColor: AppColors.surfaceVariant,
                filled: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
        ),
      ),
      body: assignmentsAsync.when(
        data: (assignments) {
          if (assignments.isEmpty) {
            return const EmptyWidget(
              title: 'No Classes',
              subtitle: 'You have no assigned classes.',
              icon: Icons.people_outline_rounded,
            );
          }
          final seen = <String>{};
          final uniqueClasses =
              assignments.where((a) => seen.add(a.classId)).toList();

          return Column(
            children: [
              // Class filter tabs
              if (uniqueClasses.isNotEmpty)
                Container(
                  color: Theme.of(context).scaffoldBackgroundColor,
                  child: SizedBox(
                    height: 50,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      children: [
                        _ClassTab(
                          label: 'All',
                          count: null,
                          isSelected: _selectedClassId == null,
                          color: AppColors.primary,
                          onTap: () => setState(() {
                            _selectedClassId = null;
                            _selectedClassName = null;
                          }),
                        ),
                        ...uniqueClasses.map((a) => _ClassTab(
                              label: a.className,
                              count: null,
                              isSelected: _selectedClassId == a.classId,
                              color: AppColors.secondary,
                              onTap: () => setState(() {
                                _selectedClassId = a.classId;
                                _selectedClassName = a.className;
                              }),
                            )),
                      ],
                    ),
                  ),
                ),

              // Students list
              Expanded(
                child: _selectedClassId != null
                    ? _StudentsForClass(
                        classId: _selectedClassId!,
                        className: _selectedClassName ?? '',
                        search: _search,
                        assignments: uniqueClasses,
                      )
                    : _AllStudents(
                        classes: uniqueClasses,
                        search: _search,
                      ),
              ),
            ],
          );
        },
        loading: () => const ShimmerList(count: 5),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }
}

class _ClassTab extends StatelessWidget {
  final String label;
  final int? count;
  final bool isSelected;
  final Color color;
  final VoidCallback onTap;
  const _ClassTab(
      {required this.label,
      this.count,
      required this.isSelected,
      required this.color,
      required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.only(right: 8),
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: isSelected ? color : AppColors.surfaceVariant,
            borderRadius: BorderRadius.circular(20),
            boxShadow: isSelected
                ? [BoxShadow(color: color.withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(0, 2))]
                : [],
          ),
          child: Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: isSelected ? Colors.white : AppColors.textSecondary,
                    fontWeight:
                        isSelected ? FontWeight.w600 : FontWeight.normal,
                    fontSize: 13,
                  ),
                ),
                if (count != null) ...[
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? Colors.white.withValues(alpha: 0.3)
                          : AppColors.border,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '$count',
                      style: TextStyle(
                        fontSize: 10,
                        color: isSelected ? Colors.white : AppColors.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      );
}

class _StudentsForClass extends ConsumerWidget {
  final String classId;
  final String className;
  final String search;
  final List<dynamic> assignments;
  const _StudentsForClass(
      {required this.classId,
      required this.className,
      required this.search,
      required this.assignments});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final studentsAsync = ref.watch(classStudentsListProvider(classId));
    return studentsAsync.when(
      data: (students) => _StudentList(
          students: students, search: search, assignments: assignments),
      loading: () => const ShimmerList(count: 5),
      error: (e, _) => Center(child: Text('Error: $e')),
    );
  }
}

class _AllStudents extends ConsumerWidget {
  final List<dynamic> classes;
  final String search;
  const _AllStudents({required this.classes, required this.search});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (classes.isEmpty) {
      return const EmptyWidget(
          title: 'No Students', icon: Icons.people_outline_rounded);
    }

    // Watch all classes and merge
    final allStudentsAsync = classes.map((c) {
      return ref.watch(classStudentsListProvider(c.classId as String));
    }).toList();

    final isLoading = allStudentsAsync.any((a) => a.isLoading);
    if (isLoading) return const ShimmerList(count: 5);

    final allStudents = <Student>[];
    final seen = <String>{};
    for (final async in allStudentsAsync) {
      async.whenData((students) {
        for (final s in students) {
          if (seen.add(s.id)) allStudents.add(s);
        }
      });
    }

    return _StudentList(
        students: allStudents, search: search, assignments: classes);
  }
}

class _StudentList extends StatelessWidget {
  final List<Student> students;
  final String search;
  final List<dynamic> assignments;
  const _StudentList(
      {required this.students,
      required this.search,
      required this.assignments});

  @override
  Widget build(BuildContext context) {
    final filtered = search.isEmpty
        ? students
        : students
            .where((s) =>
                s.fullName.toLowerCase().contains(search.toLowerCase()) ||
                s.studentId.toLowerCase().contains(search.toLowerCase()))
            .toList();

    if (filtered.isEmpty) {
      return EmptyWidget(
        title: search.isEmpty ? 'No Students' : 'No results for "$search"',
        icon: Icons.person_search_outlined,
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
      itemCount: filtered.length,
      itemBuilder: (ctx, i) =>
          _StudentCard(student: filtered[i], assignments: assignments),
    );
  }
}

class _StudentCard extends StatelessWidget {
  final Student student;
  final List<dynamic> assignments;
  const _StudentCard(
      {required this.student, required this.assignments});

  @override
  Widget build(BuildContext context) {
    final colors = [
      AppColors.primary,
      AppColors.secondary,
      AppColors.success,
      AppColors.warning,
      AppColors.info,
    ];
    final color =
        colors[student.firstName.codeUnitAt(0) % colors.length];

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Main info row
          InkWell(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            onTap: () => context.push(RouteNames.teacherStudentDetail, extra: {
              'studentId': student.id,
              'studentName': student.fullName,
            }),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: color.withValues(alpha: 0.15),
                    child: Text(
                      student.firstName.substring(0, 1).toUpperCase(),
                      style: TextStyle(
                          color: color,
                          fontWeight: FontWeight.w800,
                          fontSize: 18),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(student.fullName,
                            style: const TextStyle(
                                fontWeight: FontWeight.w700, fontSize: 15)),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 7, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.surfaceVariant,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text('ID: ${student.studentId}',
                                  style: const TextStyle(
                                      color: AppColors.textSecondary,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w500)),
                            ),
                            if (student.gender != null) ...[
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 7, vertical: 2),
                                decoration: BoxDecoration(
                                  color: color.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  student.gender!.toUpperCase(),
                                  style: TextStyle(
                                      fontSize: 10,
                                      color: color,
                                      fontWeight: FontWeight.w600),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.arrow_forward_ios_rounded,
                      size: 14, color: AppColors.textHint),
                ],
              ),
            ),
          ),

          // Action buttons row
          Container(
            decoration: BoxDecoration(
              color: AppColors.surfaceVariant.withValues(alpha: 0.5),
              borderRadius:
                  const BorderRadius.vertical(bottom: Radius.circular(16)),
            ),
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            child: Row(
              children: [
                _ActionBtn(
                  icon: Icons.fact_check_outlined,
                  label: 'Attendance',
                  color: AppColors.attendancePresent,
                  onTap: () {
                    if (assignments.isNotEmpty) {
                      final a = assignments.first;
                      context.push(RouteNames.teacherAttendanceMark, extra: {
                        'classId': a.classId,
                        'className': a.className,
                        'assignmentId': a.id,
                      });
                    }
                  },
                ),
                _ActionBtn(
                  icon: Icons.grade_outlined,
                  label: 'Add Result',
                  color: AppColors.secondary,
                  onTap: () {
                    if (assignments.isNotEmpty) {
                      final a = assignments.first;
                      context.push(RouteNames.teacherResultAdd, extra: {
                        'assignmentId': a.id,
                        'className': a.className,
                        'subjectName': a.subjectName,
                        'preselectedStudentId': student.id,
                      });
                    }
                  },
                ),
                _ActionBtn(
                  icon: Icons.chat_bubble_outline_rounded,
                  label: 'Message',
                  color: AppColors.primary,
                  onTap: () => _messageParent(context),
                ),
                _ActionBtn(
                  icon: Icons.visibility_outlined,
                  label: 'View',
                  color: AppColors.info,
                  onTap: () => context.push(RouteNames.teacherStudentDetail,
                      extra: {
                        'studentId': student.id,
                        'studentName': student.fullName,
                      }),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _messageParent(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => _MessageParentSheet(student: student),
    );
  }
}

class _MessageParentSheet extends ConsumerWidget {
  final Student student;
  const _MessageParentSheet({required this.student});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2)),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.chat_bubble_outline_rounded,
                    color: AppColors.primary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Message Parent',
                        style: TextStyle(
                            fontWeight: FontWeight.w700, fontSize: 16)),
                    Text('Regarding: ${student.fullName}',
                        style: const TextStyle(
                            color: AppColors.textSecondary, fontSize: 13)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _MessageOption(
            icon: Icons.person_outline_rounded,
            title: "Message ${student.firstName}'s Parent",
            subtitle: 'Send a direct message to this student\'s parent',
            color: AppColors.primary,
            onTap: () {
              Navigator.pop(context);
              context.push(RouteNames.teacherMessages);
            },
          ),
          const SizedBox(height: 12),
          _MessageOption(
            icon: Icons.groups_rounded,
            title: 'Message All Parents',
            subtitle: 'Broadcast a message to all parents in the class',
            color: AppColors.secondary,
            onTap: () {
              Navigator.pop(context);
              context.push(RouteNames.teacherAnnouncements);
            },
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _MessageOption extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;
  const _MessageOption(
      {required this.icon,
      required this.title,
      required this.subtitle,
      required this.color,
      required this.onTap});

  @override
  Widget build(BuildContext context) => InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withValues(alpha: 0.2)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                            color: color)),
                    Text(subtitle,
                        style: const TextStyle(
                            fontSize: 12, color: AppColors.textSecondary)),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios_rounded,
                  size: 14, color: color.withValues(alpha: 0.6)),
            ],
          ),
        ),
      );
}

class _ActionBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _ActionBtn(
      {required this.icon,
      required this.label,
      required this.color,
      required this.onTap});

  @override
  Widget build(BuildContext context) => Expanded(
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Column(
              children: [
                Icon(icon, color: color, size: 18),
                const SizedBox(height: 3),
                Text(
                  label,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontSize: 9,
                      color: color,
                      fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ),
      );
}
