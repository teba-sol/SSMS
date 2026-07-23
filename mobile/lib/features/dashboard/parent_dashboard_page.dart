import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../core/router/route_names.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/stat_card.dart';
import '../../core/widgets/loading_widget.dart';
import '../auth/auth_provider.dart';
import '../students/students_provider.dart';
import '../results/results_provider.dart';
import '../attendance/attendance_provider.dart';
import '../notifications/notifications_provider.dart';
import '../../models/attendance_model.dart';
import '../../models/parent_model.dart';

// State for selected child index
final selectedChildIndexProvider = StateProvider<int>((ref) => 0);

class ParentDashboardPage extends ConsumerWidget {
  const ParentDashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(currentProfileProvider);
    final childrenAsync = ref.watch(parentChildrenProvider);
    final unreadNotif = ref.watch(unreadNotificationsCountProvider);
    final selectedIndex = ref.watch(selectedChildIndexProvider);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // Header
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            backgroundColor: Colors.transparent,
            elevation: 0,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: AppColors.parentGradient,
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
                                      profile?.firstName.substring(0, 1).toUpperCase() ?? 'P',
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
                                        'Hello, ${profile?.firstName ?? 'Parent'}',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w700,
                                          fontSize: 16,
                                        ),
                                      ),
                                      Text(
                                        DateFormat('EEE, MMM d').format(DateTime.now()),
                                        style: const TextStyle(color: Colors.white70, fontSize: 12),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              Stack(
                                children: [
                                  IconButton(
                                    onPressed: () => context.go(RouteNames.parentNotifications),
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
                                          '$unreadNotif',
                                          style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w700),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          // Child switcher
                          childrenAsync.when(
                            data: (children) {
                              if (children.isEmpty) return const SizedBox.shrink();
                              return SizedBox(
                                height: 44,
                                child: ListView.builder(
                                  scrollDirection: Axis.horizontal,
                                  itemCount: children.length,
                                  itemBuilder: (ctx, i) {
                                    final child = children[i];
                                    final isSelected = i == selectedIndex;
                                    return GestureDetector(
                                      onTap: () => ref.read(selectedChildIndexProvider.notifier).state = i,
                                      child: AnimatedContainer(
                                        duration: const Duration(milliseconds: 200),
                                        margin: const EdgeInsets.only(right: 8),
                                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                        decoration: BoxDecoration(
                                          color: isSelected ? Colors.white : Colors.white.withValues(alpha: 0.2),
                                          borderRadius: BorderRadius.circular(22),
                                        ),
                                        child: Text(
                                          child.student?.firstName ?? 'Child ${i + 1}',
                                          style: TextStyle(
                                            color: isSelected ? AppColors.secondary : Colors.white,
                                            fontWeight: FontWeight.w600,
                                            fontSize: 13,
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              );
                            },
                            loading: () => const SizedBox.shrink(),
                            error: (_, __) => const SizedBox.shrink(),
                          ),
                        ],
                      ),
                  ),
                ),
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: childrenAsync.when(
              data: (children) {
                if (children.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.all(40),
                    child: Center(
                      child: Text(
                        'No students linked to your account.\nPlease contact the school administrator.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                    ),
                  );
                }
                final selectedChild = children.length > selectedIndex
                    ? children[selectedIndex]
                    : children.first;
                return _ChildDashboard(child: selectedChild);
              },
              loading: () => const Padding(
                padding: EdgeInsets.all(20),
                child: ShimmerList(count: 4, itemHeight: 80),
              ),
              error: (e, _) => Padding(
                padding: const EdgeInsets.all(20),
                child: Text('Error: $e'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ChildDashboard extends ConsumerWidget {
  final ParentStudent child;
  const _ChildDashboard({required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final studentId = child.studentId;
    final resultsAsync = ref.watch(studentResultsProvider(studentId));
    final attendanceAsync = ref.watch(studentAttendanceProvider(studentId));
    final attendanceSummaryAsync =
        ref.watch(studentAttendanceSummaryProvider(studentId));

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Student info card
          _StudentInfoCard(child: child),
          const SizedBox(height: 20),

          // Stats row
          attendanceSummaryAsync.when(
            data: (summary) {
              final total = summary.values.fold(0, (a, b) => a + b);
              final present = summary['present'] ?? 0;
              final rate = total > 0 ? (present / total * 100).toStringAsFixed(0) : '0';
              return GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.1,
                children: [
                  StatCard(
                    title: 'Attendance Rate',
                    value: '$rate%',
                    icon: Icons.check_circle_outline_rounded,
                    color: AppColors.attendancePresent,
                    subtitle: '$present/$total days',
                    onTap: () => context.go(RouteNames.parentAttendance),
                  ),
                  StatCard(
                    title: 'Absent Days',
                    value: '${summary['absent'] ?? 0}',
                    icon: Icons.cancel_outlined,
                    color: AppColors.attendanceAbsent,
                    onTap: () => context.go(RouteNames.parentAttendance),
                  ),
                  resultsAsync.when(
                    data: (results) {
                      final avg = results.isNotEmpty && results.any((r) => r.percentage != null)
                          ? (results
                                  .where((r) => r.percentage != null)
                                  .map((r) => r.percentage!)
                                  .reduce((a, b) => a + b) /
                              results.where((r) => r.percentage != null).length)
                          : 0.0;
                      return StatCard(
                        title: 'Avg. Score',
                        value: '${avg.toStringAsFixed(0)}%',
                        icon: Icons.school_rounded,
                        color: AppColors.secondary,
                        onTap: () => context.go(RouteNames.parentResults),
                      );
                    },
                    loading: () => StatCard(
                      title: 'Avg. Score',
                      value: '—',
                      icon: Icons.school_rounded,
                      color: AppColors.secondary,
                    ),
                    error: (_, __) => StatCard(
                      title: 'Avg. Score',
                      value: '—',
                      icon: Icons.school_rounded,
                      color: AppColors.secondary,
                    ),
                  ),
                  StatCard(
                    title: 'Late Days',
                    value: '${summary['late'] ?? 0}',
                    icon: Icons.access_time_rounded,
                    color: AppColors.attendanceLate,
                  ),
                ],
              );
            },
            loading: () => const ShimmerList(count: 1, itemHeight: 180),
            error: (_, __) => const SizedBox.shrink(),
          ),
          const SizedBox(height: 24),

          // Quick Actions
          const Text('Quick Actions',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          _ParentQuickActions(studentId: studentId),
          const SizedBox(height: 24),

          // Recent attendance
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Recent Attendance',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
              TextButton(
                onPressed: () => context.go(RouteNames.parentAttendance),
                child: const Text('View All'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          attendanceAsync.when(
            data: (records) {
              if (records.isEmpty) {
                return const Text('No attendance records',
                    style: TextStyle(color: AppColors.textSecondary));
              }
              return Column(
                children: records.take(5).map((a) {
                  final (color, bg) = switch (a.status.value) {
                    'present' => (AppColors.attendancePresent, AppColors.attendancePresentLight),
                    'absent' => (AppColors.attendanceAbsent, AppColors.attendanceAbsentLight),
                    'late' => (AppColors.attendanceLate, AppColors.attendanceLateLight),
                    _ => (AppColors.attendanceExcused, AppColors.attendanceExcusedLight),
                  };
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: bg,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.circle, size: 8, color: color),
                        const SizedBox(width: 10),
                        Text(
                          DateFormat('EEE, MMM d').format(a.date),
                          style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
                        ),
                        const Spacer(),
                        Text(
                          a.status.label,
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                            color: color,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              );
            },
            loading: () => const ShimmerList(count: 3, itemHeight: 52),
            error: (_, __) => const SizedBox.shrink(),
          ),
          const SizedBox(height: 80),
        ],
      ),
    );
  }
}

class _StudentInfoCard extends StatelessWidget {
  final ParentStudent child;
  const _StudentInfoCard({required this.child});

  @override
  Widget build(BuildContext context) {
    final student = child.student;
    if (student == null) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF7C3AED), Color(0xFF9333EA)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: Colors.white.withValues(alpha: 0.2),
            child: Text(
              student.firstName.substring(0, 1).toUpperCase(),
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 20,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  student.fullName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
                Text(
                  'ID: ${student.studentId}',
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
                Text(
                  child.relationship.label,
                  style: const TextStyle(color: Colors.white60, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ParentQuickActions extends StatelessWidget {
  final String studentId;
  const _ParentQuickActions({required this.studentId});

  @override
  Widget build(BuildContext context) {
    final actions = [
      (Icons.bar_chart_rounded, 'Results', AppColors.secondary,
          const LinearGradient(colors: [Color(0xFF7C3AED), Color(0xFF6D28D9)]),
          RouteNames.parentResults),
      (Icons.calendar_month_rounded, 'Attendance', AppColors.primary,
          const LinearGradient(colors: [Color(0xFF2563EB), Color(0xFF1D4ED8)]),
          RouteNames.parentAttendance),
      (Icons.chat_bubble_rounded, 'Message\nTeacher', AppColors.success,
          const LinearGradient(colors: [Color(0xFF16A34A), Color(0xFF15803D)]),
          RouteNames.parentMessages),
      (Icons.support_agent_rounded, 'Contact\nAdmin', AppColors.warning,
          const LinearGradient(colors: [Color(0xFFEA580C), Color(0xFFDC2626)]),
          RouteNames.parentMessages),
    ];
    return Row(
      children: actions.map((a) {
        return Expanded(
          child: GestureDetector(
            onTap: () => context.go(a.$5),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                gradient: a.$4,
                borderRadius: BorderRadius.circular(14),
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
                  Icon(a.$1, color: Colors.white, size: 22),
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
