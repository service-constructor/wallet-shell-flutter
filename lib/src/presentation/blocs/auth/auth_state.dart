part of 'auth_bloc.dart';

sealed class AuthState extends Equatable {
  const AuthState();
  @override
  List<Object?> get props => [];
}

/// Startup: still resolving whether a stored token is valid.
class AuthInitial extends AuthState {
  const AuthInitial();
}

/// A login/register/check request is in flight.
class AuthLoading extends AuthState {
  const AuthLoading();
}

class AuthAuthenticated extends AuthState {
  const AuthAuthenticated(this.user);
  final User user;
  @override
  List<Object?> get props => [user];
}

class AuthUnauthenticated extends AuthState {
  /// Non-null when the previous auth attempt failed (shown on the auth screen).
  const AuthUnauthenticated({this.error});
  final String? error;
  @override
  List<Object?> get props => [error];
}
