import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/error/exceptions.dart';
import '../../../data/repositories/wallet_repository.dart';
import '../../../domain/entities/user.dart';

part 'auth_event.dart';
part 'auth_state.dart';

/// Owns the session lifecycle: startup token validation, login/register, and
/// logout. Everything else (accounts, apps, orders) lives in CabinetBloc.
class AuthBloc extends Bloc<AuthEvent, AuthState> {
  AuthBloc(this._repo) : super(const AuthInitial()) {
    on<AuthCheckRequested>(_onCheck);
    on<AuthLoginRequested>(_onLogin);
    on<AuthRegisterRequested>(_onRegister);
    on<AuthLogoutRequested>(_onLogout);
  }

  final WalletRepository _repo;

  Future<void> _onCheck(AuthCheckRequested event, Emitter<AuthState> emit) async {
    emit(const AuthLoading());
    try {
      final user = await _repo.me();
      emit(AuthAuthenticated(user));
    } catch (_) {
      // No/expired token, or offline: treat as signed out (no error banner).
      emit(const AuthUnauthenticated());
    }
  }

  Future<void> _onLogin(AuthLoginRequested event, Emitter<AuthState> emit) async {
    emit(const AuthLoading());
    try {
      final result = await _repo.login(event.login, event.password);
      emit(AuthAuthenticated(result.user));
    } catch (e) {
      emit(AuthUnauthenticated(error: _message(e)));
    }
  }

  Future<void> _onRegister(AuthRegisterRequested event, Emitter<AuthState> emit) async {
    emit(const AuthLoading());
    try {
      final result = await _repo.register(event.login, event.password);
      emit(AuthAuthenticated(result.user));
    } catch (e) {
      emit(AuthUnauthenticated(error: _message(e)));
    }
  }

  Future<void> _onLogout(AuthLogoutRequested event, Emitter<AuthState> emit) async {
    await _repo.logout();
    emit(const AuthUnauthenticated());
  }

  String _message(Object e) => e is ApiException ? e.message : e.toString();
}
