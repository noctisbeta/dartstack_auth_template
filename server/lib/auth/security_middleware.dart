import 'dart:io';

import 'package:server/util/http_method.dart';
import 'package:shelf/shelf.dart';

Middleware securityMiddleware() =>
    (Handler handler) => (Request request) async {
      final method = HttpMethod.fromString(request.method);

      final String? origin = request.headers['origin'];

      final Map<String, String> corsHeaders = {
        'Access-Control-Allow-Origin': origin ?? '',
        'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, OPTIONS, HEAD',
        'Access-Control-Allow-Headers':
            'Content-Type, Authorization, Referrer-Policy',
        'Access-Control-Allow-Credentials': 'true',
        'Access-Control-Expose-Headers': '*',
        'Referrer-Policy': 'no-referrer-when-cross-origin',
      };

      // Handle CORS preflight requests
      if (method == HttpMethod.options) {
        return Response(HttpStatus.noContent, headers: corsHeaders);
      }

      // Get the response from the handler
      final Response response = await handler(request);

      // Apply security headers to the response
      return Response(
        response.statusCode,
        body: response.read(),
        headers: {...response.headers, ..._securityHeaders, ...corsHeaders},
      );
    };

const _securityHeaders = {
  // HSTS - Force HTTPS
  'Strict-Transport-Security': 'max-age=31536000; includeSubDomains; preload',
  // Prevent MIME type sniffing
  'X-Content-Type-Options': 'nosniff',
  // Prevent clickjacking
  'X-Frame-Options': 'DENY',
  // Enable browser XSS filter
  'X-XSS-Protection': '1; mode=block',
  // CSP - Control allowed resources
  'Content-Security-Policy':
      "default-src 'self'; "
      "script-src 'self' 'unsafe-inline' 'unsafe-eval'; "
      "style-src 'self' 'unsafe-inline'; "
      "img-src 'self' data: https:; "
      "connect-src 'self' ws: wss: http: https:",
  'Referrer-Policy': 'strict-origin-when-cross-origin',
};
