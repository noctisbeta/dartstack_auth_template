import 'dart:io';

import 'package:server/auth/auth_handler.dart';
import 'package:server/util/context_key.dart';
import 'package:server/util/http_method.dart';
import 'package:server/util/request_extension.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

Router createAuthRouter() {
  final router =
      Router()
        ..all('/login', _loginRouteHandler)
        ..all('/register', _registerRouteHandler)
        ..all('/refresh', _refreshRouteHandler);

  return router;
}

Future<Response> _loginRouteHandler(Request request) async {
  final AuthHandler authHandler = request.getFromContext(
    ContextKey.authHandler,
  );

  final method = HttpMethod.fromString(request.method);

  return switch (method) {
    HttpMethod.post => await authHandler.login(request),
    _ => Response(HttpStatus.methodNotAllowed),
  };
}

Future<Response> _registerRouteHandler(Request request) async {
  final AuthHandler authHandler = request.getFromContext(
    ContextKey.authHandler,
  );

  final method = HttpMethod.fromString(request.method);

  return switch (method) {
    HttpMethod.post => await authHandler.register(request),
    _ => Response(HttpStatus.methodNotAllowed),
  };
}

Future<Response> _refreshRouteHandler(Request request) async {
  final AuthHandler authHandler = request.getFromContext(
    ContextKey.authHandler,
  );

  final method = HttpMethod.fromString(request.method);

  return switch (method) {
    HttpMethod.post => await authHandler.refreshToken(request),
    _ => Response(HttpStatus.methodNotAllowed),
  };
}
