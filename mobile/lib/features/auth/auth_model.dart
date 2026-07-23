import 'package:equatable/equatable.dart';
import '../../models/profile_model.dart';
export '../../models/profile_model.dart' show UserRole;

enum AuthStatus { initial, loading, authenticated, unauthenticated, error }

class AuthState extends Equatable {
  final AuthStatus status;
  final String? errorMessage;
  final Profile? profile;

  const AuthState({
    this.status = AuthStatus.initial,
    this.errorMessage,
    this.profile,
  });

  AuthState copyWith({
    AuthStatus? status,
    String? errorMessage,
    Profile? profile,
    bool clearError = false,
    bool clearProfile = false,
  }) {
    return AuthState(
      status: status ?? this.status,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      profile: clearProfile ? null : (profile ?? this.profile),
    );
  }

  bool get isAuthenticated => status == AuthStatus.authenticated;
  bool get isLoading => status == AuthStatus.loading || status == AuthStatus.initial;

  @override
  List<Object?> get props => [status, errorMessage, profile];
}
