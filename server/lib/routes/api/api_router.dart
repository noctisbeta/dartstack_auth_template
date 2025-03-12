import 'package:server/postgres/providers/postgres_provider.dart';
import 'package:server/routes/api/v1/v1_router.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

Future<Router> createApiRouter() async {
  final Router v1Router = await createV1Router();

  final Handler v1Handler = const Pipeline()
      .addMiddleware(postgresServiceProvider())
      .addHandler(v1Router.call);

  final router = Router()..mount('/v1', v1Handler);

  return router;
}
