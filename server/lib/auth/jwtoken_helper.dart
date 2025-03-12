import 'dart:convert';
import 'dart:io';

import 'package:common/auth/tokens/jwtoken.dart';
import 'package:crypto/crypto.dart';

class JWTokenHelper {
  JWTokenHelper._();

  static JWToken getFromAuthorizationHeader(String authorizationHeader) {
    final List<String> parts = authorizationHeader.split(' ');

    if (parts.length != 2 || parts.first != 'Bearer') {
      throw Exception('Invalid authorization header');
    }

    return JWToken.fromJwtString(parts.last);
  }

  static JWToken createWith({required int userID}) {
    final String header = jsonEncode({'typ': 'JWT', 'alg': 'HS256'});
    final String headerBase64 = base64Url
        .encode(utf8.encode(header))
        .replaceAll('=', '');

    final int expirationTimestamp =
        DateTime.now()
            .toUtc()
            .add(JWToken.expirationDuration)
            .millisecondsSinceEpoch ~/
        1000;

    final String payload = jsonEncode({
      'user_id': userID,
      'exp': expirationTimestamp,
    });

    final String payloadBase64 = base64Url
        .encode(utf8.encode(payload))
        .replaceAll('=', '');

    final String signature = _generateSignature(headerBase64, payloadBase64);

    return JWToken.fromJwtString('$headerBase64.$payloadBase64.$signature');
  }

  static bool verifyToken(JWToken token) {
    final String signature = _generateSignature(
      token.headerBase64,
      token.payloadBase64,
    );

    if (signature != token.signatureBase64) {
      return false;
    }

    final Map<String, dynamic> payload = jsonDecode(
      utf8.decode(base64Url.decode(token.payloadBase64)),
    );
    final int expiryTimestamp = payload['exp'];
    final DateTime expiryDate =
        DateTime.fromMillisecondsSinceEpoch(expiryTimestamp * 1000).toUtc();

    return DateTime.now().toUtc().isBefore(expiryDate);
  }

  static String _generateSignature(String headerBase64, String payloadBase64) {
    final String? secret = Platform.environment['JWT_SECRET'];

    if (secret == null) {
      throw Exception('JWT_SECRET environment variable not set');
    }

    final hmac = Hmac(sha256, utf8.encode(secret));

    final Digest digest = hmac.convert(
      utf8.encode('$headerBase64.$payloadBase64'),
    );

    return base64Url.encode(digest.bytes).replaceAll('=', '');
  }
}
