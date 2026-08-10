import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/loading_widget.dart';
import '../../models/result_model.dart';
import '../../models/student_model.dart';
import '../students/students_provider.dart';
import 'results_provider.dart';

String normalizeMarksInput(String value) {
  final trimmed = value.trim();
  if (trimmed.isEmpty) return '';

  final parsed = double.tryParse(trimmed);
  if (parsed == null) return trimmed;
  if (parsed < 0) return '0';

  if (parsed % 1 == 0) {
    return parsed.toInt().toString();
  }
  return parsed.toString();
}

Map<String, dynamic> buildResultPayload({
  required String studentId,
  required String assignmentId,
  required double? marksObtained,
  required double? totalMarks,
  required String? grade,
  required String examTypeValue,
  required String examDate,
  String? remarks,
  required bool notifyParents,
}) {
  return {
    'student_id': studentId,
    'teacher_assignment_id': assignmentId,
    'marks_obtained': marksObtained,
    'total_marks': totalMarks,
    'grade': grade,
    'exam_type': examTypeValue,
    'exam_date': examDate,
    if (remarks != null && remarks.isNotEmpty) 'remarks': remarks,
    'notify_parents': notifyParents,
  };
}

class ResultFormPage extends ConsumerStatefulWidget {
  final String assignmentId;
  final String className;
  final String subjectName;
  final String? preselectedStudentId;

  const ResultFormPage({
    super.key,
    required this.assignmentId,
    required this.className,
    required this.subjectName,
    this.preselectedStudentId,
  });

  @override
  ConsumerState<ResultFormPage> createState() => _ResultFormPageState();
}

class _ResultFormPageState extends ConsumerState<ResultFormPage> {
  final _formKey = GlobalKey<FormState>();
  Student? _selectedStudent;
  ExamType _examType = ExamType.quiz;
  final _marksController = TextEditingController();
  final _totalController = TextEditingController(text: '100');
  final _remarksController = TextEditingController();
  DateTime _examDate = DateTime.now();
  String? _computedGrade;

  @override
  void dispose() {
    _marksController.dispose();
    _totalController.dispose();
    _remarksController.dispose();
    super.dispose();
  }

  String? _computeGrade() {
    final marks = double.tryParse(_marksController.text);
    final total = double.tryParse(_totalController.text);
    if (marks == null || total == null || total <= 0) return null;
    final pct = (marks / total) * 100;
    if (pct >= 95) return 'A+';
    if (pct >= 90) return 'A';
    if (pct >= 85) return 'A-';
    if (pct >= 80) return 'B+';
    if (pct >= 75) return 'B';
    if (pct >= 70) return 'B-';
    if (pct >= 65) return 'C+';
    if (pct >= 60) return 'C';
    if (pct >= 55) return 'C-';
    if (pct >= 50) return 'D';
    return 'F';
  }

  @override
  Widget build(BuildContext context) {
    // Fetch students using the proper Riverpod provider keyed by assignmentId
    final assignmentsAsync = ref.watch(teacherAssignmentsProvider);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Add Result'),
        actions: [
          TextButton(
            onPressed: () => _showSaveOptions(context),
            child: const Text('Save'),
          ),
        ],
      ),
      body: assignmentsAsync.when(
        data: (assignments) {
          final assignment =
              assignments.where((a) => a.id == widget.assignmentId).firstOrNull;
          final classId = assignment?.classId ?? '';

          final studentsAsync = ref.watch(classStudentsListProvider(classId));

          return studentsAsync.when(
            data: (students) {
              // Pre-select student if navigated from student detail
              if (widget.preselectedStudentId != null &&
                  _selectedStudent == null) {
                final match = students
                    .where((s) => s.id == widget.preselectedStudentId)
                    .firstOrNull;
                if (match != null) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    setState(() => _selectedStudent = match);
                  });
                }
              }

              return SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Class & Subject info
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppColors.secondaryLight,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.book_outlined,
                                color: AppColors.secondary, size: 20),
                            const SizedBox(width: 10),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(widget.subjectName,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 15,
                                        color: AppColors.secondary)),
                                Text(widget.className,
                                    style: const TextStyle(
                                        color: AppColors.textSecondary,
                                        fontSize: 12)),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Student selector
                      const Text('Student',
                          style: TextStyle(fontWeight: FontWeight.w600)),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<Student>(
                        value: _selectedStudent,
                        decoration: const InputDecoration(
                          hintText: 'Select student',
                          prefixIcon: Icon(Icons.person_outlined),
                        ),
                        items: students
                            .map((s) => DropdownMenuItem(
                                  value: s,
                                  child: Text('${s.fullName} (${s.studentId})'),
                                ))
                            .toList(),
                        onChanged: (s) => setState(() => _selectedStudent = s),
                        validator: (v) =>
                            v == null ? 'Please select a student' : null,
                      ),
                      const SizedBox(height: 16),

                      // Exam type
                      const Text('Exam Type',
                          style: TextStyle(fontWeight: FontWeight.w600)),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        children: ExamType.values
                            .map((t) => ChoiceChip(
                                  label: Text(t.label),
                                  selected: _examType == t,
                                  onSelected: (v) =>
                                      v ? setState(() => _examType = t) : null,
                                  selectedColor: AppColors.primaryLight,
                                  labelStyle: TextStyle(
                                    color: _examType == t
                                        ? AppColors.primary
                                        : AppColors.textSecondary,
                                    fontWeight: _examType == t
                                        ? FontWeight.w600
                                        : FontWeight.normal,
                                  ),
                                ))
                            .toList(),
                      ),
                      const SizedBox(height: 16),

                      // Marks
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Marks Obtained',
                                    style:
                                        TextStyle(fontWeight: FontWeight.w600)),
                                const SizedBox(height: 8),
                                TextFormField(
                                  controller: _marksController,
                                  keyboardType:
                                      const TextInputType.numberWithOptions(
                                          decimal: true),
                                  decoration: const InputDecoration(
                                      hintText: '85'),
                                  onChanged: (value) {
                                    final normalized = normalizeMarksInput(value);
                                    if (normalized != value) {
                                      _marksController.value =
                                          TextEditingValue(
                                        text: normalized,
                                        selection: TextSelection.collapsed(
                                          offset: normalized.length,
                                        ),
                                      );
                                    }
                                    setState(() => _computedGrade = _computeGrade());
                                  },
                                  validator: (v) {
                                    if (v == null || v.isEmpty)
                                      return 'Required';
                                    final marks = double.tryParse(v);
                                    final total =
                                        double.tryParse(_totalController.text);
                                    if (marks == null) return 'Invalid';
                                    if (total == null || total <= 0) {
                                      return 'Enter a valid total mark';
                                    }
                                    if (marks < 0 || marks > total) {
                                      return 'Enter a score from 0 to $total';
                                    }
                                    return null;
                                  },
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Total Marks',
                                    style:
                                        TextStyle(fontWeight: FontWeight.w600)),
                                const SizedBox(height: 8),
                                TextFormField(
                                  controller: _totalController,
                                  keyboardType:
                                      const TextInputType.numberWithOptions(
                                          decimal: true),
                                  decoration: const InputDecoration(
                                      hintText: '100'),
                                  onChanged: (_) => setState(
                                      () => _computedGrade = _computeGrade()),
                                  validator: (v) {
                                    if (v == null || v.trim().isEmpty) {
                                      return 'Required';
                                    }
                                    final total = double.tryParse(v);
                                    if (total == null || total <= 0) {
                                      return 'Enter a total greater than 0';
                                    }
                                    return null;
                                  },
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      // Grade preview
                      if (_computedGrade != null) ...[
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 10),
                          decoration: BoxDecoration(
                            color: AppColors.successLight,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.auto_awesome_rounded,
                                  color: AppColors.success, size: 16),
                              const SizedBox(width: 8),
                              Text('Grade: $_computedGrade',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.success)),
                            ],
                          ),
                        ),
                      ],
                      const SizedBox(height: 16),

                      // Exam date
                      const Text('Exam Date',
                          style: TextStyle(fontWeight: FontWeight.w600)),
                      const SizedBox(height: 8),
                      InkWell(
                        onTap: () async {
                          final d = await showDatePicker(
                            context: context,
                            initialDate: _examDate,
                            firstDate: DateTime(2024),
                            lastDate: DateTime.now(),
                          );
                          if (d != null) setState(() => _examDate = d);
                        },
                        child: InputDecorator(
                          decoration: const InputDecoration(
                            prefixIcon: Icon(Icons.calendar_today_outlined),
                          ),
                          child: Text(DateFormat('EEEE, MMMM d, yyyy')
                              .format(_examDate)),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Remarks
                      const Text('Remarks (Optional)',
                          style: TextStyle(fontWeight: FontWeight.w600)),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _remarksController,
                        maxLines: 3,
                        decoration:
                            const InputDecoration(hintText: 'Add remarks...'),
                      ),
                      const SizedBox(height: 32),

                      ElevatedButton.icon(
                        onPressed: () => _showSaveOptions(context),
                        icon: const Icon(Icons.save_rounded),
                        label: const Text('Save Result'),
                      ),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              );
            },
            loading: () => const LoadingWidget(),
            error: (e, _) => Center(child: Text('Error loading students: $e')),
          );
        },
        loading: () => const LoadingWidget(),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }

  Future<void> _showSaveOptions(BuildContext context) async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedStudent == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a student first.')),
      );
      return;
    }

    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Choose save option',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              const Text(
                'Save the result now, or save it and notify the student\'s parent immediately.',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.save_outlined, color: AppColors.primary),
                title: const Text('Save result only'),
                subtitle: const Text('Store the result without sending a parent notification'),
                onTap: () {
                  Navigator.pop(sheetContext);
                  _submit(notifyParents: false);
                },
              ),
              ListTile(
                leading: const Icon(Icons.send_rounded, color: AppColors.success),
                title: const Text('Save and send to parent'),
                subtitle: const Text('Save the result and notify the parent right away'),
                onTap: () {
                  Navigator.pop(sheetContext);
                  _submit(notifyParents: true);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _submit({required bool notifyParents}) async {
    final grade = _computeGrade();
    final notifier = ref.read(resultsNotifierProvider.notifier);

    final payload = buildResultPayload(
      studentId: _selectedStudent!.id,
      assignmentId: widget.assignmentId,
      marksObtained: double.tryParse(_marksController.text),
      totalMarks: double.tryParse(_totalController.text),
      grade: grade,
      examTypeValue: _examType.value,
      examDate: _examDate.toIso8601String().split('T')[0],
      remarks: _remarksController.text,
      notifyParents: notifyParents,
    );

    final submissionData = Map<String, dynamic>.from(payload)
      ..remove('notify_parents');

    await notifier.create(submissionData);

    final state = ref.read(resultsNotifierProvider);
    state.when(
      data: (_) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(notifyParents
                  ? 'Result saved and sent to parent'
                  : 'Result saved successfully'),
              backgroundColor: AppColors.success,
            ),
          );
          Navigator.pop(context);
        }
      },
      error: (e, _) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Error: $e'), backgroundColor: AppColors.error),
        );
      },
      loading: () {},
    );
  }
}
