import 'dart:io';

import 'package:common/auth/tokens/jwtoken.dart';
import 'package:server/auth/jwtoken_helper.dart';
import 'package:server/util/context_key.dart';
import 'package:shelf/shelf.dart';

Middleware jwtMiddlewareProvider() =>
    (Handler handler) => (request) async {
      final String? authorizationHeader =
          request.headers[HttpHeaders.authorizationHeader];

      if (authorizationHeader == null ||
          !authorizationHeader.startsWith('Bearer ')) {
        return Response(HttpStatus.unauthorized, body: 'Unauthorized');
      }

      final JWToken token = JWTokenHelper.getFromAuthorizationHeader(
        authorizationHeader,
      );

      if (token.isExpired()) {
        return Response(HttpStatus.unauthorized, body: 'Token expired');
      }

      try {
        final bool isVerified = JWTokenHelper.verifyToken(token);

        if (!isVerified) {
          return Response(HttpStatus.unauthorized, body: 'Invalid token');
        }

        final int userId = token.getUserId();

        final Request newRequest = request.change(
          context: {ContextKey.userId.keyString: userId},
        );

        return await handler(newRequest);
      } on Exception catch (e) {
        return Response(HttpStatus.unauthorized, body: 'Invalid token: $e');
      }
    };
