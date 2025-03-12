import 'package:server/auth/abstractions/i_auth_repository.dart';
import 'package:server/auth/auth_data_source.dart';
import 'package:server/auth/auth_handler.dart';
import 'package:server/auth/auth_service_factory.dart';
import 'package:server/auth/hasher.dart';
import 'package:server/postgres/implementations/postgres_service.dart';
import 'package:server/util/context_key.dart';
import 'package:server/util/request_extension.dart';
import 'package:shelf/shelf.dart';

/// Middleware for providing AuthHandler
Middleware authHandlerProvider() =>
    (Handler innerHandler) => (Request request) async {
      final IAuthRepository authRepository = request.getFromContext(
        ContextKey.authRepository,
      );

      final AuthHandler authHandler = AuthServiceFactory.getAuthHandler(
        authRepository,
      );

      final Request newRequest = request.addToContext(
        ContextKey.authHandler,
        authHandler,
      );

      return await innerHandler(newRequest);
    };

/// Middleware for providing AuthRepository
Middleware authRepositoryProvider() =>
    (Handler innerHandler) => (Request request) async {
      final AuthDataSource authDataSource = request.getFromContext(
        ContextKey.authDataSource,
      );

      // Get the hasher explicitly
      final Hasher hasher = AuthServiceFactory.getHasher();

      // Use the new signature with named parameters
      final IAuthRepository authRepository =
          AuthServiceFactory.getAuthRepository(
            authDataSource: authDataSource,
            hasher: hasher,
          );

      final Request newRequest = request.addToContext(
        ContextKey.authRepository,
        authRepository,
      );

      return await innerHandler(newRequest);
    };

/// Middleware for providing AuthDataSource
Middleware authDataSourceProvider() =>
    (Handler innerHandler) => (Request request) async {
      final PostgresService postgresService = request.getFromContext(
        ContextKey.postgresService,
      );

      final AuthDataSource authDataSource =
          AuthServiceFactory.getAuthDataSource(postgresService);

      final Request newRequest = request.addToContext(
        ContextKey.authDataSource,
        authDataSource,
      );

      return await innerHandler(newRequest);
    };
