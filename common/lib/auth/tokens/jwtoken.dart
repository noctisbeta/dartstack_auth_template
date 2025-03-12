import 'dart:convert';

extension type JWToken._(String value) {
  JWToken.fromJwtString(String jwtString) : value = jwtString;

  String get headerBase64 => value.substring(0, value.indexOf('.'));

  String get payloadBase64 =>
      value.substring(value.indexOf('.') + 1, value.lastIndexOf('.'));

  String get signatureBase64 => value.substring(value.lastIndexOf('.') + 1);

  static const expirationDuration = Duration(seconds: 15);

  int getUserId() {
    final Map<String, dynamic> payload = _decodePayload();
    if (!payload.containsKey('user_id')) {
      throw Exception('Invalid JWT: Missing "user_id" claim');
    }
    return payload['user_id'] as int;
  }

  bool isExpired() {
    final Map<String, dynamic> payload = _decodePayload();
    if (!payload.containsKey('exp')) {
      throw Exception('Invalid JWT: Missing "exp" claim');
    }
    final int expiryTimestamp = payload['exp'];
    final DateTime expiryDate = DateTime.fromMillisecondsSinceEpoch(
      expiryTimestamp * 1000,
    );
    return DateTime.now().isAfter(expiryDate);
  }

  bool isValid() => !isExpired();

  Map<String, dynamic> _decodePayload() {
    final String normalized = base64Url.normalize(payloadBase64);
    final String decoded = utf8.decode(base64Url.decode(normalized));
    return jsonDecode(decoded);
  }
}
