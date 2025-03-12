import 'package:server/postgres/implementations/migration_service.dart';
import 'package:server/util/context_key.dart';
import 'package:server/util/request_extension.dart';
import 'package:shelf/shelf.dart';

MigrationService? _migrationService;

Middleware migrationProvider() =>
    (Handler innerHandler) => (Request request) async {
      _migrationService ??= MigrationService(
        postgresService: request.getFromContext(ContextKey.postgresService),
      );

      final Request newRequest = request.addToContext(
        ContextKey.migrationService,
        _migrationService,
      );

      return await innerHandler(newRequest);
    };
