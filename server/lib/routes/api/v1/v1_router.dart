import 'dart:io';

import 'package:server/auth/auth_providers.dart';
import 'package:server/health/providers/health_service_provider.dart';
import 'package:server/health/services/health_service.dart';
import 'package:server/routes/api/v1/auth_router.dart';
import 'package:server/util/context_key.dart';
import 'package:server/util/http_method.dart';
import 'package:server/util/json_response.dart';
import 'package:server/util/request_extension.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

Future<Router> createV1Router() async {
  final Handler healthHandler = const Pipeline()
      .addMiddleware(healthServiceProvider())
      .addHandler(_apiV1HealthHandler);

  final Router authRouter = createAuthRouter();
  final Handler authHandler = const Pipeline()
      .addMiddleware(authDataSourceProvider())
      .addMiddleware(authRepositoryProvider())
      .addMiddleware(authHandlerProvider())
      .addHandler(authRouter.call);

  final router =
      Router()
        ..all('/health', healthHandler)
        ..mount('/auth', authHandler);

  return router;
}

Future<Response> _apiV1HealthHandler(Request request) async {
  final method = HttpMethod.fromString(request.method);

  if (method != HttpMethod.get) {
    return Response(HttpStatus.methodNotAllowed);
  }

  final HealthService healthService = request.getFromContext(
    ContextKey.healthService,
  );

  final Map<String, dynamic> healthCheck = await healthService.checkHealth();

  final String status = healthCheck['status'];
  final DateTime timestamp = DateTime.parse(healthCheck['timestamp']);
  final Map<String, dynamic> databaseChecks = healthCheck['database'];

  final String dbStatus = databaseChecks['status'];
  final String dbLatency = databaseChecks['latency'];

  final health = <String, dynamic>{
    'status': status,
    'timestamp': timestamp.toIso8601String(),
    'version': '1.0.0',
    'service': 'chrono-quest-api',
    'api': {
      'version': 'v1',
      'dependencies': {'database': dbStatus},
      'latency': {'database': dbLatency},
    },
  };

  return JsonResponse(
    body: health,
    statusCode:
        health['status'] == 'UP'
            ? HttpStatus.ok
            : HttpStatus.serviceUnavailable,
  );
}
