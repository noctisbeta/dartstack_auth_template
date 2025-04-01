import 'dart:io';

import 'package:server/annotations/prefix.dart';
import 'package:server/auth/hasher.dart';
import 'package:server/auth/implementations/auth_data_source.dart';
import 'package:server/auth/implementations/auth_handler.dart';
import 'package:server/auth/implementations/auth_repository.dart';
import 'package:server/middleware/content_type_middleware.dart';
import 'package:server/postgres/postgres_service.dart';
import 'package:server/routes/api/v1/auth_router.dart';
import 'package:server/util/json_response.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

@Prefix('/api/v1')
Future<Router> createV1Router() async {
  final PostgresService postgresService = await PostgresService.create();

  final AuthDataSource authDataSource = AuthDataSource(
    postgresService: postgresService,
  );
  final AuthRepository authRepository = AuthRepository(
    authDataSource: authDataSource,
    hasher: const Hasher(),
  );
  final AuthHandler authHandler = AuthHandler(authRepository: authRepository);

  final Router authRouter = createAuthRouter(authHandler);
  final Handler authHandlerWithMiddleware = const Pipeline()
      .addMiddleware(enforceJsonContentType())
      .addHandler(authRouter.call);

  final router =
      Router()
        ..get('/health', (request) => _healthHandler(request, postgresService))
        ..mount('/auth', authHandlerWithMiddleware);

  return router;
}

Future<Response> _healthHandler(
  Request request,
  PostgresService postgresService,
) async {
  try {
    // Start timing for latency measurement
    final Stopwatch stopwatch = Stopwatch()..start();

    // Check database health
    final bool isDatabaseHealthy = await postgresService.isHealthy();

    // Stop timing after health check completes
    stopwatch.stop();
    final int latencyMs = stopwatch.elapsedMilliseconds;

    // Build response with latency information
    final Map<String, dynamic> healthData = {
      'status': isDatabaseHealthy ? 'UP' : 'DOWN',
      'timestamp': DateTime.now().toUtc().toIso8601String(),
      'version': '1.0.0',
      'dependencies': {'database': isDatabaseHealthy ? 'UP' : 'DOWN'},
      'latency': {'database': '$latencyMs ms'},
    };

    return JsonResponse.other(
      body: healthData,
      statusCode:
          isDatabaseHealthy ? HttpStatus.ok : HttpStatus.serviceUnavailable,
    );
  } on Exception catch (e) {
    return JsonResponse.other(
      body: {
        'status': 'DOWN',
        'timestamp': DateTime.now().toUtc().toIso8601String(),
        'version': '1.0.0',
        'dependencies': {'database': 'DOWN'},
        'latency': {'database': 'N/A'},
        'error': e.toString(),
      },
      statusCode: HttpStatus.serviceUnavailable,
    );
  }
}
