import 'dart:convert';
import 'dart:io';

import 'package:shelf/shelf.dart';

final class JsonResponse extends Response {
  JsonResponse._({
    required Object? body,
    int statusCode = HttpStatus.ok,
    Map<String, Object>? headers,
  }) : super(
         statusCode,
         body: jsonEncode(body),
         headers: {
           HttpHeaders.contentTypeHeader: ContentType.json.toString(),
           if (headers != null) ...headers,
         },
       );

  // Named constructors for common status codes
  JsonResponse.ok({Object? body, Map<String, Object>? headers})
    : this._(body: body, statusCode: HttpStatus.ok, headers: headers);

  JsonResponse.created({Object? body, Map<String, Object>? headers})
    : this._(body: body, statusCode: HttpStatus.created, headers: headers);

  JsonResponse.badRequest({Object? body, Map<String, Object>? headers})
    : this._(body: body, statusCode: HttpStatus.badRequest, headers: headers);

  JsonResponse.notFound({Object? body, Map<String, Object>? headers})
    : this._(body: body, statusCode: HttpStatus.notFound, headers: headers);

  JsonResponse.unauthorized({Object? body, Map<String, Object>? headers})
    : this._(body: body, statusCode: HttpStatus.unauthorized, headers: headers);

  JsonResponse.internalServerError({Object? body, Map<String, Object>? headers})
    : this._(
        body: body,
        statusCode: HttpStatus.internalServerError,
        headers: headers,
      );

  JsonResponse.forbidden({Object? body, Map<String, Object>? headers})
    : this._(body: body, statusCode: HttpStatus.forbidden, headers: headers);

  JsonResponse.conflict({Object? body, Map<String, Object>? headers})
    : this._(body: body, statusCode: HttpStatus.conflict, headers: headers);

  JsonResponse.other({
    required int statusCode,
    Object? body,
    Map<String, Object>? headers,
  }) : this._(body: body, statusCode: statusCode, headers: headers);
}
