import 'dart:io';

import 'package:common/logger/logger.dart';
import 'package:server/auth/security_middleware.dart';
import 'package:server/postgres/implementations/migration_service.dart';
import 'package:server/postgres/implementations/postgres_service.dart';
import 'package:server/routes/root_router.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart';
import 'package:shelf_hotreload/shelf_hotreload.dart';
import 'package:shelf_router/shelf_router.dart';

Future<void> _initDatabase() async {
  final PostgresService postgresService = await PostgresService.create();
  final migrationService = MigrationService(postgresService: postgresService);

  await migrationService.up();
}

Future<void> main() async {
  await _initDatabase();

  final Router router = await createRootRouter();

  final Handler handler = const Pipeline()
      .addMiddleware(logRequests())
      .addMiddleware(securityMiddleware())
      .addHandler(router.call);

  final bool enableHotReload =
      Platform.environment['ENABLE_HOT_RELOAD'] == 'true';

  if (enableHotReload) {
    withHotreload(() => serve(handler, InternetAddress.anyIPv4, 8080));
  } else {
    await serve(handler, InternetAddress.anyIPv4, 8080);
  }

  LOG.i('Server running on localhost:8080');
}
