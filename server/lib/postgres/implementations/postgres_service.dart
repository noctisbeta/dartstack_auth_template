import 'dart:io';

import 'package:common/exceptions/throws.dart';
import 'package:common/logger/logger.dart';
import 'package:postgres/postgres.dart';
import 'package:server/postgres/exceptions/database_exception.dart';

final class PostgresService {
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
}
