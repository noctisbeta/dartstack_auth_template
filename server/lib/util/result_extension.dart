import 'package:postgres/postgres.dart';
import 'package:server/postgres/exceptions/database_exception.dart';

extension ResultExtension on Result {
  void assertNotEmpty() {
    if (isEmpty) {
      throw const DBEemptyResult('Result is empty');
    }
  }
}
