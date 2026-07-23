import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_colors.dart';
import 'activities_provider.dart';

class ActivityFormPage extends ConsumerStatefulWidget {
  final String? classId;
  final String className;
  final String academicYearId;

  const ActivityFormPage({
    super.key,
    this.classId,
    required this.className,
    required this.academicYearId,
  });

  @override
  ConsumerState<ActivityFormPage> createState() => _ActivityFormPageState();
}

class _ActivityFormPageState extends ConsumerState<ActivityFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _locationCtrl = TextEditingController();
  String _activityType = 'event';
  DateTime _activityDate = DateTime.now();
  bool _isSubmitting = false;

  final _types = ['event', 'sports', 'club', 'field_trip', 'competition', 'assignment', 'behavior', 'participation'];

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _locationCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Log Activity'),
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
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.successLight,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(Icons.class_, color: AppColors.success, size: 16),
                  const SizedBox(width: 8),
                  Text('Class: ${widget.className}',
                      style: const TextStyle(color: AppColors.success, fontWeight: FontWeight.w600, fontSize: 13)),
                ],
              ),
            ),
            const SizedBox(height: 16),

            const Text('Title', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            TextFormField(
              controller: _titleCtrl,
              decoration: const InputDecoration(hintText: 'Activity title'),
              validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 16),

            const Text('Activity Type', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _types.map((t) => ChoiceChip(
                label: Text(t.replaceAll('_', ' ').split(' ').map((w) => w.isNotEmpty ? w[0].toUpperCase() + w.substring(1) : '').join(' ')),
                selected: _activityType == t,
                onSelected: (v) => v ? setState(() => _activityType = t) : null,
                selectedColor: AppColors.successLight,
                labelStyle: TextStyle(
                  color: _activityType == t ? AppColors.success : AppColors.textSecondary,
                  fontWeight: _activityType == t ? FontWeight.w600 : FontWeight.normal,
                  fontSize: 12,
                ),
              )).toList(),
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
                child: Text(DateFormat('EEEE, MMMM d, yyyy').format(_activityDate)),
              ),
            ),
            const SizedBox(height: 16),

            const Text('Location (Optional)', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            TextFormField(
              controller: _locationCtrl,
              decoration: const InputDecoration(
                hintText: 'e.g. School Auditorium',
                prefixIcon: Icon(Icons.location_on_outlined),
              ),
            ),
            const SizedBox(height: 16),

            const Text('Description (Optional)', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            TextFormField(
              controller: _descCtrl,
              maxLines: 4,
              decoration: const InputDecoration(hintText: 'Describe the activity...'),
            ),
            const SizedBox(height: 32),

            ElevatedButton.icon(
              onPressed: _isSubmitting ? null : _submit,
              icon: const Icon(Icons.event_note_rounded),
              label: _isSubmitting
                  ? const Text('Saving...')
                  : const Text('Log Activity'),
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.success),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSubmitting = true);

    await ref.read(activitiesNotifierProvider.notifier).create(
          title: _titleCtrl.text.trim(),
          description: _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
          activityType: _activityType,
          activityDate: _activityDate,
          location: _locationCtrl.text.trim().isEmpty ? null : _locationCtrl.text.trim(),
          classId: widget.classId,
          academicYearId: widget.academicYearId,
        );

    setState(() => _isSubmitting = false);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Activity logged successfully'),
          backgroundColor: AppColors.success,
        ),
      );
      Navigator.pop(context);
    }
  }
}
