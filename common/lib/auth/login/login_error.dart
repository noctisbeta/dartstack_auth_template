enum LoginError {
  wrongPassword,
  userNotFound,
  unknownLoginError;

  factory LoginError.fromString(String name) {
    switch (name) {
      case 'wrongPassword':
        return LoginError.wrongPassword;
      case 'userNotFound':
        return LoginError.userNotFound;
      case 'unknownLoginError':
        return LoginError.unknownLoginError;
      default:
        throw ArgumentError('Invalid LoginError: $name');
    }
  }

  @override
  String toString() => switch (this) {
    LoginError.wrongPassword => 'wrongPassword',
    LoginError.userNotFound => 'userNotFound',
    LoginError.unknownLoginError => 'unknownLoginError',
  };
}
