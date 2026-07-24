import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/loading_widget.dart';
import '../../models/result_model.dart';
import '../../models/student_model.dart';
import '../students/students_provider.dart';
import 'results_provider.dart';

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
    if (marks == null || total == null || total == 0) return null;
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
            onPressed: _submit,
            child: const Text('Save'),
          ),
        ],
      ),
      body: assignmentsAsync.when(
        data: (assignments) {
          final assignment = assignments.where((a) => a.id == widget.assignmentId).firstOrNull;
          final classId = assignment?.classId ?? '';

          final studentsAsync = ref.watch(classStudentsListProvider(classId));

          return studentsAsync.when(
            data: (students) {
              // Pre-select student if navigated from student detail
              if (widget.preselectedStudentId != null && _selectedStudent == null) {
                final match = students.where((s) => s.id == widget.preselectedStudentId).firstOrNull;
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
                            const Icon(Icons.book_outlined, color: AppColors.secondary, size: 20),
                            const SizedBox(width: 10),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(widget.subjectName,
                                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: AppColors.secondary)),
                                Text(widget.className,
                                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Student selector
                      const Text('Student', style: TextStyle(fontWeight: FontWeight.w600)),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<Student>(
                        value: _selectedStudent,
                        decoration: const InputDecoration(
                          hintText: 'Select student',
                          prefixIcon: Icon(Icons.person_outlined),
                        ),
                        items: students.map((s) => DropdownMenuItem(
                          value: s,
                          child: Text(s.fullName),
                        )).toList(),
                        onChanged: (s) => setState(() => _selectedStudent = s),
                        validator: (v) => v == null ? 'Please select a student' : null,
                      ),
                      const SizedBox(height: 16),

                      // Exam type
                      const Text('Exam Type', style: TextStyle(fontWeight: FontWeight.w600)),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        children: ExamType.values.map((t) => ChoiceChip(
                          label: Text(t.label),
                          selected: _examType == t,
                          onSelected: (v) => v ? setState(() => _examType = t) : null,
                          selectedColor: AppColors.primaryLight,
                          labelStyle: TextStyle(
                            color: _examType == t ? AppColors.primary : AppColors.textSecondary,
                            fontWeight: _examType == t ? FontWeight.w600 : FontWeight.normal,
                          ),
                        )).toList(),
                      ),
                      const SizedBox(height: 16),

                      // Marks
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Marks Obtained', style: TextStyle(fontWeight: FontWeight.w600)),
                                const SizedBox(height: 8),
                                TextFormField(
                                  controller: _marksController,
                                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                  decoration: const InputDecoration(hintText: '85'),
                                  onChanged: (_) => setState(() => _computedGrade = _computeGrade()),
                                  validator: (v) {
                                    if (v == null || v.isEmpty) return 'Required';
                                    final marks = double.tryParse(v);
                                    final total = double.tryParse(_totalController.text);
                                    if (marks == null) return 'Invalid';
                                    if (total != null && marks > total) return 'Exceeds total';
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
                                const Text('Total Marks', style: TextStyle(fontWeight: FontWeight.w600)),
                                const SizedBox(height: 8),
                                TextFormField(
                                  controller: _totalController,
                                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                  decoration: const InputDecoration(hintText: '100'),
                                  onChanged: (_) => setState(() => _computedGrade = _computeGrade()),
                                  validator: (v) {
                                    if (v == null || v.isEmpty) return 'Required';
                                    if (double.tryParse(v) == null) return 'Invalid';
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
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          decoration: BoxDecoration(
                            color: AppColors.successLight,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.auto_awesome_rounded, color: AppColors.success, size: 16),
                              const SizedBox(width: 8),
                              Text('Grade: $_computedGrade',
                                  style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.success)),
                            ],
                          ),
                        ),
                      ],
                      const SizedBox(height: 16),

                      // Exam date
                      const Text('Exam Date', style: TextStyle(fontWeight: FontWeight.w600)),
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
                          child: Text(DateFormat('EEEE, MMMM d, yyyy').format(_examDate)),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Remarks
                      const Text('Remarks (Optional)', style: TextStyle(fontWeight: FontWeight.w600)),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _remarksController,
                        maxLines: 3,
                        decoration: const InputDecoration(hintText: 'Add remarks...'),
                      ),
                      const SizedBox(height: 32),

                      ElevatedButton.icon(
                        onPressed: _submit,
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

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedStudent == null) return;

    final grade = _computeGrade();
    final notifier = ref.read(resultsNotifierProvider.notifier);

    await notifier.create({
      'student_id': _selectedStudent!.id,
      'teacher_assignment_id': widget.assignmentId,
      'marks_obtained': double.tryParse(_marksController.text),
      'total_marks': double.tryParse(_totalController.text),
      'grade': grade,
      'exam_type': _examType.value,
      'exam_date': _examDate.toIso8601String().split('T')[0],
      if (_remarksController.text.isNotEmpty) 'remarks': _remarksController.text,
    });

    final state = ref.read(resultsNotifierProvider);
    state.when(
      data: (_) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Result saved successfully'),
              backgroundColor: AppColors.success,
            ),
          );
          Navigator.pop(context);
        }
      },
      error: (e, _) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error),
        );
      },
      loading: () {},
    );
  }
}
