import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart' show immutable;

@immutable
sealed class AuthEvent extends Equatable {
  const AuthEvent();
}

@immutable
final class AuthEventCheckAuth extends AuthEvent {
  const AuthEventCheckAuth();

  @override
  List<Object?> get props => [];
}

@immutable
final class AuthEventLogin extends AuthEvent {
  const AuthEventLogin({required this.username, required this.password});

  final String username;
  final String password;

  @override
  List<Object?> get props => [username, password];
}

@immutable
final class AuthEventRegister extends AuthEvent {
  const AuthEventRegister({required this.username, required this.password});

  final String username;
  final String password;

  @override
  List<Object?> get props => [username, password];
}

@immutable
final class AuthEventLogout extends AuthEvent {
  const AuthEventLogout();

  @override
  List<Object?> get props => [];
}
