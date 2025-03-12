import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';
import 'package:meta/meta.dart';

@immutable
final class Hasher {
  const Hasher();

  static const int _iterations = 10000;
  static const int _saltLength = 32;
  static const int _keyLength = 32;

  /// Hashes the given password with a generated salt using PBKDF2.
  /// Returns a map containing the hashed password and the salt.
  Future<({String hashedPassword, String salt})> hashPassword(
    String password,
  ) async {
    final String salt = _generateSalt();
    final String hashedPassword = await _hash(password, salt);

    return (hashedPassword: hashedPassword, salt: salt);
  }

  /// Verifies the given password against the hashed password and salt
  /// using PBKDF2.
  Future<bool> verifyPassword(
    String password,
    String hashedPassword,
    String salt,
  ) async {
    final String newHash = await _hash(password, salt);
    return newHash == hashedPassword;
  }

  /// Hashes the given password with the provided salt using PBKDF2.
  Future<String> _hash(String password, String salt) async {
    final pbkdf2 = Pbkdf2(
      macAlgorithm: Hmac.sha256(),
      iterations: _iterations,
      bits: _keyLength * 8,
    );

    final secretKey = SecretKey(utf8.encode(password));
    final Uint8List nonce = base64.decode(salt);

    final SecretKey newKey = await pbkdf2.deriveKey(
      secretKey: secretKey,
      nonce: nonce,
    );

    final List<int> newKeyBytes = await newKey.extractBytes();

    return base64.encode(newKeyBytes);
  }

  /// Generates a cryptographically secure random salt of the configured length.
  String _generateSalt() {
    final random = Random.secure();
    final salt = List<int>.generate(_saltLength, (_) => random.nextInt(256));

    return base64.encode(salt);
  }
}
