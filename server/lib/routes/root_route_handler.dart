import 'dart:convert';
import 'dart:io';

import 'package:server/util/http_method.dart';
import 'package:server/util/json_response.dart';
import 'package:shelf/shelf.dart';

Future<Response> rootRouteHandler(Request request) async {
  final HttpMethod method = HttpMethod.fromString(request.method);

  return switch (method) {
    HttpMethod.get => JsonResponse(
      body: jsonEncode({
        'name': 'ChronoQuest API',
        'version': '1.0.0',
        'timestamp': DateTime.now().toUtc().toIso8601String(),
      }),
    ),
    _ => Response(HttpStatus.methodNotAllowed),
  };
}
