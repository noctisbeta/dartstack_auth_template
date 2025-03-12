import 'dart:io';

import 'package:server/auth/auth_handler.dart';
import 'package:server/util/context_key.dart';
import 'package:server/util/http_method.dart';
import 'package:server/util/request_extension.dart';
import 'package:shelf/shelf.dart';

Future<Response> refreshRouteHandler(Request request) async {
  final AuthHandler authHandler = request.getFromContext(
    ContextKey.authHandler,
  );

  final method = HttpMethod.fromString(request.method);

  return switch (method) {
    HttpMethod.post => await authHandler.refreshToken(request),
    _ => Response(HttpStatus.methodNotAllowed),
  };
}
