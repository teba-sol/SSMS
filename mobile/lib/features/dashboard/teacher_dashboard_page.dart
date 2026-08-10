import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../core/router/route_names.dart';
import '../../core/theme/app_colors.dart';
import '../../core/localization/app_localizations.dart';
import '../../core/widgets/stat_card.dart';
import '../../core/widgets/loading_widget.dart';
import '../../core/widgets/app_card.dart';
import '../../models/teacher_model.dart';
import '../auth/auth_provider.dart';
import '../students/students_provider.dart';
import '../notifications/notifications_provider.dart';
import '../announcements/announcements_provider.dart';

class TeacherDashboardPage extends ConsumerStatefulWidget {
  const TeacherDashboardPage({super.key});

  @override
  ConsumerState<TeacherDashboardPage> createState() =>
      _TeacherDashboardPageState();
}

class _TeacherDashboardPageState extends ConsumerState<TeacherDashboardPage> {
  Future<void> _refresh() async {
    ref.invalidate(currentTeacherProvider);
    ref.invalidate(teacherAssignmentsProvider);
    ref.invalidate(announcementsProvider);
    // Wait for the main data to settle
    await ref
        .read(teacherAssignmentsProvider.future)
        .catchError((_) => <TeacherAssignment>[]);
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(currentProfileProvider);
    final strings = AppLocalizations.of(context);
    final teacherAsync = ref.watch(currentTeacherProvider);
    final assignmentsAsync = ref.watch(teacherAssignmentsProvider);
    final unreadNotif = ref.watch(unreadNotificationsCountProvider);

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: CustomScrollView(
          slivers: [
            // Header
            SliverAppBar(
              expandedHeight: 180,
              pinned: true,
              backgroundColor: Colors.transparent,
              elevation: 0,
              flexibleSpace: FlexibleSpaceBar(
                background: Container(
                  decoration: const BoxDecoration(
                    gradient: AppColors.teacherGradient,
                  ),
                  child: SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  CircleAvatar(
                                    radius: 22,
                                    backgroundColor:
                                        Colors.white.withValues(alpha: 0.2),
                                    child: Text(
                                      profile?.firstName
                                              .substring(0, 1)
                                              .toUpperCase() ??
                                          'T',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w700,
                                        fontSize: 18,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '${strings.isAmharic ? 'እንኳን ደህና መጡ' : 'Good'} ${_greeting()},',
                                        style: const TextStyle(
                                          color: Colors.white70,
                                          fontSize: 13,
                                        ),
                                      ),
                                      Text(
                                        profile?.fullName ?? (strings.isAmharic ? 'መምህር' : 'Teacher'),
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w700,
                                          fontSize: 16,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              Row(
                                children: [
                                  Stack(
                                    children: [
                                      IconButton(
                                        onPressed: () => context.push(
                                            RouteNames.teacherNotifications),
                                        icon: const Icon(
                                            Icons.notifications_outlined,
                                            color: Colors.white),
                                      ),
                                      if (unreadNotif > 0)
                                        Positioned(
                                          right: 8,
                                          top: 8,
                                          child: Container(
                                            padding: const EdgeInsets.all(2),
                                            decoration: const BoxDecoration(
                                              color: AppColors.error,
                                              shape: BoxShape.circle,
                                            ),
                                            child: Text(
                                              unreadNotif > 9
                                                  ? '9+'
                                                  : '$unreadNotif',
                                              style: const TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 9,
                                                  fontWeight: FontWeight.w700),
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                  IconButton(
                                    onPressed: _refresh,
                                    icon: const Icon(Icons.refresh_rounded,
                                        color: Colors.white),
                                    tooltip: strings.isAmharic ? 'አድስ' : 'Refresh',
                                  ),
                                  IconButton(
                                    onPressed: () =>
                                        context.push(RouteNames.settings),
                                    icon: const Icon(Icons.settings_outlined,
                                        color: Colors.white),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            DateFormat('EEEE, MMMM d').format(DateTime.now()),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          teacherAsync.when(
                            data: (t) => Text(
                              t?.department != null
                                  ? '${t!.department} • ${t.employeeId}'
                                  : t?.employeeId ?? '',
                              style: const TextStyle(
                                  color: Colors.white70, fontSize: 12),
                            ),
                            loading: () => const SizedBox.shrink(),
                            error: (_, __) => const SizedBox.shrink(),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              actions: const [SizedBox(width: 8)],
            ),

            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Quick actions
                    _QuickActionsRow(),
                    const SizedBox(height: 24),

                    // My Classes
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(strings.myClasses,
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.w700)),
                        TextButton(
                          onPressed: () =>
                              context.go(RouteNames.teacherClasses),
                          child: Text(strings.viewAll),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    assignmentsAsync.when(
                      data: (assignments) {
                        if (assignments.isEmpty) {
                          return Text(strings.noClassesAssigned,
                              style: TextStyle(color: AppColors.textSecondary));
                        }
                        final recentClasses = assignments.take(2).toList();
                        return Column(
                          children: recentClasses.map((a) {
                            return _ClassCard(
                              assignment: a,
                            );
                          }).toList(),
                        );
                      },
                      loading: () =>
                          const ShimmerList(count: 2, itemHeight: 100),
                      error: (e, _) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Row(
                          children: [
                            const Icon(Icons.error_outline,
                                color: AppColors.error, size: 16),
                            const SizedBox(width: 8),
                            const Expanded(
                                child: Text('Failed to load classes',
                                    style: TextStyle(
                                        color: AppColors.error, fontSize: 13))),
                            TextButton(
                                onPressed: _refresh,
                                child: const Text('Retry')),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Today's Summary
                    Text(strings.isAmharic ? 'የዛሬ ማጠቃለያ' : 'Today\'s Summary',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 12),
                    assignmentsAsync.when(
                      data: (assignments) {
                        final classIds =
                            assignments.map((a) => a.classId).toSet().length;
                        final subjects = assignments.length;
                        return GridView.count(
                          crossAxisCount: 2,
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          childAspectRatio: 1.1,
                          children: [
                            StatCard(
                              title: strings.classes,
                              value: '$classIds',
                              icon: Icons.class_,
                              color: AppColors.primary,
                              onTap: () =>
                                  context.go(RouteNames.teacherClasses),
                            ),
                            StatCard(
                              title: strings.subjects,
                              value: '$subjects',
                              icon: Icons.book_outlined,
                              color: AppColors.secondary,
                              onTap: () =>
                                  context.go(RouteNames.teacherClasses),
                            ),
                            StatCard(
                              title: strings.messages,
                              value: '—',
                              icon: Icons.chat_bubble_outline_rounded,
                              color: AppColors.accent,
                              onTap: () =>
                                  context.go(RouteNames.teacherMessages),
                            ),
                            StatCard(
                              title: strings.notifications,
                              value: '$unreadNotif',
                              icon: Icons.notifications_outlined,
                              color: unreadNotif > 0
                                  ? AppColors.warning
                                  : AppColors.success,
                              subtitle: unreadNotif > 0 ? strings.unread : strings.allRead,
                              onTap: () =>
                                  context.push(RouteNames.teacherNotifications),
                            ),
                          ],
                        );
                      },
                      loading: () =>
                          const ShimmerList(count: 1, itemHeight: 180),
                      error: (_, __) => const SizedBox.shrink(),
                    ),
                    const SizedBox(height: 24),

                    // Recent announcements
                    _RecentAnnouncements(),
                    const SizedBox(height: 80),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _greeting() {
    final h = DateTime.now().hour;
    if (h < 12) return 'Morning';
    if (h < 17) return 'Afternoon';
    return 'Evening';
  }
}

class _QuickActionsRow extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Row 1: Primary actions
    final row1 = [
      (
        Icons.fact_check_rounded,
        'Mark\nAttend',
        AppColors.primary,
        const LinearGradient(colors: [Color(0xFF2563EB), Color(0xFF1D4ED8)]),
        RouteNames.teacherAttendance
      ),
      (
        Icons.add_chart_rounded,
        'Add\nResult',
        AppColors.secondary,
        const LinearGradient(colors: [Color(0xFF7C3AED), Color(0xFF6D28D9)]),
        RouteNames.teacherResults
      ),
      (
        Icons.event_note_rounded,
        'Log\nActivity',
        AppColors.success,
        const LinearGradient(colors: [Color(0xFF16A34A), Color(0xFF15803D)]),
        null
      ),
      (
        Icons.campaign_rounded,
        'Announce',
        AppColors.warning,
        const LinearGradient(colors: [Color(0xFFEA580C), Color(0xFFDC2626)]),
        RouteNames.teacherAnnouncements
      ),
    ];

    Widget actionButton(IconData icon, String label, Color color,
        LinearGradient grad, String? route) {
      return Expanded(
        child: GestureDetector(
          onTap: () {
            if (route != null) {
              context.go(route);
            } else {
              _showActivityModePicker(context, ref);
            }
          },
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 4),
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(
              gradient: grad,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.25),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              children: [
                Icon(icon, color: Colors.white, size: 22),
                const SizedBox(height: 5),
                Text(
                  label,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Row(
      children:
          row1.map((a) => actionButton(a.$1, a.$2, a.$3, a.$4, a.$5)).toList(),
    );
  }

  Future<void> _showActivityModePicker(BuildContext context, WidgetRef ref) async {
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
                'Choose log type',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              const Text(
                'Broadcast logs go to all active parents in a class. Student logs go to one specific student\'s parent(s).',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.campaign_rounded, color: AppColors.success),
                title: const Text('Broadcast class log'),
                subtitle: const Text('Send one message to all active parents in a class'),
                onTap: () {
                  Navigator.pop(sheetContext);
                  context.push(RouteNames.teacherActivities);
                },
              ),
              ListTile(
                leading: const Icon(Icons.person_outline_rounded, color: AppColors.warning),
                title: const Text('Single student log'),
                subtitle: const Text('Send a log to one student\'s parent(s) only'),
                onTap: () {
                  Navigator.pop(sheetContext);
                  _showStudentSelectionSheet(context, ref);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showStudentSelectionSheet(BuildContext context, WidgetRef ref) async {
    final assignmentsAsync = ref.read(teacherAssignmentsProvider);
    final assignments = assignmentsAsync.valueOrNull ?? <TeacherAssignment>[];

    if (assignments.isEmpty) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No class assignments available.')),
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
                'Choose a class',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              const Text(
                'Select a class to choose the student for the personal log.',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
              ),
              const SizedBox(height: 12),
              ...assignments.map((assignment) => ListTile(
                    leading: const Icon(Icons.class_rounded, color: AppColors.primary),
                    title: Text(assignment.className),
                    subtitle: Text(assignment.subjectName),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () {
                      Navigator.pop(sheetContext);
                      _showStudentPickerForClass(context, assignment, ref);
                    },
                  )),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showStudentPickerForClass(
    BuildContext context,
    TeacherAssignment assignment,
    WidgetRef ref,
  ) async {
    final studentsAsync = await ref.read(classStudentsListProvider(assignment.classId).future);

    if (!context.mounted) return;

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
              Text(
                'Choose a student for ${assignment.className}',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              const Text(
                'This log will notify only that student\'s parent(s).',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
              ),
              const SizedBox(height: 12),
              if (studentsAsync.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Text('No students are enrolled in this class.'),
                )
              else
                SizedBox(
                  height: MediaQuery.sizeOf(context).height * 0.5,
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: studentsAsync.length,
                    itemBuilder: (_, index) {
                      final student = studentsAsync[index];
                      return ListTile(
                        leading: const Icon(Icons.person_outline_rounded),
                        title: Text(student.fullName),
                        subtitle: Text(student.studentId),
                        onTap: () {
                          Navigator.pop(sheetContext);
                          context.push(RouteNames.teacherActivityAdd, extra: {
                            'classId': assignment.classId,
                            'className': assignment.className,
                            'academicYearId': assignment.academicYearId,
                            'studentId': student.id,
                            'studentName': student.fullName,
                          });
                        },
                      );
                    },
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ClassCard extends StatelessWidget {
  final dynamic assignment;
  const _ClassCard({required this.assignment});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(16),
      onTap: () => context.push(
        RouteNames.teacherClasses,
        extra: {'initialClassId': assignment.classId},
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.class_,
                    color: AppColors.primary, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${assignment.subjectName}/${assignment.className}',
                      style: const TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 15),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios_rounded,
                  size: 14, color: AppColors.textHint),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _pill(Icons.fact_check_outlined, 'Attendance',
                  AppColors.attendancePresent, () {
                context.push(RouteNames.teacherAttendanceMark, extra: {
                  'classId': assignment.classId,
                  'className': assignment.className,
                  'assignmentId': assignment.id,
                });
              }),
              const SizedBox(width: 8),
              _pill(Icons.grade_outlined, 'Results', AppColors.secondary, () {
                context.push(RouteNames.teacherResultAdd, extra: {
                  'assignmentId': assignment.id,
                  'className': assignment.className,
                  'subjectName': assignment.subjectName,
                });
              }),
            ],
          ),
        ],
      ),
    );
  }

  Widget _pill(IconData icon, String label, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 12, color: color),
            const SizedBox(width: 4),
            Text(label,
                style: TextStyle(
                    fontSize: 11, fontWeight: FontWeight.w600, color: color)),
          ],
        ),
      ),
    );
  }
}

class _RecentAnnouncements extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final announcementsState = ref.watch(announcementsProvider);
    final strings = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(strings.announcements,
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            TextButton(
              onPressed: () => context.push(RouteNames.teacherAnnouncements),
              child: Text(strings.viewAll),
            ),
          ],
        ),
        const SizedBox(height: 8),
        announcementsState.when(
          data: (items) {
            if (items.isEmpty) {
              return Text(strings.noAnnouncements,
                  style: TextStyle(color: AppColors.textSecondary));
            }
            return Column(
              children: items.take(2).map((a) => _AnnouncementTile(a)).toList(),
            );
          },
          loading: () => const ShimmerList(count: 2, itemHeight: 72),
          error: (_, __) => const SizedBox.shrink(),
        ),
      ],
    );
  }
}

class _AnnouncementTile extends StatelessWidget {
  final dynamic announcement;
  const _AnnouncementTile(this.announcement);

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(14),
      onTap: () {},
      child: Row(
        children: [
          Container(
            width: 4,
            height: 48,
            decoration: BoxDecoration(
              color: announcement.isRead ? AppColors.border : AppColors.primary,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  announcement.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontWeight:
                        announcement.isRead ? FontWeight.w500 : FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
                Text(
                  announcement.content,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      color: AppColors.textSecondary, fontSize: 12),
                ),
              ],
            ),
          ),
          if (!announcement.isRead)
            Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
              ),
            ),
        ],
      ),
    );
  }
}
