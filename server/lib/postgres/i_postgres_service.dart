import 'package:common/annotations/throws.dart';
import 'package:postgres/postgres.dart';
import 'package:server/postgres/database_exception.dart';

abstract interface class IPostgresService {
  @Throws([DatabaseException])
  Future<Result> execute(Sql query, {Map<String, dynamic>? parameters});

  Future<T> executeAndMap<T>({
    required Sql query,
    required T Function(Map<String, dynamic>) mapper,
    required String emptyResultMessage,
    Map<String, dynamic>? parameters,
  });

  @Throws([DatabaseException])
  Future<R> runTx<R>(
    Future<R> Function(TxSession sess) fn, {
    TransactionSettings? settings,
  });

  Future<bool> isHealthy();
}
