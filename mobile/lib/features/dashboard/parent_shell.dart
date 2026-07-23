import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/router/route_names.dart';
import '../../core/theme/app_colors.dart';
import '../notifications/notifications_provider.dart';
import '../messages/messages_provider.dart';

class ParentShell extends ConsumerStatefulWidget {
  final Widget child;
  const ParentShell({super.key, required this.child});

  @override
  ConsumerState<ParentShell> createState() => _ParentShellState();
}

class _ParentShellState extends ConsumerState<ParentShell> {
  int _currentIndex = 0;

  final _tabs = [
    (RouteNames.parentDashboard, Icons.home_rounded, Icons.home_outlined, 'Home'),
    (RouteNames.parentResults, Icons.bar_chart_rounded, Icons.bar_chart_outlined, 'Results'),
    (RouteNames.parentAttendance, Icons.calendar_month_rounded, Icons.calendar_month_outlined, 'Attendance'),
    (RouteNames.parentMessages, Icons.chat_bubble_rounded, Icons.chat_bubble_outline_rounded, 'Messages'),
    (RouteNames.parentNotifications, Icons.notifications_rounded, Icons.notifications_outlined, 'Alerts'),
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
            context.go(RouteNames.parentDashboard);
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
                final hasBadge = (i == 3 && unreadMsg > 0) ||
                    (i == 4 && unreadNotif > 0);

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
                                    ? AppColors.secondaryLight
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                isActive ? activeIcon : inactiveIcon,
                                color: isActive
                                    ? AppColors.secondary
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
                                ? AppColors.secondary
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
