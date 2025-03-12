sealed class DatabaseException implements Exception {
  const DatabaseException(this.message);

  final String message;

  @override
  String toString() => 'DatabaseException: $message';
}

final class DBEuniqueViolation extends DatabaseException {
  const DBEuniqueViolation(super.message);
}

final class DBEunknown extends DatabaseException {
  const DBEunknown(super.message);
}

final class DBEbadCertificate extends DatabaseException {
  const DBEbadCertificate(super.message);
}

final class DBEbadSchema extends DatabaseException {
  const DBEbadSchema(super.message);
}

final class DBEemptyResult extends DatabaseException {
  const DBEemptyResult(super.message);
}
