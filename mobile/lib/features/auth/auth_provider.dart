import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/profile_model.dart';
import 'auth_model.dart';
import 'auth_repository.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository();
});

final authProvider = NotifierProvider<AuthNotifier, AuthState>(AuthNotifier.new);

class AuthNotifier extends Notifier<AuthState> {
  @override
  AuthState build() {
    _init();
    return const AuthState();
  }

  void _init() async {
    state = state.copyWith(status: AuthStatus.loading, clearError: true);

    final result = await ref.read(authRepositoryProvider).getCurrentProfile();

    result.fold(
      (error) => state = state.copyWith(
        status: AuthStatus.unauthenticated,
        clearError: true,
      ),
      (profile) => state = state.copyWith(
        status: AuthStatus.authenticated,
        clearError: true,
      ),
    );
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
      ),
      (profile) => state = state.copyWith(
        status: AuthStatus.authenticated,
        clearError: true,
      ),
    );
  }

  Future<void> resetPassword(String email) async {
    state = state.copyWith(status: AuthStatus.loading, clearError: true);

    final result =
        await ref.read(authRepositoryProvider).resetPassword(email);

    result.fold(
      (error) => state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: error,
      ),
      (_) => state = state.copyWith(
        status: AuthStatus.unauthenticated,
        clearError: true,
      ),
    );
  }

  Future<void> signOut() async {
    await ref.read(authRepositoryProvider).signOut();
    state = const AuthState(status: AuthStatus.unauthenticated);
  }
}

final currentProfileProvider = FutureProvider<Profile?>((ref) async {
  final auth = ref.watch(authProvider);

  if (!auth.isAuthenticated) {
    return null;
  }

  final result = await ref.read(authRepositoryProvider).getCurrentProfile();

  return result.fold(
    (_) => null,
    (profile) => profile,
  );
});
