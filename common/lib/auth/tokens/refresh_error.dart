enum RefreshError {
  expired,
  compromised,
  revoked,
  unknownRefreshError;

  factory RefreshError.fromString(String name) {
    switch (name) {
      case 'expired':
        return RefreshError.expired;
      case 'compromised':
        return RefreshError.compromised;
      case 'revoked':
        return RefreshError.revoked;
      case 'unknownRegisterError':
        return RefreshError.unknownRefreshError;
      default:
        throw ArgumentError('Invalid RefreshError: $name');
    }
  }

  @override
  String toString() => switch (this) {
    RefreshError.expired => 'expired',
    RefreshError.compromised => 'compromised',
    RefreshError.revoked => 'revoked',
    RefreshError.unknownRefreshError => 'unknownRefreshError',
  };
}
