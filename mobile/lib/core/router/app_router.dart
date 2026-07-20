import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../models/profile_model.dart';
import '../auth/auth_page.dart';
import '../auth/auth_provider.dart';
import '../auth/forgot_password_page.dart';
import '../auth/reset_password_page.dart';
import '../dashboard/dashboard_page.dart';
import '../settings/settings_page.dart';
import 'route_names.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: RouteNames.login,
    debugLogDiagnostics: true,
    redirect: (context, state) {
      final authState = ref.read(authProvider);
      final isLoggedIn = authState.isAuthenticated;
      final isLoginRoute = state.matchedLocation == RouteNames.login;

      if (!isLoggedIn && !isLoginRoute) {
        return RouteNames.login;
      }

      if (isLoggedIn && isLoginRoute) {
        final profileAsync = ref.read(currentProfileProvider);
        return profileAsync.when(
          data: (profile) {
            if (profile == null) return RouteNames.login;
            return _getDashboardRoute(profile.role);
          },
          loading: () => null,
          error: (_, __) => RouteNames.login,
        );
      }

      return null;
    },
    routes: [
      GoRoute(
        name: RouteNames.login,
        path: RouteNames.login,
        builder: (context, state) => const AuthPage(),
      ),
      GoRoute(
        name: RouteNames.forgotPassword,
        path: RouteNames.forgotPassword,
        builder: (context, state) => const ForgotPasswordPage(),
      ),
      GoRoute(
        name: RouteNames.resetPassword,
        path: RouteNames.resetPassword,
        builder: (context, state) => const ResetPasswordPage(),
      ),
      GoRoute(
        name: RouteNames.teacherDashboard,
        path: RouteNames.teacherDashboard,
        builder: (context, state) => const DashboardPage(
          role: UserRole.teacher,
        ),
      ),
      GoRoute(
        name: RouteNames.parentDashboard,
        path: RouteNames.parentDashboard,
        builder: (context, state) => const DashboardPage(
          role: UserRole.parent,
        ),
      ),
      GoRoute(
        name: RouteNames.settings,
        path: RouteNames.settings,
        builder: (context, state) => const SettingsPage(),
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Text('Page not found: ${state.matchedLocation}'),
      ),
    ),
  );
});

String _getDashboardRoute(UserRole role) {
  switch (role) {
    case UserRole.teacher:
      return RouteNames.teacherDashboard;
    case UserRole.parent:
      return RouteNames.parentDashboard;
    case UserRole.administrator:
      return RouteNames.login;
  }
}
