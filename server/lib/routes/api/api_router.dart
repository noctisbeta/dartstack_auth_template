import 'package:server/annotations/prefix.dart';
import 'package:server/routes/api/v1/v1_router.dart';
import 'package:shelf_router/shelf_router.dart';

@Prefix('/api')
Future<Router> createApiRouter() async {
  final Router v1Router = await createV1Router();

  final router = Router()..mount('/v1', v1Router.call);

  return router;
}
