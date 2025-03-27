import 'dart:convert';
import 'dart:io';

import 'package:server/routes/api/api_router.dart';
import 'package:server/util/http_method.dart';
import 'package:server/util/json_response.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

Future<Router> createRootRouter() async {
  final Router apiRouter = await createApiRouter();

  final router =
      Router()
        ..all('/', _rootRouteHandler)
        ..all('/health', _healthHandler)
        ..mount('/api', apiRouter.call);

  return router;
}

Future<Response> _rootRouteHandler(Request request) async {
  final HttpMethod method = HttpMethod.fromString(request.method);

  return switch (method) {
    HttpMethod.get => JsonResponse(
      body: jsonEncode({
        'name': 'DartstackAuthTemplate API',
        'version': '1.0.0',
        'timestamp': DateTime.now().toUtc().toIso8601String(),
      }),
    ),
    _ => Response(HttpStatus.methodNotAllowed),
  };
}

Future<Response> _healthHandler(Request request) async {
  final method = HttpMethod.fromString(request.method);

  return switch (method) {
    HttpMethod.get => JsonResponse(
      body: {
        'status': 'UP',
        'timestamp': DateTime.now().toUtc().toIso8601String(),
      },
    ),
    _ => Response(HttpStatus.methodNotAllowed),
  };
}
