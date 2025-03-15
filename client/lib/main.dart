import 'dart:async';

import 'package:client/authentication/controllers/auth_bloc.dart';
import 'package:client/authentication/models/auth_event.dart';
import 'package:client/authentication/models/auth_state.dart';
import 'package:client/authentication/repositories/auth_repository.dart';
import 'package:client/authentication/views/auth_view.dart';
import 'package:client/dashboard/views/dashboard_view.dart';
import 'package:client/dio_wrapper/dio_wrapper.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) => MultiRepositoryProvider(
    providers: [
      RepositoryProvider(create: (context) => DioWrapper.unauthorized()),
      RepositoryProvider(create: (context) => const FlutterSecureStorage()),
      RepositoryProvider(
        create:
            (context) => AuthRepository(
              dio: context.read<DioWrapper>(),
              storage: context.read<FlutterSecureStorage>(),
            ),
      ),
    ],
    child: MultiBlocProvider(
      providers: [
        BlocProvider<AuthBloc>(
          create:
              (context) =>
                  AuthBloc(authRepository: context.read<AuthRepository>())
                    ..add(const AuthEventCheckAuth()),
        ),
      ],
      child: const AppWithAuthListener(),
    ),
  );
}

// This widget listens to auth state changes and handles navigation accordingly
class AppWithAuthListener extends StatelessWidget {
  const AppWithAuthListener({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
    scaffoldMessengerKey: GlobalKey<ScaffoldMessengerState>(),
    title: 'Dart Stack Auth Template',
    theme: ThemeData(
      colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      useMaterial3: true,
    ),
    initialRoute: '/login',
    routes: {
      '/login': (context) => const AuthView(),
      '/dashboard': (context) => const DashboardView(),
    },
    builder:
        (context, child) => BlocListener<AuthBloc, AuthState>(
          listener: (context, state) {
            if (state is AuthStateSessionExpired) {
              // Use the ScaffoldMessenger that's now available from MaterialApp
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.message),
                  backgroundColor: Colors.red,
                  duration: const Duration(seconds: 5),
                ),
              );

              // Navigate to login screen
              unawaited(
                Navigator.of(
                  context,
                ).pushNamedAndRemoveUntil('/login', (route) => false),
              );
            }
          },
          child: child ?? const SizedBox.shrink(),
        ),
  );
}
