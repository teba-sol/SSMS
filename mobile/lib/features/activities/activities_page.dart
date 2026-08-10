import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../core/router/route_names.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/loading_widget.dart';
import '../../core/widgets/empty_widget.dart';
import '../../core/widgets/app_card.dart';
import '../../models/activity_model.dart';
import '../students/students_provider.dart';
import '../students/teacher_class_subject_flow_page.dart';
import '../dashboard/parent_dashboard_page.dart';
import 'activities_provider.dart';
import 'activity_form_page.dart';

class ActivitiesPage extends ConsumerWidget {
  final bool isParent;
  const ActivitiesPage({super.key, this.isParent = false});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return isParent
        ? const _ParentActivitiesView()
        : const TeacherClassSubjectFlowPage(
            mode: TeacherClassFlowMode.activities,
          );
  }
}

class _TeacherActivitiesView extends ConsumerWidget {
  const _TeacherActivitiesView();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final assignmentsAsync = ref.watch(teacherAssignmentsProvider);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.canPop()
              ? context.pop()
              : context.go(RouteNames.teacherDashboard),
        ),
        title: const Text('Activities'),
      ),
      body: assignmentsAsync.when(
        data: (assignments) {
          if (assignments.isEmpty) {
            return const EmptyWidget(
              title: 'No Classes',
              subtitle: 'No class assignments found.',
              icon: Icons.event_note_outlined,
            );
          }

          final seen = <String>{};
          final uniqueByClass =
              assignments.where((a) => seen.add(a.classId)).toList();

          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              const Text('Broadcast Class Log',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
              const SizedBox(height: 4),
              const Text(
                'Share a class update with every active parent in that class.',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
              ),
              const SizedBox(height: 8),
              ...uniqueByClass.map((assignment) => _LogAudienceTile(
                    icon: Icons.campaign_rounded,
                    color: AppColors.success,
                    title: assignment.className,
                    subtitle: 'Broadcast to this class',
                    actionLabel: 'Broadcast',
                    onTap: () async {
                      final saved = await context.push<bool>(
                        RouteNames.teacherActivityAdd,
                        extra: {
                          'classId': assignment.classId,
                          'className': assignment.className,
                          'academicYearId': assignment.academicYearId,
                        },
                      );
                      if (saved == true) {
                        ref.invalidate(
                            classActivitiesProvider(assignment.classId));
                      }
                    },
                  )),
              const SizedBox(height: 20),
              const Text('Student Log',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
              const SizedBox(height: 4),
              const Text(
                'Choose one student to notify only that student\'s parent.',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
              ),
              const SizedBox(height: 8),
              ...uniqueByClass.map((assignment) => _LogAudienceTile(
                    icon: Icons.person_add_alt_1_rounded,
                    color: AppColors.warning,
                    title: assignment.className,
                    subtitle: 'Choose a student',
                    actionLabel: 'Select student',
                    onTap: () => showModalBottomSheet<void>(
                      context: context,
                      showDragHandle: true,
                      builder: (_) => _StudentLogPickerSheet(
                        classId: assignment.classId,
                        className: assignment.className,
                        academicYearId: assignment.academicYearId,
                      ),
                    ),
                  )),
              const SizedBox(height: 28),
              const Text('Recent Class Logs',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              ...uniqueByClass.map((a) {
                final activitiesAsync =
                    ref.watch(classActivitiesProvider(a.classId));
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(a.className,
                            style: const TextStyle(
                                fontWeight: FontWeight.w700, fontSize: 15)),
                        const Text('Broadcasts',
                            style: TextStyle(
                                color: AppColors.textSecondary, fontSize: 12)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    activitiesAsync.when(
                      data: (activities) {
                        if (activities.isEmpty) {
                          return const Padding(
                            padding: EdgeInsets.only(bottom: 16),
                            child: Text('No activities yet',
                                style: TextStyle(
                                    color: AppColors.textSecondary,
                                    fontSize: 13)),
                          );
                        }
                        return Column(
                          children: activities
                              .take(3)
                              .map((act) => _ActivityCard(activity: act))
                              .toList(),
                        );
                      },
                      loading: () => const ShimmerCard(),
                      error: (_, __) => const SizedBox.shrink(),
                    ),
                    const Divider(height: 24),
                  ],
                );
              }),
            ],
          );
        },
        loading: () => const ShimmerList(count: 3),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }
}

class _LogAudienceTile extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final String actionLabel;
  final VoidCallback onTap;

  const _LogAudienceTile({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.actionLabel,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => Card(
        margin: const EdgeInsets.only(bottom: 8),
        child: ListTile(
          leading: CircleAvatar(
            backgroundColor: color.withValues(alpha: 0.12),
            child: Icon(icon, color: color),
          ),
          title:
              Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
          subtitle: Text(subtitle),
          trailing: TextButton(onPressed: onTap, child: Text(actionLabel)),
          onTap: onTap,
        ),
      );
}

class _StudentLogPickerSheet extends ConsumerWidget {
  final String classId;
  final String className;
  final String academicYearId;

  const _StudentLogPickerSheet({
    required this.classId,
    required this.className,
    required this.academicYearId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final studentsAsync = ref.watch(classStudentsListProvider(classId));

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        child: studentsAsync.when(
          data: (students) => Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Select a student',
                  style: Theme.of(context).textTheme.titleLarge),
              Text(className,
                  style: const TextStyle(color: AppColors.textSecondary)),
              const SizedBox(height: 12),
              if (students.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Text('No active students in this class.'),
                )
              else
                SizedBox(
                  height: MediaQuery.sizeOf(context).height * 0.55,
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: students.length,
                    itemBuilder: (_, index) {
                      final student = students[index];
                      return ListTile(
                        leading: const Icon(Icons.person_outline_rounded),
                        title: Text(student.fullName),
                        subtitle: Text(student.studentId),
                        trailing: const Icon(Icons.chevron_right_rounded),
                        onTap: () async {
                          Navigator.pop(context);
                          final saved = await Navigator.of(context).push<bool>(
                            MaterialPageRoute(
                              builder: (_) => ActivityFormPage(
                                classId: classId,
                                className: className,
                                academicYearId: academicYearId,
                                studentId: student.id,
                                studentName: student.fullName,
                              ),
                            ),
                          );
                          if (saved == true) {
                            ref.invalidate(studentLogsProvider(student.id));
                          }
                        },
                      );
                    },
                  ),
                ),
            ],
          ),
          loading: () => const SizedBox(
              height: 160, child: Center(child: CircularProgressIndicator())),
          error: (error, _) => SizedBox(
            height: 160,
            child: Center(child: Text('Unable to load students: $error')),
          ),
        ),
      ),
    );
  }
}

class _ParentActivitiesView extends ConsumerWidget {
  const _ParentActivitiesView();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final childrenAsync = ref.watch(parentChildrenProvider);
    final selectedIndex = ref.watch(selectedChildIndexProvider);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.canPop()
              ? context.pop()
              : context.go(RouteNames.parentDashboard),
        ),
        title: const Text('Activities'),
      ),
      body: childrenAsync.when(
        data: (children) {
          if (children.isEmpty) {
            return const EmptyWidget(
                title: 'No Students', icon: Icons.child_care_rounded);
          }
          final child = children.length > selectedIndex
              ? children[selectedIndex]
              : children.first;
          final activitiesAsync =
              ref.watch(studentActivitiesProvider(child.studentId));

          return activitiesAsync.when(
            data: (activities) {
              if (activities.isEmpty) {
                return const EmptyWidget(
                  title: 'No Activities',
                  subtitle: 'School activities will appear here.',
                  icon: Icons.event_note_outlined,
                );
              }
              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: activities.length,
                itemBuilder: (_, i) => _ActivityCard(activity: activities[i]),
              );
            },
            loading: () => const ShimmerList(count: 4),
            error: (e, _) => Center(child: Text('Error: $e')),
          );
        },
        loading: () => const LoadingWidget(),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }
}

class _ActivityCard extends StatelessWidget {
  final Activity activity;
  const _ActivityCard({required this.activity});

  @override
  Widget build(BuildContext context) {
    final (color, icon) = _typeData(activity.activityType);
    return AppCard(
      padding: const EdgeInsets.all(14),
      onTap: () => _showDetail(context),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(activity.title,
                    style: const TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 14),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        activity.activityType.toUpperCase(),
                        style: TextStyle(
                            fontSize: 9,
                            color: color,
                            fontWeight: FontWeight.w700),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      DateFormat('MMM d, yyyy').format(activity.activityDate),
                      style: const TextStyle(
                          color: AppColors.textSecondary, fontSize: 12),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (activity.location != null)
            Row(
              children: [
                const Icon(Icons.location_on_outlined,
                    size: 12, color: AppColors.textHint),
                Text(activity.location!,
                    style: const TextStyle(
                        fontSize: 11, color: AppColors.textHint)),
              ],
            ),
        ],
      ),
    );
  }

  (Color, IconData) _typeData(String type) {
    return switch (type.toLowerCase()) {
      'sports' => (AppColors.success, Icons.sports_rounded),
      'club' => (AppColors.secondary, Icons.groups_rounded),
      'field_trip' || 'field trip' => (
          AppColors.info,
          Icons.directions_bus_rounded
        ),
      'competition' => (AppColors.warning, Icons.emoji_events_rounded),
      'event' => (AppColors.primary, Icons.celebration_rounded),
      'assignment' => (AppColors.secondary, Icons.assignment_rounded),
      'behavior' => (AppColors.warning, Icons.psychology_rounded),
      'participation' => (AppColors.success, Icons.record_voice_over_rounded),
      _ => (AppColors.primary, Icons.event_note_rounded),
    };
  }

  void _showDetail(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.5,
        maxChildSize: 0.85,
        builder: (_, ctrl) => SingleChildScrollView(
          controller: ctrl,
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(activity.title,
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.calendar_today_outlined,
                      size: 14, color: AppColors.textSecondary),
                  const SizedBox(width: 6),
                  Text(
                      DateFormat('EEEE, MMMM d, yyyy')
                          .format(activity.activityDate),
                      style: const TextStyle(
                          color: AppColors.textSecondary, fontSize: 13)),
                ],
              ),
              if (activity.location != null) ...[
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.location_on_outlined,
                        size: 14, color: AppColors.textSecondary),
                    const SizedBox(width: 6),
                    Text(activity.location!,
                        style: const TextStyle(
                            color: AppColors.textSecondary, fontSize: 13)),
                  ],
                ),
              ],
              const Divider(height: 24),
              if (activity.description != null)
                Text(activity.description!,
                    style: const TextStyle(fontSize: 14, height: 1.6)),
              Row(
                children: [
                  const Icon(Icons.person_outline_rounded,
                      size: 14, color: AppColors.textHint),
                  const SizedBox(width: 6),
                  Text('Organized by ${activity.organizerName}',
                      style: const TextStyle(
                          color: AppColors.textHint, fontSize: 12)),
                ],
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}
