import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_colors.dart';
import 'activities_provider.dart';

class ActivityFormPage extends ConsumerStatefulWidget {
  final String? classId;
  final String className;
  final String academicYearId;
  final String? studentId;
  final String? studentName;

  const ActivityFormPage({
    super.key,
    this.classId,
    required this.className,
    required this.academicYearId,
    this.studentId,
    this.studentName,
  });

  bool get isStudentLog => studentId != null;

  @override
  ConsumerState<ActivityFormPage> createState() => _ActivityFormPageState();
}

class _ActivityFormPageState extends ConsumerState<ActivityFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  DateTime _activityDate = DateTime.now();
  bool _isSubmitting = false;

  static const _classEventTypes = [
    'event',
    'sports',
    'club',
    'field_trip',
    'competition',
    'assignment',
    'behavior',
    'participation',
  ];

  static const _studentLogTypes = [
    'behavior',
    'participation',
    'achievement',
    'concern',
    'counseling',
    'discipline',
    'health',
    'other',
  ];

  late String _activityType;

  @override
  void initState() {
    super.initState();
    _activityType = widget.isStudentLog ? 'behavior' : 'event';
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  List<String> get _types =>
      widget.isStudentLog ? _studentLogTypes : _classEventTypes;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(widget.isStudentLog ? 'Student Log' : 'Class Log'),
        actions: [
          TextButton(
            onPressed: _isSubmitting ? null : _submit,
            child: const Text('Save'),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // Context banner
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: widget.isStudentLog
                    ? AppColors.warningLight
                    : AppColors.successLight,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(
                    widget.isStudentLog
                        ? Icons.person_outline_rounded
                        : Icons.class_,
                    color: widget.isStudentLog
                        ? AppColors.warning
                        : AppColors.success,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.isStudentLog
                              ? 'Student: ${widget.studentName}'
                              : 'Class: ${widget.className}',
                          style: TextStyle(
                              color: widget.isStudentLog
                                  ? AppColors.warning
                                  : AppColors.success,
                              fontWeight: FontWeight.w600,
                              fontSize: 13),
                        ),
                        if (widget.isStudentLog)
                          const Text(
                            'Only this student\'s active parent(s) will be notified.',
                            style: TextStyle(
                                color: AppColors.warning, fontSize: 11),
                          )
                        else
                          const Text(
                            'All active parents in this class will be notified.',
                            style: TextStyle(
                                color: AppColors.success, fontSize: 11),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Log type chips
            Text(
              'Activity Type',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _types.map((t) {
                final selected = _activityType == t;
                final (color, _) = _typeStyle(t);
                return ChoiceChip(
                  label: Text(_prettyType(t)),
                  selected: selected,
                  onSelected: (v) =>
                      v ? setState(() => _activityType = t) : null,
                  selectedColor: color.withValues(alpha: 0.15),
                  labelStyle: TextStyle(
                    color: selected ? color : AppColors.textSecondary,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.normal,
                    fontSize: 12,
                  ),
                  side: BorderSide(color: selected ? color : AppColors.border),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),

            const Text('Title / Summary',
                style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            TextFormField(
              controller: _titleCtrl,
              decoration: InputDecoration(
                hintText: 'Activity title',
              ),
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 16),

            const Text('Date', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            InkWell(
              onTap: () async {
                final d = await showDatePicker(
                  context: context,
                  initialDate: _activityDate,
                  firstDate: DateTime(2024),
                  lastDate: DateTime.now().add(const Duration(days: 365)),
                );
                if (d != null) setState(() => _activityDate = d);
              },
              child: InputDecorator(
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.calendar_today_outlined),
                ),
                child: Text(
                    DateFormat('EEEE, MMMM d, yyyy').format(_activityDate)),
              ),
            ),
            const SizedBox(height: 16),

            Text(
              'Description (Optional)',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _descCtrl,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: 'Describe the activity...',
              ),
            ),
            const SizedBox(height: 32),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isSubmitting ? null : _submit,
                icon: Icon(Icons.event_note_rounded),
                label: _isSubmitting
                    ? const Text('Saving...')
                    : Text(widget.isStudentLog
                        ? 'Save Student Log'
                        : 'Broadcast Class Log'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.success,
                ),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  String _prettyType(String t) => t
      .replaceAll('_', ' ')
      .split(' ')
      .map((w) => w.isNotEmpty ? '${w[0].toUpperCase()}${w.substring(1)}' : '')
      .join(' ');

  (Color, IconData) _typeStyle(String type) {
    return switch (type.toLowerCase()) {
      'behavior' => (AppColors.warning, Icons.psychology_rounded),
      'participation' => (AppColors.success, Icons.record_voice_over_rounded),
      'achievement' => (AppColors.gradeA, Icons.emoji_events_rounded),
      'concern' => (AppColors.error, Icons.warning_amber_rounded),
      'counseling' => (AppColors.info, Icons.support_agent_rounded),
      'discipline' => (AppColors.error, Icons.gavel_rounded),
      'health' => (AppColors.secondary, Icons.health_and_safety_outlined),
      'sports' => (AppColors.success, Icons.sports_rounded),
      'club' => (AppColors.secondary, Icons.groups_rounded),
      'field_trip' => (AppColors.info, Icons.directions_bus_rounded),
      'competition' => (AppColors.warning, Icons.emoji_events_rounded),
      'event' => (AppColors.primary, Icons.celebration_rounded),
      'assignment' => (AppColors.secondary, Icons.assignment_rounded),
      _ => (AppColors.primary, Icons.event_note_rounded),
    };
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSubmitting = true);

    await ref.read(activitiesNotifierProvider.notifier).create(
          title: _titleCtrl.text.trim(),
          description:
              _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
          activityType: _activityType,
          activityDate: _activityDate,
          classId: widget.classId,
          studentId: widget.studentId,
          academicYearId: widget.academicYearId,
        );

    setState(() => _isSubmitting = false);

    final state = ref.read(activitiesNotifierProvider);
    if (!mounted) return;

    state.when(
      data: (_) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.isStudentLog
                ? 'Student log saved and parent notified'
                : 'Class log saved and parents notified'),
            backgroundColor: AppColors.success,
          ),
        );
        Navigator.pop(context, true); // return true = refresh needed
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
