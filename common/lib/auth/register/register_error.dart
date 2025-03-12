enum RegisterError {
  usernameAlreadyExists,
  unknownRegisterError;

  factory RegisterError.fromString(String name) {
    switch (name) {
      case 'usernameAlreadyExists':
        return RegisterError.usernameAlreadyExists;
      case 'unknownRegisterError':
        return RegisterError.unknownRegisterError;
      default:
        throw ArgumentError('Invalid RegisterError: $name');
    }
  }

  @override
  String toString() => switch (this) {
    RegisterError.usernameAlreadyExists => 'usernameAlreadyExists',
    RegisterError.unknownRegisterError => 'unknownRegisterError',
  };
}
