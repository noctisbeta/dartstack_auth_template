import 'dart:convert';

import 'package:server/routes/api/api_router.dart';
import 'package:server/util/json_response.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

Future<Router> createRootRouter() async {
  final Router apiRouter = await createApiRouter();

  final router =
      Router()
        ..get('/', _rootRouteHandler)
        ..get('/health', _healthHandler)
        ..mount('/api', apiRouter.call);

  return router;
}

Future<Response> _rootRouteHandler(Request request) async => JsonResponse(
  body: jsonEncode({
    'name': 'DartstackAuthTemplate API',
    'version': '1.0.0',
    'timestamp': DateTime.now().toUtc().toIso8601String(),
  }),
);

Future<Response> _healthHandler(Request request) async => JsonResponse(
  body: {'status': 'UP', 'timestamp': DateTime.now().toUtc().toIso8601String()},
);
