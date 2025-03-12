import 'package:server/routes/api/api_router.dart';
import 'package:server/routes/health/health_handler.dart';
import 'package:server/routes/root_route_handler.dart';
import 'package:shelf_router/shelf_router.dart';

Future<Router> createRouter() async {
  final Router apiRouter = await createApiRouter();

  final router =
      Router()
        ..all('/', rootRouteHandler)
        ..all('/health', healthHandler)
        ..mount('/api', apiRouter.call);

  return router;
}
