part of 'auth_bloc.dart';

sealed class AuthEvent extends Equatable {
  const AuthEvent();
  @override
  List<Object?> get props => [];
}

/// On startup: validate any persisted token by fetching the current user.
class AuthCheckRequested extends AuthEvent {
  const AuthCheckRequested();
}

class AuthLoginRequested extends AuthEvent {
  const AuthLoginRequested(this.login, this.password);
  final String login;
  final String password;
  @override
  List<Object?> get props => [login, password];
}

class AuthRegisterRequested extends AuthEvent {
  const AuthRegisterRequested(this.login, this.password);
  final String login;
  final String password;
  @override
  List<Object?> get props => [login, password];
}

class AuthLogoutRequested extends AuthEvent {
  const AuthLogoutRequested();
}
