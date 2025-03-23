/// An enum that defines all available routes in the application.
enum RouterPath {
  auth('/auth'),
  dashboard('/dashboard');

  /// Creates a [RouterPath] with the given [path].
  const RouterPath(this.path);

  /// Returns a [RouterPath] from a given path string.
  factory RouterPath.fromPath(String path) => RouterPath.values.firstWhere(
    (route) => route.path == path,
    orElse: () => throw Exception('No route found for path: $path'),
  );

  /// The path value used for routing.
  final String path;
}
