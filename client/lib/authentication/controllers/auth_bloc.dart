import 'package:client/authentication/models/auth_event.dart';
import 'package:client/authentication/models/auth_state.dart';
import 'package:client/authentication/repositories/auth_repository.dart';
import 'package:common/auth/login/login_error.dart';
import 'package:common/auth/login/login_request.dart';
import 'package:common/auth/login/login_response.dart';
import 'package:common/auth/register/register_error.dart';
import 'package:common/auth/register/register_request.dart';
import 'package:common/auth/register/register_response.dart';
import 'package:common/auth/user.dart';
import 'package:common/logger/logger.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  AuthBloc({required AuthRepository authRepository})
    : _authRepository = authRepository,
      super(const AuthStateUnauthenticated()) {
    on<AuthEvent>(
      (event, emit) async => switch (event) {
        AuthEventLogin() => await login(event, emit),
        AuthEventRegister() => await register(event, emit),
        AuthEventLogout() => await logout(event, emit),
        AuthEventCheckAuth() => await checkAuth(event, emit),
      },
    );
  }

  final AuthRepository _authRepository;

  Future<void> checkAuth(
    AuthEventCheckAuth event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthStateLoading());

    final bool isAuthenticated = await _authRepository.isAuthenticated();

    if (isAuthenticated) {
      final User user = await _authRepository.getUser();
      emit(AuthStateAuthenticated(user: user));
    } else {
      emit(const AuthStateUnauthenticated());
    }
  }

  Future<void> logout(AuthEventLogout event, Emitter<AuthState> emit) async {
    try {
      await _authRepository.logout();
      emit(const AuthStateUnauthenticated());
    } on Exception catch (e) {
      LOG.e('Unknown logout error: $e');

      emit(const AuthStateErrorUnknown(message: 'Error logging out'));
    }
  }

  Future<void> login(AuthEventLogin event, Emitter<AuthState> emit) async {
    emit(const AuthStateLoading());

    final LoginRequest loginRequest = LoginRequest(
      username: event.username,
      password: event.password,
    );

    final LoginResponse loginResponse = await _authRepository.login(
      loginRequest,
    );

    switch (loginResponse) {
      case LoginResponseSuccess():
        emit(AuthStateAuthenticated(user: loginResponse.user));
      case LoginResponseError():
        switch (loginResponse.error) {
          case LoginError.wrongPassword:
            emit(const AuthStateErrorWrongPassword(message: 'Wrong password'));
          case LoginError.unknownLoginError:
            emit(const AuthStateErrorUnknown(message: 'Error logging in user'));
          case LoginError.userNotFound:
            emit(const AuthStateErrorUserNotFound(message: 'User not found'));
        }
    }
  }

  Future<void> register(
    AuthEventRegister event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthStateLoading());

    final RegisterRequest registerRequest = RegisterRequest(
      username: event.username,
      password: event.password,
    );

    final RegisterResponse registerResponse = await _authRepository.register(
      registerRequest,
    );

    switch (registerResponse) {
      case RegisterResponseSuccess():
        emit(AuthStateAuthenticated(user: registerResponse.user));
      case RegisterResponseError():
        switch (registerResponse.error) {
          case RegisterError.usernameAlreadyExists:
            emit(
              const AuthStateErrorUsernameAlreadyExists(
                message: 'Username already taken',
              ),
            );
          case RegisterError.unknownRegisterError:
            emit(
              const AuthStateErrorUnknown(message: 'Error registering user'),
            );
        }
    }
  }
}
