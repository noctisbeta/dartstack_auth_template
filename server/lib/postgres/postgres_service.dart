import 'dart:io';

import 'package:common/annotations/throws.dart';
import 'package:common/logger/logger.dart';
import 'package:postgres/postgres.dart';
import 'package:server/postgres/database_exception.dart';
import 'package:server/postgres/i_postgres_service.dart';

final class PostgresService implements IPostgresService {
  PostgresService._(this._conn);

  Connection _conn;

  static Future<PostgresService> create() async {
    try {
      final Connection conn = await _open();

      return PostgresService._(conn);
    } on Exception catch (e) {
      LOG.e('Failed to connect to database: $e');
      rethrow;
    }
  }

  static Future<Connection> _open() async {
    LOG.i('Connecting to database...');

    final Connection conn = await Connection.open(
      Endpoint(
        host: Platform.environment['POSTGRES_HOST']!,
        database: Platform.environment['POSTGRES_DATABASE']!,
        username: Platform.environment['POSTGRES_USER'],
        password: Platform.environment['POSTGRES_PASSWORD'],
      ),
      settings: const ConnectionSettings(
        sslMode: SslMode.disable,
        timeZone: 'GMT',
      ),
    );

    return conn;
  }

  @Throws([DatabaseException])
  Never _rewrapServerException(ServerException e) {
    switch (e.code) {
      case '23505':
        throw DBEuniqueViolation(e.toString());
      default:
        throw DBEunknown(e.toString());
    }
  }

  @override
  @Throws([DatabaseException])
  Future<R> runTx<R>(
    Future<R> Function(TxSession sess) fn, {
    TransactionSettings? settings,
  }) async {
    try {
      if (!_conn.isOpen) {
        _conn = await _open();
      }
      return await _conn.runTx(fn, settings: settings);
    } on ServerException catch (e) {
      _rewrapServerException(e);
    } on BadCertificateException catch (e) {
      throw DBEbadCertificate(e.toString());
    }
  }

  /// Checks if the database connection is healthy
  /// Returns true if a simple query succeeds, false otherwise
  @override
  Future<bool> isHealthy() async {
    try {
      final Result result = await _conn.execute('SELECT 1');

      return result.isNotEmpty;
    } on Exception catch (e) {
      LOG.e('Database health check failed: $e');
    }
    return false;
  }

  @override
  @Throws([DatabaseException])
  Future<Result> execute(Sql query, {Map<String, dynamic>? parameters}) async {
    try {
      if (!_conn.isOpen) {
        _conn = await _open();
      }
      return await _conn.execute(query, parameters: parameters);
    } on ServerException catch (e) {
      _rewrapServerException(e);
    } on BadCertificateException catch (e) {
      throw DBEbadCertificate(e.toString());
    }
  }

  @override
  Future<T> executeAndMap<T>({
    required Sql query,
    required T Function(Map<String, dynamic>) mapper,
    required String emptyResultMessage,
    Map<String, dynamic>? parameters,
  }) async {
    final Result result = await execute(query, parameters: parameters);
    if (result.isEmpty) {
      throw DBEemptyResult(emptyResultMessage);
    }
    return mapper(result.first.toColumnMap());
  }
}
