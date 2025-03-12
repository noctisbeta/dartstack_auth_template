import 'dart:io';

import 'package:server/util/http_method.dart';
import 'package:server/util/json_response.dart';
import 'package:shelf/shelf.dart';

Future<Response> healthHandler(Request request) async {
  final method = HttpMethod.fromString(request.method);

  return switch (method) {
    HttpMethod.get => JsonResponse(
      body: {
        'status': 'UP',
        'timestamp': DateTime.now().toUtc().toIso8601String(),
      },
    ),
    _ => Response(HttpStatus.methodNotAllowed),
  };
}
