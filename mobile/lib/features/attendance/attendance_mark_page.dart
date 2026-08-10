import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/loading_widget.dart';
import '../../models/attendance_model.dart';
import '../students/students_provider.dart';
import 'attendance_provider.dart';

class AttendanceMarkPage extends ConsumerStatefulWidget {
  final String classId;
  final String className;
  final String assignmentId;
  final bool isBulkMode;
  final String? selectedStudentId;
  final String? selectedStudentName;

  const AttendanceMarkPage({
    super.key,
    required this.classId,
    required this.className,
    required this.assignmentId,
    this.isBulkMode = true,
    this.selectedStudentId,
    this.selectedStudentName,
  });

  @override
  ConsumerState<AttendanceMarkPage> createState() => _AttendanceMarkPageState();
}

class _AttendanceMarkPageState extends ConsumerState<AttendanceMarkPage> {
  DateTime _selectedDate = DateTime.now();
  final Map<String, AttendanceDraft> _drafts = {};
  bool _isSubmitting = false;

  @override
  Widget build(BuildContext context) {
    final studentsAsync = ref.watch(classStudentsListProvider(widget.classId));
    final existingAsync = ref.watch(classAttendanceProvider((
      classId: widget.classId,
      date: DateFormat('yyyy-MM-dd').format(_selectedDate),
    )));

    final isSingleStudent = !widget.isBulkMode && widget.selectedStudentId != null;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          isSingleStudent
              ? '${widget.selectedStudentName ?? 'Student'} • ${widget.className}'
              : widget.className,
        ),
        actions: [
          TextButton.icon(
            onPressed: _isSubmitting ? null : () => _submit(),
            icon: _isSubmitting
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: AppColors.primary))
                : const Icon(Icons.check_rounded),
            label: const Text('Submit'),
          ),
        ],
      ),
      body: studentsAsync.when(
        data: (students) {
          if (students.isEmpty) {
            return const Center(
              child: Text('No enrolled students in this class.',
                  style: TextStyle(color: AppColors.textSecondary)),
            );
          }

          // Initialize drafts from existing records
          return existingAsync.when(
            data: (existing) {
              // Build drafts if not already initialized
              for (final s in students) {
                if (!_drafts.containsKey(s.id)) {
                  final ex = existing.where((e) => e.studentId == s.id).firstOrNull;
                  _drafts[s.id] = AttendanceDraft(
                    studentId: s.id,
                    studentName: s.fullName,
                    studentNumber: s.studentId,
                    status: ex?.status ?? AttendanceStatus.present,
                    notes: ex?.notes,
                    existingId: ex?.id,
                  );
                }
              }

              final isSingleStudent = !widget.isBulkMode && widget.selectedStudentId != null;

              return Column(
                children: [
                  // Date selector
                  _DateSelector(
                    selectedDate: _selectedDate,
                    onDateChanged: (d) => setState(() {
                      _selectedDate = d;
                      _drafts.clear(); // reset drafts on date change
                    }),
                  ),

                  if (widget.isBulkMode) ...[
                    _BulkActions(onMarkAll: (status) {
                      setState(() {
                        for (final d in _drafts.values) {
                          d.status = status;
                        }
                      });
                    }),
                  ],

                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: isSingleStudent ? 1 : students.length,
                      itemBuilder: (ctx, i) {
                        final s = isSingleStudent
                            ? students.firstWhere(
                                (student) => student.id == widget.selectedStudentId)
                            : students[i];
                        final draft = _drafts[s.id]!;
                        return _StudentAttendanceRow(
                          draft: draft,
                          onStatusChanged: (status) {
                            setState(() => draft.status = status);
                          },
                          onNotesChanged: (notes) => draft.notes = notes,
                        );
                      },
                    ),
                  ),
                ],
              );
            },
            loading: () => const LoadingWidget(message: 'Loading existing records...'),
            error: (_, __) {
              // Still show list even if existing records fail
              for (final s in students) {
                if (!_drafts.containsKey(s.id)) {
                  _drafts[s.id] = AttendanceDraft(
                    studentId: s.id,
                    studentName: s.fullName,
                    studentNumber: s.studentId,
                  );
                }
              }
              final isSingleStudent = !widget.isBulkMode && widget.selectedStudentId != null;

              return Column(
                children: [
                  _DateSelector(
                    selectedDate: _selectedDate,
                    onDateChanged: (d) => setState(() {
                      _selectedDate = d;
                      _drafts.clear();
                    }),
                  ),
                  if (widget.isBulkMode) ...[
                    _BulkActions(onMarkAll: (status) {
                      setState(() {
                        for (final d in _drafts.values) { d.status = status; }
                      });
                    }),
                  ],
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: isSingleStudent ? 1 : students.length,
                      itemBuilder: (ctx, i) {
                        final s = isSingleStudent
                            ? students.firstWhere(
                                (student) => student.id == widget.selectedStudentId)
                            : students[i];
                        final draft = _drafts[s.id]!;
                        return _StudentAttendanceRow(
                          draft: draft,
                          onStatusChanged: (status) =>
                              setState(() => draft.status = status),
                          onNotesChanged: (notes) => draft.notes = notes,
                        );
                      },
                    ),
                  ),
                ],
              );
            },
          );
        },
        loading: () => const LoadingWidget(message: 'Loading students...'),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }

  Future<void> _submit() async {
    if (_drafts.isEmpty) return;
    setState(() => _isSubmitting = true);

    final teacherAsync = await ref.read(currentTeacherProvider.future);
    if (teacherAsync == null) {
      setState(() => _isSubmitting = false);
      return;
    }

    final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate);
    final records = _drafts.values.map((d) => {
      'student_id': d.studentId,
      'class_id': widget.classId,
      'date': dateStr,
      'status': d.status.value,
      'marked_by': teacherAsync.id,
      if (d.notes != null && d.notes!.isNotEmpty) 'notes': d.notes,
    }).toList();

    final notifier = ref.read(markAttendanceProvider(widget.classId).notifier);
    await notifier.mark(records);

    setState(() => _isSubmitting = false);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Attendance saved successfully'),
          backgroundColor: AppColors.success,
        ),
      );
      Navigator.pop(context);
    }
  }
}

class _DateSelector extends StatelessWidget {
  final DateTime selectedDate;
  final ValueChanged<DateTime> onDateChanged;
  const _DateSelector({required this.selectedDate, required this.onDateChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          const Icon(Icons.calendar_today_outlined,
              size: 18, color: AppColors.primary),
          const SizedBox(width: 8),
          Text(
            DateFormat('EEEE, MMMM d, yyyy').format(selectedDate),
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
          ),
          const Spacer(),
          TextButton(
            onPressed: () async {
              final d = await showDatePicker(
                context: context,
                initialDate: selectedDate,
                firstDate: DateTime(2024),
                lastDate: DateTime.now(),
              );
              if (d != null) onDateChanged(d);
            },
            child: const Text('Change'),
          ),
        ],
      ),
    );
  }
}

class _BulkActions extends StatelessWidget {
  final ValueChanged<AttendanceStatus> onMarkAll;
  const _BulkActions({required this.onMarkAll});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      color: AppColors.surfaceVariant,
      child: Row(
        children: [
          const Text('Mark All:',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
          const SizedBox(width: 10),
          _BulkChip('Present', AppColors.attendancePresent, () => onMarkAll(AttendanceStatus.present)),
          const SizedBox(width: 6),
          _BulkChip('Absent', AppColors.attendanceAbsent, () => onMarkAll(AttendanceStatus.absent)),
          const SizedBox(width: 6),
          _BulkChip('Late', AppColors.attendanceLate, () => onMarkAll(AttendanceStatus.late)),
        ],
      ),
    );
  }
}

class _BulkChip extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _BulkChip(this.label, this.color, this.onTap);

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: color.withValues(alpha: 0.3)),
          ),
          child: Text(label,
              style: TextStyle(
                  fontSize: 11, fontWeight: FontWeight.w600, color: color)),
        ),
      );
}

class _StudentAttendanceRow extends StatelessWidget {
  final AttendanceDraft draft;
  final ValueChanged<AttendanceStatus> onStatusChanged;
  final ValueChanged<String?> onNotesChanged;

  const _StudentAttendanceRow({
    required this.draft,
    required this.onStatusChanged,
    required this.onNotesChanged,
  });

  @override
  Widget build(BuildContext context) {
    final (statusColor, statusBg) = switch (draft.status) {
      AttendanceStatus.present => (AppColors.attendancePresent, AppColors.attendancePresentLight),
      AttendanceStatus.absent => (AppColors.attendanceAbsent, AppColors.attendanceAbsentLight),
      AttendanceStatus.late => (AppColors.attendanceLate, AppColors.attendanceLateLight),
      AttendanceStatus.excused => (AppColors.attendanceExcused, AppColors.attendanceExcusedLight),
    };

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: statusBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: statusColor.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: statusColor.withValues(alpha: 0.2),
                child: Text(
                  draft.studentName.substring(0, 1).toUpperCase(),
                  style: TextStyle(
                      color: statusColor,
                      fontWeight: FontWeight.w700,
                      fontSize: 14),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(draft.studentName,
                        style: const TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 14)),
                    Text(draft.studentNumber,
                        style: const TextStyle(
                            color: AppColors.textSecondary, fontSize: 12)),
                  ],
                ),
              ),
              // Status selector
              Container(
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.border),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<AttendanceStatus>(
                    value: draft.status,
                    isDense: true,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    items: AttendanceStatus.values
                        .map((s) => DropdownMenuItem(
                              value: s,
                              child: Text(s.label,
                                  style: const TextStyle(fontSize: 13)),
                            ))
                        .toList(),
                    onChanged: (v) => v != null ? onStatusChanged(v) : null,
                  ),
                ),
              ),
            ],
          ),
          if (draft.status == AttendanceStatus.absent ||
              draft.status == AttendanceStatus.late) ...[
            const SizedBox(height: 8),
            TextField(
              onChanged: onNotesChanged,
              decoration: InputDecoration(
                hintText: 'Add a note (optional)...',
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                isDense: true,
                hintStyle: const TextStyle(
                    fontSize: 12, color: AppColors.textHint),
                filled: true,
                fillColor: AppColors.surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
              ),
              style: const TextStyle(fontSize: 12),
            ),
          ],
        ],
      ),
    );
  }
}
