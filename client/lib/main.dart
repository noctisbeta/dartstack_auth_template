import 'package:client/authentication/controllers/auth_bloc.dart';
import 'package:client/authentication/models/auth_event.dart';
import 'package:client/authentication/repositories/auth_repository.dart';
import 'package:client/authentication/views/auth_view.dart';
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
    child: BlocProvider(
      create:
          (context) =>
              AuthBloc(authRepository: context.read<AuthRepository>())
                ..add(const AuthEventCheckAuth()),
      child: MaterialApp(
        title: 'Authentication App',
        theme: ThemeData(primarySwatch: Colors.blue, useMaterial3: true),
        home: const AuthView(),
      ),
    ),
  );
}
