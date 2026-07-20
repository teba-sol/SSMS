import 'package:equatable/equatable.dart';

enum AuthStatus { initial, loading, authenticated, unauthenticated, error }

class AuthState extends Equatable {
  final AuthStatus status;
  final String? errorMessage;

  const AuthState({
    this.status = AuthStatus.initial,
    this.errorMessage,
  });

  AuthState copyWith({
    AuthStatus? status,
    String? errorMessage,
    bool clearError = false,
  }) {
    return AuthState(
      status: status ?? this.status,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  bool get isAuthenticated => status == AuthStatus.authenticated;
  bool get isLoading => status == AuthStatus.loading;

  @override
  List<Object?> get props => [status, errorMessage];
}
