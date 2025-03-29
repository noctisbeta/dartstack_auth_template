import 'package:server/annotations/prefix.dart';
import 'package:server/auth/implementations/auth_handler.dart';
import 'package:shelf_router/shelf_router.dart';

@Prefix('/api/v1/auth')
Router createAuthRouter(AuthHandler authHandler) {
  final router =
      Router()
        ..post('/login', authHandler.login)
        ..post('/register', authHandler.register)
        ..all('/refresh', authHandler.refreshJWToken);

  return router;
}
