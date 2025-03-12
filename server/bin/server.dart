import 'dart:io';

import 'package:server/auth/security_middleware.dart';
import 'package:server/postgres/implementations/migration_service.dart';
import 'package:server/postgres/implementations/postgres_service.dart';
import 'package:server/routes/routes.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart';
import 'package:shelf_router/shelf_router.dart';

Future<void> _initDatabase() async {
  final PostgresService database = await PostgresService.create();
  final migrationService = MigrationService(postgresService: database);

  await migrationService.up();
}

Future<void> main() async {
  // Initialize database and run migrations
  await _initDatabase();

  // Create router
  final Router router = await createRouter();

  // Create handler pipeline
  final Handler handler = const Pipeline()
      .addMiddleware(logRequests())
      .addMiddleware(securityMiddleware())
      .addHandler(router.call);

  await serve(handler, InternetAddress.anyIPv4, 8080);
}
