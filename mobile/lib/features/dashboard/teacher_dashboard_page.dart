import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../core/router/route_names.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/stat_card.dart';
import '../../core/widgets/loading_widget.dart';
import '../../core/widgets/app_card.dart';
import '../auth/auth_provider.dart';
import '../students/students_provider.dart';
import '../notifications/notifications_provider.dart';
import '../announcements/announcements_provider.dart';

class TeacherDashboardPage extends ConsumerWidget {
  const TeacherDashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(currentProfileProvider);
    final teacherAsync = ref.watch(currentTeacherProvider);
    final assignmentsAsync = ref.watch(teacherAssignmentsProvider);
    final unreadNotif = ref.watch(unreadNotificationsCountProvider);

    return Scaffold(
      body: CustomScrollView(
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
                                    backgroundColor: Colors.white.withValues(alpha: 0.2),
                                    child: Text(
                                      profile?.firstName.substring(0, 1).toUpperCase() ?? 'T',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w700,
                                        fontSize: 18,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Good ${_greeting()},',
                                        style: const TextStyle(
                                          color: Colors.white70,
                                          fontSize: 13,
                                        ),
                                      ),
                                      Text(
                                        profile?.fullName ?? 'Teacher',
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
                                        onPressed: () => context.push(RouteNames.teacherNotifications),
                                        icon: const Icon(Icons.notifications_outlined, color: Colors.white),
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
                                              unreadNotif > 9 ? '9+' : '$unreadNotif',
                                              style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w700),
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                  IconButton(
                                    onPressed: () => context.push(RouteNames.settings),
                                    icon: const Icon(Icons.settings_outlined, color: Colors.white),
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
                              t?.department != null ? '${t!.department} • ${t.employeeId}' : t?.employeeId ?? '',
                              style: const TextStyle(color: Colors.white70, fontSize: 12),
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
                      const Text('My Classes',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                      TextButton(
                        onPressed: () => context.go(RouteNames.teacherStudents),
                        child: const Text('View All'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  assignmentsAsync.when(
                    data: (assignments) {
                      if (assignments.isEmpty) {
                        return const Text('No classes assigned',
                            style: TextStyle(color: AppColors.textSecondary));
                      }
                      // Group by class
                      final byClass = <String, List<dynamic>>{};
                      for (final a in assignments) {
                        byClass.putIfAbsent(a.classId, () => []).add(a);
                      }
                      return Column(
                        children: byClass.entries.take(3).map((e) {
                          final first = e.value.first;
                          return _ClassCard(
                            assignment: first,
                            subjectCount: e.value.length,
                          );
                        }).toList(),
                      );
                    },
                    loading: () => const ShimmerList(count: 2, itemHeight: 100),
                    error: (e, _) => Text('$e'),
                  ),
                  const SizedBox(height: 24),

                  // Today's Summary
                  const Text('Today\'s Summary',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 12),
                  assignmentsAsync.when(
                    data: (assignments) {
                      final classIds = assignments.map((a) => a.classId).toSet().length;
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
                            title: 'Classes',
                            value: '$classIds',
                            icon: Icons.class_,
                            color: AppColors.primary,
                            onTap: () => context.go(RouteNames.teacherStudents),
                          ),
                          StatCard(
                            title: 'Subjects',
                            value: '$subjects',
                            icon: Icons.book_outlined,
                            color: AppColors.secondary,
                          ),
                          StatCard(
                            title: 'Messages',
                            value: '—',
                            icon: Icons.chat_bubble_outline_rounded,
                            color: AppColors.accent,
                            onTap: () => context.go(RouteNames.teacherMessages),
                          ),
                          StatCard(
                            title: 'Notifications',
                            value: '$unreadNotif',
                            icon: Icons.notifications_outlined,
                            color: unreadNotif > 0 ? AppColors.warning : AppColors.success,
                            subtitle: unreadNotif > 0 ? 'Unread' : 'All read',
                            onTap: () => context.push(RouteNames.teacherNotifications),
                          ),
                        ],
                      );
                    },
                    loading: () => const ShimmerList(count: 1, itemHeight: 180),
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
    final actions = [
      (Icons.fact_check_rounded, 'Mark\nAttendance', AppColors.primary,
          const LinearGradient(colors: [Color(0xFF2563EB), Color(0xFF1D4ED8)]),
          RouteNames.teacherAttendance),
      (Icons.add_chart_rounded, 'Add\nResult', AppColors.secondary,
          const LinearGradient(colors: [Color(0xFF7C3AED), Color(0xFF6D28D9)]),
          RouteNames.teacherResults),
      (Icons.event_note_rounded, 'Log\nActivity', AppColors.success,
          const LinearGradient(colors: [Color(0xFF16A34A), Color(0xFF15803D)]),
          RouteNames.teacherActivities),
      (Icons.campaign_rounded, 'Announce', AppColors.warning,
          const LinearGradient(colors: [Color(0xFFEA580C), Color(0xFFDC2626)]),
          RouteNames.teacherAnnouncements),
    ];
    return Row(
      children: actions.map((a) {
        return Expanded(
          child: GestureDetector(
            onTap: () => context.go(a.$5),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                gradient: a.$4,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: a.$3.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Icon(a.$1, color: Colors.white, size: 24),
                  const SizedBox(height: 6),
                  Text(
                    a.$2,
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
      }).toList(),
    );
  }
}

class _ClassCard extends StatelessWidget {
  final dynamic assignment;
  final int subjectCount;
  const _ClassCard({required this.assignment, required this.subjectCount});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(16),
      onTap: () => context.go(RouteNames.teacherAttendance),
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
                child: Icon(Icons.class_,
                    color: AppColors.primary, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      assignment.className,
                      style: const TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 15),
                    ),
                    Text(
                      '$subjectCount ${subjectCount == 1 ? 'subject' : 'subjects'}',
                      style: const TextStyle(
                          color: AppColors.textSecondary, fontSize: 12),
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

  Widget _pill(
      IconData icon, String label, Color color, VoidCallback onTap) {
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
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: color)),
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Announcements',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            TextButton(
              onPressed: () => context.push(RouteNames.teacherAnnouncements),
              child: const Text('View All'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        announcementsState.when(
          data: (items) {
            if (items.isEmpty) {
              return const Text('No announcements',
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
                    fontWeight: announcement.isRead
                        ? FontWeight.w500
                        : FontWeight.w700,
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
