import 'package:server/annotations/prefix.dart';
import 'package:server/routes/api/api_router.dart';
import 'package:server/util/json_response.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

@Prefix('/')
Future<Router> createRootRouter() async {
  final Router apiRouter = await createApiRouter();

  final router =
      Router()
        ..get('/', _rootRouteHandler)
        ..get('/health', _healthHandler)
        ..mount('/api', apiRouter.call);

  return router;
}

Future<Response> _rootRouteHandler(Request request) async => JsonResponse.ok(
  body: {
    'name': 'DartstackAuthTemplate API',
    'version': '1.0.0',
    'timestamp': DateTime.now().toUtc().toIso8601String(),
  },
);

Future<Response> _healthHandler(Request request) async => JsonResponse.ok(
  body: {'status': 'UP', 'timestamp': DateTime.now().toUtc().toIso8601String()},
);
