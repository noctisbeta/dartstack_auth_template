import 'package:client/authentication/controllers/auth_bloc.dart';
import 'package:client/authentication/models/auth_event.dart';
import 'package:client/authentication/models/auth_state.dart';
import 'package:client/authentication/repositories/auth_repository.dart';
import 'package:client/common/widgets/my_snackbar.dart';
import 'package:client/dio_wrapper/dio_wrapper.dart';
import 'package:client/routing/my_router.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

void main() {
  runApp(const ProviderWrapper());
}

class ProviderWrapper extends StatelessWidget {
  const ProviderWrapper({super.key});

  @override
  Widget build(BuildContext context) => MultiRepositoryProvider(
    providers: [
      RepositoryProvider(create: (context) => DioWrapper()),
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
                  AuthBloc(authRepository: context.read<AuthRepository>()),
        ),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();

    context.read<AuthBloc>().add(const AuthEventCheckAuth());
  }

  @override
  Widget build(BuildContext context) => RouterWrapper(
    builder:
        (context, router) => BlocListener<AuthBloc, AuthState>(
          listener: (context, state) {
            if (state is AuthStateSessionExpired) {
              MySnackBar.show(
                context: context,
                message: state.message,
                type: SnackBarType.warning,
              );
            } else if (state is AuthStateError) {
              MySnackBar.show(
                context: context,
                message: state.message,
                type: SnackBarType.error,
              );
            }
          },
          child: router,
        ),
  );
}
