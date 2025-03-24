import 'package:client/authentication/controllers/auth_bloc.dart';
import 'package:client/authentication/repositories/auth_repository.dart';
import 'package:client/authentication/views/auth_view.dart';
import 'package:client/dashboard/views/dashboard_view.dart';
import 'package:client/routing/refresh_listenable.dart';
import 'package:client/routing/router_path.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

class RouterWrapper extends StatefulWidget {
  const RouterWrapper({this.builder, super.key});

  final Widget Function(BuildContext, Widget?)? builder;

  @override
  State<RouterWrapper> createState() => _RouterWrapperState();
}

class _RouterWrapperState extends State<RouterWrapper> {
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
          path: RouterPath.auth.path,
          name: RouterPath.auth.name,
          builder: (context, state) => const AuthView(),
        ),
        GoRoute(
          path: RouterPath.dashboard.path,
          name: RouterPath.dashboard.name,
          builder: (context, state) => const DashboardView(),
        ),
      ],
      initialLocation: RouterPath.auth.path,
      redirect: _redirect,
      refreshListenable: RefreshListenable(stream: authBloc.stream),
      debugLogDiagnostics: kDebugMode,
    );
  }

  Future<String?>? _redirect(BuildContext context, GoRouterState state) async {
    final bool isAuthenticated =
        await context.read<AuthRepository>().isAuthenticated();

    final bool isOnAuth = state.uri.toString() == RouterPath.auth.path;

    switch ((isAuthenticated, isOnAuth)) {
      case (true, true):
        return RouterPath.dashboard.path;
      case (false, false):
        return RouterPath.auth.path;
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
    builder: widget.builder,
  );
}
