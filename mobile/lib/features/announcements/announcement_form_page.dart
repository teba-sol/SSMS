import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../models/announcement_model.dart';
import 'announcements_provider.dart';

class AnnouncementFormPage extends ConsumerStatefulWidget {
  final String? classId;
  final String? className;

  const AnnouncementFormPage({super.key, this.classId, this.className});

  @override
  ConsumerState<AnnouncementFormPage> createState() =>
      _AnnouncementFormPageState();
}

class _AnnouncementFormPageState
    extends ConsumerState<AnnouncementFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _contentCtrl = TextEditingController();
  AnnouncementPriority _priority = AnnouncementPriority.normal;
  AnnouncementTarget _target = AnnouncementTarget.all;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _titleCtrl.dispose();
    _contentCtrl.dispose();
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
        title: const Text('Create Announcement'),
        actions: [
          TextButton(
            onPressed: _isSubmitting ? null : _submit,
            child: _isSubmitting
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2))
                : const Text('Post'),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            if (widget.className != null) ...[
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.class_, color: AppColors.primary, size: 18),
                    const SizedBox(width: 10),
                    Text('For: ${widget.className}',
                        style: const TextStyle(
                            fontWeight: FontWeight.w600, color: AppColors.primary)),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Title
            const Text('Title', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            TextFormField(
              controller: _titleCtrl,
              decoration: const InputDecoration(hintText: 'Announcement title'),
              validator: (v) => v == null || v.trim().isEmpty ? 'Title is required' : null,
            ),
            const SizedBox(height: 16),

            // Content
            const Text('Message', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            TextFormField(
              controller: _contentCtrl,
              maxLines: 6,
              decoration: const InputDecoration(
                hintText: 'Write your announcement here...',
                alignLabelWithHint: true,
              ),
              validator: (v) => v == null || v.trim().isEmpty ? 'Content is required' : null,
            ),
            const SizedBox(height: 16),

            // Priority
            const Text('Priority', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: AnnouncementPriority.values
                  .map((p) => ChoiceChip(
                        label: Text(p.label),
                        selected: _priority == p,
                        onSelected: (v) => v ? setState(() => _priority = p) : null,
                      ))
                  .toList(),
            ),
            const SizedBox(height: 16),

            // Target audience
            const Text('Audience', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: AnnouncementTarget.values
                  .map((t) => ChoiceChip(
                        label: Text(t.label),
                        selected: _target == t,
                        onSelected: (v) => v ? setState(() => _target = t) : null,
                      ))
                  .toList(),
            ),
            const SizedBox(height: 32),

            ElevatedButton.icon(
              onPressed: _isSubmitting ? null : _submit,
              icon: const Icon(Icons.campaign_rounded),
              label: const Text('Post Announcement'),
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

    await ref.read(announcementsProvider.notifier).createAnnouncement(
          title: _titleCtrl.text.trim(),
          content: _contentCtrl.text.trim(),
          targetAudience: _target.value,
          priority: _priority.value,
          classId: widget.classId,
        );

    setState(() => _isSubmitting = false);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Announcement posted'),
          backgroundColor: AppColors.success,
        ),
      );
      Navigator.pop(context);
    }
  }
}
