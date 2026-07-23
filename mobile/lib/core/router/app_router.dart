import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../models/profile_model.dart';
import '../../features/auth/auth_model.dart';
import '../../features/auth/auth_page.dart';
import '../../features/auth/auth_provider.dart';
import '../../features/auth/forgot_password_page.dart';
import '../../features/auth/reset_password_page.dart';
import '../../features/dashboard/teacher_shell.dart';
import '../../features/dashboard/parent_shell.dart';
import '../../features/dashboard/teacher_dashboard_page.dart';
import '../../features/dashboard/parent_dashboard_page.dart';
import '../../features/attendance/attendance_page.dart';
import '../../features/attendance/attendance_mark_page.dart';
import '../../features/results/results_page.dart';
import '../../features/results/result_form_page.dart';
import '../../features/activities/activities_page.dart';
import '../../features/activities/activity_form_page.dart';
import '../../features/messages/messages_page.dart';
import '../../features/messages/chat_page.dart';
import '../../features/notifications/notifications_page.dart';
import '../../features/announcements/announcements_page.dart';
import '../../features/announcements/announcement_form_page.dart';
import '../../features/students/students_page.dart';
import '../../features/students/student_detail_page.dart';
import '../../features/settings/settings_page.dart';
import 'route_names.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final navigatorKey = GlobalKey<NavigatorState>();
  final routerNotifier = _RouterNotifier();

  // Notify router whenever auth state changes (includes profile)
  ref.listen<AuthState>(authProvider, (_, next) {
    routerNotifier.notify();
  });

  return GoRouter(
    navigatorKey: navigatorKey,
    initialLocation: RouteNames.login,
    debugLogDiagnostics: false,
    refreshListenable: routerNotifier,
    redirect: (context, state) {
      final authState = ref.read(authProvider);
      final isLoggedIn = authState.isAuthenticated;
      final isLoading = authState.isLoading;
      final loc = state.matchedLocation;

      final authRoutes = [
        RouteNames.login,
        RouteNames.forgotPassword,
        RouteNames.resetPassword,
      ];

      // Still initializing — don't redirect yet
      if (isLoading) return null;

      // Not logged in — send to login
      if (!isLoggedIn && !authRoutes.contains(loc)) {
        return RouteNames.login;
      }

      // Logged in and on an auth page — redirect to dashboard
      if (isLoggedIn && authRoutes.contains(loc)) {
        final profile = ref.read(currentProfileProvider) ?? authState.profile;
        if (profile == null) return null; // profile not loaded yet
        switch (profile.role) {
          case UserRole.teacher:
          case UserRole.administrator:
            return RouteNames.teacherDashboard;
          case UserRole.parent:
            return RouteNames.parentDashboard;
        }
      }

      return null;
    },
    routes: [
      // ── Auth ──────────────────────────────────────────────
      GoRoute(
        path: RouteNames.login,
        builder: (_, __) => const AuthPage(),
      ),
      GoRoute(
        path: RouteNames.forgotPassword,
        builder: (_, __) => const ForgotPasswordPage(),
      ),
      GoRoute(
        path: RouteNames.resetPassword,
        builder: (_, __) => const ResetPasswordPage(),
      ),

      // ── Teacher Shell ─────────────────────────────────────
      ShellRoute(
        builder: (context, state, child) => TeacherShell(child: child),
        routes: [
          GoRoute(
            path: RouteNames.teacherDashboard,
            builder: (_, __) => const TeacherDashboardPage(),
          ),
          GoRoute(
            path: RouteNames.teacherAttendance,
            builder: (_, __) => const AttendancePage(),
          ),
          GoRoute(
            path: RouteNames.teacherResults,
            builder: (_, __) => const ResultsPage(),
          ),
          GoRoute(
            path: RouteNames.teacherMessages,
            builder: (_, __) => const MessagesPage(),
          ),
          GoRoute(
            path: RouteNames.teacherStudents,
            builder: (_, __) => const StudentsPage(),
          ),
        ],
      ),

      // ── Teacher Overlay Pages ─────────────────────────────
      GoRoute(
        path: RouteNames.teacherAttendanceMark,
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          return AttendanceMarkPage(
            classId: extra?['classId'] ?? '',
            className: extra?['className'] ?? '',
            assignmentId: extra?['assignmentId'] ?? '',
          );
        },
      ),
      GoRoute(
        path: RouteNames.teacherResultAdd,
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          return ResultFormPage(
            assignmentId: extra?['assignmentId'] ?? '',
            className: extra?['className'] ?? '',
            subjectName: extra?['subjectName'] ?? '',
          );
        },
      ),
      GoRoute(
        path: RouteNames.teacherActivityAdd,
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          return ActivityFormPage(
            classId: extra?['classId'],
            className: extra?['className'] ?? 'School Wide',
            academicYearId: extra?['academicYearId'] ?? '',
          );
        },
      ),
      GoRoute(
        path: RouteNames.teacherChat,
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          return ChatPage(
            conversationId: extra?['conversationId'] ?? '',
            otherUserId: extra?['otherUserId'] ?? '',
            otherUserName: extra?['otherUserName'] ?? 'Chat',
            otherUserRole: extra?['otherUserRole'] ?? '',
          );
        },
      ),
      GoRoute(
        path: RouteNames.teacherNotifications,
        builder: (_, __) => const NotificationsPage(),
      ),
      GoRoute(
        path: RouteNames.teacherAnnouncements,
        builder: (_, __) => const AnnouncementsPage(),
      ),
      GoRoute(
        path: RouteNames.teacherAnnouncementAdd,
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          return AnnouncementFormPage(
            classId: extra?['classId'],
            className: extra?['className'],
          );
        },
      ),
      GoRoute(
        path: RouteNames.teacherStudentDetail,
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          return StudentDetailPage(
            studentId: extra?['studentId'] ?? '',
            studentName: extra?['studentName'] ?? '',
          );
        },
      ),
      GoRoute(
        path: RouteNames.teacherActivities,
        builder: (_, __) => const ActivitiesPage(),
      ),

      // ── Parent Shell ──────────────────────────────────────
      ShellRoute(
        builder: (context, state, child) => ParentShell(child: child),
        routes: [
          GoRoute(
            path: RouteNames.parentDashboard,
            builder: (_, __) => const ParentDashboardPage(),
          ),
          GoRoute(
            path: RouteNames.parentResults,
            builder: (_, __) => const ResultsPage(isParent: true),
          ),
          GoRoute(
            path: RouteNames.parentAttendance,
            builder: (_, __) => const AttendancePage(isParent: true),
          ),
          GoRoute(
            path: RouteNames.parentMessages,
            builder: (_, __) => const MessagesPage(isParent: true),
          ),
          GoRoute(
            path: RouteNames.parentNotifications,
            builder: (_, __) => const NotificationsPage(),
          ),
        ],
      ),

      // ── Parent Overlay Pages ──────────────────────────────
      GoRoute(
        path: RouteNames.parentChat,
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          return ChatPage(
            conversationId: extra?['conversationId'] ?? '',
            otherUserId: extra?['otherUserId'] ?? '',
            otherUserName: extra?['otherUserName'] ?? 'Chat',
            otherUserRole: extra?['otherUserRole'] ?? '',
          );
        },
      ),
      GoRoute(
        path: RouteNames.parentActivities,
        builder: (_, __) => const ActivitiesPage(isParent: true),
      ),
      GoRoute(
        path: RouteNames.parentAnnouncements,
        builder: (_, __) => const AnnouncementsPage(),
      ),

      // ── Shared ────────────────────────────────────────────
      GoRoute(
        path: RouteNames.settings,
        builder: (_, __) => const SettingsPage(),
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(child: Text('Not found: ${state.matchedLocation}')),
    ),
  );
});

/// Simple ChangeNotifier that the router watches.
/// Triggered externally via [notify()] when auth state changes.
class _RouterNotifier extends ChangeNotifier {
  void notify() => notifyListeners();
}
