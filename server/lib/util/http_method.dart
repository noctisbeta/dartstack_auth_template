enum HttpMethod {
  get('GET'),
  post('POST'),
  put('PUT'),
  patch('PATCH'),
  delete('DELETE'),
  head('HEAD'),
  options('OPTIONS'),
  trace('TRACE'),
  connect('CONNECT');

  const HttpMethod(this.method);

  factory HttpMethod.fromString(String method) => HttpMethod.values.firstWhere(
    (e) => e.method == method.toUpperCase(),
    orElse: () => throw ArgumentError('Unsupported HTTP method: $method'),
  );

  final String method;
}
