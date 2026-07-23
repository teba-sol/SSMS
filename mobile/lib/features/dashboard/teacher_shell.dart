import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/router/route_names.dart';
import '../../core/theme/app_colors.dart';
import '../notifications/notifications_provider.dart';
import '../messages/messages_provider.dart';

class TeacherShell extends ConsumerStatefulWidget {
  final Widget child;
  const TeacherShell({super.key, required this.child});

  @override
  ConsumerState<TeacherShell> createState() => _TeacherShellState();
}

class _TeacherShellState extends ConsumerState<TeacherShell> {
  int _currentIndex = 0;

  final _tabs = [
    (RouteNames.teacherDashboard, Icons.dashboard_rounded, Icons.dashboard_outlined, 'Home'),
    (RouteNames.teacherAttendance, Icons.fact_check_rounded, Icons.fact_check_outlined, 'Attendance'),
    (RouteNames.teacherResults, Icons.bar_chart_rounded, Icons.bar_chart_outlined, 'Results'),
    (RouteNames.teacherMessages, Icons.chat_bubble_rounded, Icons.chat_bubble_outline_rounded, 'Messages'),
    (RouteNames.teacherStudents, Icons.people_rounded, Icons.people_outline_rounded, 'Students'),
  ];

  void _onTap(int index) {
    setState(() => _currentIndex = index);
    context.go(_tabs[index].$1);
  }

  int _indexFromLocation(String location) {
    for (int i = 0; i < _tabs.length; i++) {
      if (location.startsWith(_tabs[i].$1)) return i;
    }
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final unreadNotif = ref.watch(unreadNotificationsCountProvider);
    final unreadMsg = ref.watch(unreadMessagesCountProvider);

    // Sync active tab with current route
    final location = GoRouterState.of(context).matchedLocation;
    final routeIndex = _indexFromLocation(location);
    if (routeIndex != _currentIndex) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() => _currentIndex = routeIndex);
      });
    }

    return Scaffold(
      body: PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, _) {
          if (didPop) return;
          if (_currentIndex != 0) {
            setState(() => _currentIndex = 0);
            context.go(RouteNames.teacherDashboard);
          }
          // On dashboard — do nothing, don't exit
        },
        child: widget.child,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).bottomNavigationBarTheme.backgroundColor,
          boxShadow: [
            BoxShadow(
              color: AppColors.border.withValues(alpha: 0.8),
              blurRadius: 12,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          child: SizedBox(
            height: 64,
            child: Row(
              children: List.generate(_tabs.length, (i) {
                final (_, activeIcon, inactiveIcon, label) = _tabs[i];
                final isActive = _currentIndex == i;
                final hasBadge = i == 3 && (unreadMsg + unreadNotif) > 0;

                return Expanded(
                  child: GestureDetector(
                    onTap: () => _onTap(i),
                    behavior: HitTestBehavior.opaque,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Stack(
                          clipBehavior: Clip.none,
                          children: [
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: isActive
                                    ? AppColors.primaryLight
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                isActive ? activeIcon : inactiveIcon,
                                color: isActive
                                    ? AppColors.primary
                                    : AppColors.textHint,
                                size: 22,
                              ),
                            ),
                            if (hasBadge)
                              Positioned(
                                right: 6,
                                top: 2,
                                child: Container(
                                  width: 8,
                                  height: 8,
                                  decoration: const BoxDecoration(
                                    color: AppColors.error,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          label,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: isActive
                                ? FontWeight.w600
                                : FontWeight.w400,
                            color: isActive
                                ? AppColors.primary
                                : AppColors.textHint,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ),
        ),
      ),
    );
  }
}
