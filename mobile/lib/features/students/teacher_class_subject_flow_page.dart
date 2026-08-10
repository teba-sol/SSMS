import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/localization/app_localizations.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/empty_widget.dart';
import '../../core/widgets/loading_widget.dart';
import '../../models/student_model.dart';
import '../../models/teacher_model.dart';
import '../activities/activity_form_page.dart';
import '../attendance/attendance_mark_page.dart';
import '../results/result_form_page.dart';
import 'students_provider.dart';

enum TeacherClassFlowMode { classes, attendance, results, activities }

/// A teacher only sees the classes and subjects assigned to them.  The final
/// student list is always read from the selected class's active enrolments.
class TeacherClassSubjectFlowPage extends ConsumerStatefulWidget {
  const TeacherClassSubjectFlowPage({
    super.key,
    this.mode = TeacherClassFlowMode.classes,
    this.initialClassId,
  });

  final TeacherClassFlowMode mode;
  final String? initialClassId;

  @override
  ConsumerState<TeacherClassSubjectFlowPage> createState() =>
      _TeacherClassSubjectFlowPageState();
}

class _TeacherClassSubjectFlowPageState
    extends ConsumerState<TeacherClassSubjectFlowPage> {
  TeacherAssignment? _selectedClass;
  TeacherAssignment? _selectedAssignment;

  String _title(BuildContext context) {
    final strings = AppLocalizations.of(context);
    return switch (widget.mode) {
      TeacherClassFlowMode.classes => strings.myClasses,
      TeacherClassFlowMode.attendance => strings.attendance,
      TeacherClassFlowMode.results => strings.results,
      TeacherClassFlowMode.activities => strings.studentActivities,
    };
  }

  @override
  Widget build(BuildContext context) {
    final assignmentsAsync = ref.watch(teacherAssignmentsProvider);
    return Scaffold(
      appBar: AppBar(
        leading: _selectedClass == null
            ? null
            : IconButton(
                icon: const Icon(Icons.arrow_back_rounded),
                onPressed: () => setState(() {
                  if (_selectedAssignment != null) {
                    _selectedAssignment = null;
                  } else {
                    _selectedClass = null;
                  }
                }),
              ),
        title: Text(_selectedAssignment?.subjectName ??
            _selectedClass?.className ??
            _title(context)),
      ),
      body: assignmentsAsync.when(
        loading: () => const ShimmerList(count: 4),
        error: (error, _) =>
            Center(child: Text('Unable to load classes: $error')),
        data: (assignments) {
          if (widget.initialClassId != null &&
              _selectedClass == null &&
              assignments.isNotEmpty) {
            for (final assignment in assignments) {
              if (assignment.classId == widget.initialClassId) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted && _selectedClass == null) {
                    setState(() {
                      _selectedClass = assignment;
                      _selectedAssignment = null;
                    });
                  }
                });
                break;
              }
            }
          }

          if (assignments.isEmpty) {
            return EmptyWidget(
              title: AppLocalizations.of(context).noClassesAssigned,
              subtitle: AppLocalizations.of(context).noClassesAssignedDescription,
              icon: Icons.class_outlined,
            );
          }
          if (_selectedClass == null) return _classList(assignments);
          if (_selectedAssignment == null) return _subjectList(assignments);
          return _studentList(_selectedAssignment!);
        },
      ),
    );
  }

  Widget _classList(List<TeacherAssignment> assignments) {
    final classes = <String, TeacherAssignment>{};
    for (final assignment in assignments) {
      classes.putIfAbsent(assignment.classId, () => assignment);
    }
    final strings = AppLocalizations.of(context);
    final instruction = switch (widget.mode) {
      TeacherClassFlowMode.classes => strings.chooseClassToViewSubjects,
      TeacherClassFlowMode.attendance => strings.chooseClassForAttendance,
      TeacherClassFlowMode.results => strings.chooseClassForResults,
      TeacherClassFlowMode.activities => strings.chooseClassForActivityLog,
    };

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text(instruction,
            style: const TextStyle(color: AppColors.textSecondary)),
        const SizedBox(height: 16),
        ...classes.values.map((assignment) => Card(
              child: ListTile(
                leading: const CircleAvatar(child: Icon(Icons.class_rounded)),
                title: Text(assignment.className,
                    style: const TextStyle(fontWeight: FontWeight.w700)),
                subtitle: Text(
                    '${assignments.where((a) => a.classId == assignment.classId).length} subject(s) assigned'),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () => setState(() => _selectedClass = assignment),
              ),
            )),
      ],
    );
  }

  Widget _subjectList(List<TeacherAssignment> assignments) {
    final subjects =
        assignments.where((a) => a.classId == _selectedClass!.classId).toList();
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text(AppLocalizations.of(context).subjectsYouTeachIn(_selectedClass!.className),
            style: const TextStyle(color: AppColors.textSecondary)),
        const SizedBox(height: 16),
        ...subjects.map((assignment) => Card(
              child: ListTile(
                leading: const CircleAvatar(
                    backgroundColor: AppColors.secondaryLight,
                    child: Icon(Icons.menu_book_rounded,
                        color: AppColors.secondary)),
                title: Text(assignment.subjectName,
                    style: const TextStyle(fontWeight: FontWeight.w700)),
                subtitle: Text(assignment.subjectCode.isEmpty
                    ? _selectedClass!.className
                    : assignment.subjectCode),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () => setState(() => _selectedAssignment = assignment),
              ),
            )),
      ],
    );
  }

  Widget _studentList(TeacherAssignment assignment) {
    final studentsAsync =
        ref.watch(classStudentsListProvider(assignment.classId));
    return studentsAsync.when(
      loading: () =>
          const LoadingWidget(message: 'Loading enrolled students...'),
      error: (error, _) =>
          Center(child: Text('Unable to load students: $error')),
      data: (students) {
        if (students.isEmpty) {
          return EmptyWidget(
            title: AppLocalizations.of(context).noStudentsEnrolled,
            subtitle: AppLocalizations.of(context).noStudentsEnrolledDescription,
            icon: Icons.people_outline_rounded,
          );
        }
        return Column(
          children: [
            _contextHeader(assignment, students.length),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
                itemCount: students.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (_, index) =>
                    _studentTile(students[index], assignment),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _contextHeader(TeacherAssignment assignment, int count) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        color: AppColors.surfaceVariant,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('${assignment.className} • ${assignment.subjectName}',
              style: const TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          Text(AppLocalizations.of(context).enrolledStudentsCount(count),
              style: const TextStyle(
                  color: AppColors.textSecondary, fontSize: 12)),
          if (widget.mode == TeacherClassFlowMode.attendance) ...[
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: () => _openAttendance(assignment, isBulk: true),
              icon: const Icon(Icons.fact_check_rounded),
              label: Text(AppLocalizations.of(context).takeAttendanceForClassSubject),
            ),
          ],
          if (widget.mode == TeacherClassFlowMode.activities) ...[
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: () => _openClassActivityForm(assignment),
              icon: const Icon(Icons.campaign_rounded),
              label: const Text('Broadcast class log'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.success,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ]),
      );

  Widget _studentTile(Student student, TeacherAssignment assignment) => Card(
        child: ListTile(
          leading: CircleAvatar(
              child: Text(student.firstName.substring(0, 1).toUpperCase())),
          title: Text(student.fullName,
              style: const TextStyle(fontWeight: FontWeight.w600)),
          subtitle: Text(student.studentId),
          trailing: _studentActionLabel(),
          onTap: () => _openStudentAction(student, assignment),
        ),
      );

  Widget _studentActionLabel() => switch (widget.mode) {
        TeacherClassFlowMode.attendance =>
          const Icon(Icons.edit_note_rounded),
        TeacherClassFlowMode.results => Text(AppLocalizations.of(context).addResult,
            style: const TextStyle(color: AppColors.secondary, fontSize: 12)),
        TeacherClassFlowMode.activities => Text(AppLocalizations.of(context).addLog,
            style: const TextStyle(color: AppColors.success, fontSize: 12)),
        TeacherClassFlowMode.classes => const Icon(Icons.more_horiz_rounded),
      };

  void _openAttendance(
    TeacherAssignment assignment, {
    bool isBulk = false,
    String? selectedStudentId,
    String? selectedStudentName,
  }) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => AttendanceMarkPage(
        classId: assignment.classId,
        className: '${assignment.className} • ${assignment.subjectName}',
        assignmentId: assignment.id,
        isBulkMode: isBulk,
        selectedStudentId: selectedStudentId,
        selectedStudentName: selectedStudentName,
      ),
    ));
  }

  void _openClassActivityForm(TeacherAssignment assignment) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => ActivityFormPage(
        classId: assignment.classId,
        className: assignment.className,
        academicYearId: assignment.academicYearId,
      ),
    ));
  }

  void _openStudentAction(Student student, TeacherAssignment assignment) {
    switch (widget.mode) {
      case TeacherClassFlowMode.attendance:
        _openAttendance(
          assignment,
          isBulk: false,
          selectedStudentId: student.id,
          selectedStudentName: student.fullName,
        );
      case TeacherClassFlowMode.results:
        Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => ResultFormPage(
            assignmentId: assignment.id,
            className: assignment.className,
            subjectName: assignment.subjectName,
            preselectedStudentId: student.id,
          ),
        ));
      case TeacherClassFlowMode.activities:
        Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => ActivityFormPage(
            classId: assignment.classId,
            className: '${assignment.className} • ${assignment.subjectName}',
            academicYearId: assignment.academicYearId,
            studentId: student.id,
            studentName: student.fullName,
          ),
        ));
      case TeacherClassFlowMode.classes:
        _showStudentActions(student, assignment);
    }
  }

  Future<void> _showStudentActions(
          Student student, TeacherAssignment assignment) =>
      showModalBottomSheet<void>(
        context: context,
        builder: (sheetContext) => SafeArea(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            ListTile(
                title: Text(student.fullName),
                subtitle: Text(assignment.subjectName)),
            ListTile(
              leading: const Icon(Icons.fact_check_outlined),
              title: Text(AppLocalizations.of(context).takeAttendanceForStudent),
              onTap: () {
                Navigator.pop(sheetContext);
                _openAttendance(
                  assignment,
                  isBulk: false,
                  selectedStudentId: student.id,
                  selectedStudentName: student.fullName,
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.grade_outlined),
              title: Text(AppLocalizations.of(context).addResult),
              onTap: () {
                Navigator.pop(sheetContext);
                _openStudentActionForMode(
                    student, assignment, TeacherClassFlowMode.results);
              },
            ),
            ListTile(
              leading: const Icon(Icons.event_note_outlined),
              title: Text(AppLocalizations.of(context).addStudentLog),
              onTap: () {
                Navigator.pop(sheetContext);
                _openStudentActionForMode(
                    student, assignment, TeacherClassFlowMode.activities);
              },
            ),
          ]),
        ),
      );

  void _openStudentActionForMode(Student student, TeacherAssignment assignment,
      TeacherClassFlowMode mode) {
    final previousMode = widget.mode;
    // The page is in classes mode; open the same destination used by the other flows.
    if (mode == TeacherClassFlowMode.results) {
      Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => ResultFormPage(
              assignmentId: assignment.id,
              className: assignment.className,
              subjectName: assignment.subjectName,
              preselectedStudentId: student.id)));
    } else if (mode == TeacherClassFlowMode.activities) {
      Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => ActivityFormPage(
              classId: assignment.classId,
              className: '${assignment.className} • ${assignment.subjectName}',
              academicYearId: assignment.academicYearId,
              studentId: student.id,
              studentName: student.fullName)));
    }
    assert(previousMode == TeacherClassFlowMode.classes);
  }
}
