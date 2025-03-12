import 'package:server/auth/abstractions/i_auth_repository.dart';
import 'package:server/auth/auth_data_source.dart';
import 'package:server/auth/auth_handler.dart';
import 'package:server/auth/auth_repository.dart';
import 'package:server/auth/hasher.dart';
import 'package:server/postgres/implementations/postgres_service.dart';

/// Factory class for managing auth-related services
class AuthServiceFactory {
  AuthServiceFactory._();

  // Private instance cache
  static final Map<Type, Object> _instances = {};

  /// Gets or creates an AuthHandler instance
  static AuthHandler getAuthHandler(IAuthRepository authRepository) =>
      _instances.putIfAbsent(
            AuthHandler,
            () => AuthHandler(authRepository: authRepository),
          )
          as AuthHandler;

  /// Gets or creates an AuthRepository instance with explicit dependencies
  static IAuthRepository getAuthRepository({
    required AuthDataSource authDataSource,
    required Hasher hasher,
  }) =>
      _instances.putIfAbsent(
            AuthRepository,
            () =>
                AuthRepository(authDataSource: authDataSource, hasher: hasher),
          )
          as IAuthRepository;

  /// Gets or creates a Hasher instance
  static Hasher getHasher() =>
      _instances.putIfAbsent(Hasher, () => const Hasher()) as Hasher;

  /// Gets or creates an AuthDataSource instance
  static AuthDataSource getAuthDataSource(PostgresService postgresService) =>
      _instances.putIfAbsent(
            AuthDataSource,
            () => AuthDataSource(postgresService: postgresService),
          )
          as AuthDataSource;

  /// Clears all instances (useful for testing)
  static void reset() {
    _instances.clear();
  }
}
