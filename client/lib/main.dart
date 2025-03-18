import 'dart:async';

import 'package:client/authentication/controllers/auth_bloc.dart';
import 'package:client/authentication/models/auth_event.dart';
import 'package:client/authentication/models/auth_state.dart';
import 'package:client/authentication/repositories/auth_repository.dart';
import 'package:client/authentication/views/auth_view.dart';
import 'package:client/common/widgets/my_snackbar.dart';
import 'package:client/dashboard/views/dashboard_view.dart';
import 'package:client/dio_wrapper/dio_wrapper.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:go_router/go_router.dart';

void main() {
  runApp(const ProviderWrapper());
}

class ProviderWrapper extends StatelessWidget {
  const ProviderWrapper({super.key});

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
      child: const AuthListenerWrapper(),
    ),
  );
}

class AuthListenerWrapper extends StatefulWidget {
  const AuthListenerWrapper({super.key});

  @override
  State<AuthListenerWrapper> createState() => _AuthListenerWrapperState();
}

class _AuthListenerWrapperState extends State<AuthListenerWrapper> {
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    _router = createRouter();
  }

  GoRouter createRouter() {
    final AuthBloc authBloc = context.read<AuthBloc>();

    return GoRouter(
      routes: [
        GoRoute(
          path: '/auth',
          name: 'auth',
          builder: (context, state) => const AuthView(),
        ),
        GoRoute(
          path: '/dashboard',
          name: 'dashboard',
          builder: (context, state) => const DashboardView(),
        ),
      ],
      initialLocation: '/auth',
      redirect: _redirect,
      // Add this line to make router refresh when auth state changes
      refreshListenable: _GoRouterRefresh(authBloc),
      debugLogDiagnostics: kDebugMode,
    );
  }

  Future<String?>? _redirect(BuildContext context, GoRouterState state) async {
    final bool isAuthenticated =
        await context.read<AuthRepository>().isAuthenticated();

    final bool isOnAuth = state.uri.toString() == '/auth';

    switch ((isAuthenticated, isOnAuth)) {
      case (true, true):
        return '/dashboard';
      case (false, false):
        return '/auth';
      case (true, false):
        return null;
      case (false, true):
        return null;
    }
  }

  @override
  Widget build(BuildContext context) => MaterialApp.router(
    routerConfig: _router,
    title: 'Dartstack Auth Template',
    debugShowCheckedModeBanner: false,
    builder:
        (context, child) => BlocListener<AuthBloc, AuthState>(
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
          child: child ?? const SizedBox.shrink(),
        ),
  );
}

// Simple class to refresh router when auth state changes
class _GoRouterRefresh extends ChangeNotifier {
  _GoRouterRefresh(this._authBloc) {
    _subscription = _authBloc.stream.listen((_) => notifyListeners());
  }
  final AuthBloc _authBloc;
  StreamSubscription<AuthState>? _subscription;

  @override
  void dispose() {
    unawaited(_subscription?.cancel());
    super.dispose();
  }
}
