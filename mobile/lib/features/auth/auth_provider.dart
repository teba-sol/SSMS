import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthState;
import '../../models/profile_model.dart';
import '../../supabase/supabase_client.dart';
import 'auth_model.dart';
import 'auth_repository.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository();
});

final authProvider = NotifierProvider<AuthNotifier, AuthState>(AuthNotifier.new);

class AuthNotifier extends Notifier<AuthState> {
  StreamSubscription? _authSubscription;

  @override
  AuthState build() {
    ref.onDispose(() {
      _authSubscription?.cancel();
    });
    Future.microtask(() => _init());
    return const AuthState();
  }

  void _init() async {
    try {
      final currentSession = AppSupabase.client.auth.currentSession;

      // Subscribe to auth state changes from Supabase
      _authSubscription?.cancel();
      _authSubscription = AppSupabase.client.auth.onAuthStateChange.listen((data) async {
        final event = data.event;
        final session = data.session;

        if (session == null || event == AuthChangeEvent.signedOut) {
          state = state.copyWith(
            status: AuthStatus.unauthenticated,
            clearError: true,
            clearProfile: true,
          );
          return;
        }

        if (event == AuthChangeEvent.signedIn || event == AuthChangeEvent.initialSession || event == AuthChangeEvent.tokenRefreshed) {
          final result = await ref.read(authRepositoryProvider).getCurrentProfile();
          result.fold(
            (error) => state = state.copyWith(
              status: AuthStatus.unauthenticated,
              clearError: true,
              clearProfile: true,
            ),
            (profile) => state = state.copyWith(
              status: AuthStatus.authenticated,
              profile: profile,
              clearError: true,
            ),
          );
        }
      });

      if (currentSession == null) {
        state = state.copyWith(
          status: AuthStatus.unauthenticated,
          clearError: true,
          clearProfile: true,
        );
        return;
      }

      // Also check current profile immediately
      final result = await ref.read(authRepositoryProvider).getCurrentProfile();
      result.fold(
        (error) => state = state.copyWith(
          status: AuthStatus.unauthenticated,
          clearError: true,
          clearProfile: true,
        ),
        (profile) => state = state.copyWith(
          status: AuthStatus.authenticated,
          profile: profile,
          clearError: true,
        ),
      );
    } catch (_) {
      state = state.copyWith(
        status: AuthStatus.unauthenticated,
        clearError: true,
        clearProfile: true,
      );
    }
  }

  Future<void> signIn({
    required String email,
    required String password,
  }) async {
    state = state.copyWith(status: AuthStatus.loading, clearError: true);

    final result = await ref.read(authRepositoryProvider).signIn(
          email: email,
          password: password,
        );

    result.fold(
      (error) => state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: error,
        clearProfile: true,
      ),
      (profile) => state = state.copyWith(
        status: AuthStatus.authenticated,
        profile: profile,
        clearError: true,
      ),
    );
  }

  Future<void> resetPassword(String email) async {
    state = state.copyWith(status: AuthStatus.loading, clearError: true);

    final result = await ref.read(authRepositoryProvider).resetPassword(email);

    result.fold(
      (error) => state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: error,
      ),
      (_) => state = state.copyWith(
        status: AuthStatus.unauthenticated,
        clearError: true,
        clearProfile: true,
      ),
    );
  }

  // Public method to refresh profile after updates
  void refreshProfile() => _init();

  Future<void> signOut() async {
    state = state.copyWith(status: AuthStatus.loading, clearError: true);
    final result = await ref.read(authRepositoryProvider).signOut();
    result.fold(
      (error) => state = state.copyWith(status: AuthStatus.error, errorMessage: error),
      (_) => state = const AuthState(status: AuthStatus.unauthenticated),
    );
  }
}

/// Reads profile from auth state — synchronous, no FutureProvider needed.
final currentProfileProvider = Provider<Profile?>((ref) {
  return ref.watch(authProvider).profile;
});
