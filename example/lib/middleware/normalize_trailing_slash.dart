import 'package:aw_router/aw_router.dart' as awr;

/// Middleware to normalize incoming request paths by removing trailing slashes.
///
/// This helps ensure route matching consistency, so that both `/products/` and
/// `/products` are treated as the same route.
///
/// - Logs the path before and after normalization (if a logger is available in the context).
/// - Only removes trailing slashes if the path is not the root `/`.
awr.RequestHandler stripTrailingSlashMiddleware(awr.RequestHandler handler) {
  return (awr.AwRequest request) async {
    final path = request.path;

    // Optional logging for debugging before normalization
    request.logInfo('NORMALISE BEFORE: ${request.path}');

    // Remove trailing slashes except for the root path
    final isTrailing = path != '/' && path.endsWith('/');
    request.logInfo('NORMALISE IS TRAILING: $isTrailing');

    final normalizedPath = path != '/' && path.endsWith('/')
        ? path.replaceAll(RegExp(r'/+$'), '')
        : path;

    // Create a new request with the normalized path
    final updated = request.copyWith(path: normalizedPath);

    // Optional logging after normalization
    updated.logInfo('NORMALISE AFTER: ${updated.path}');

    // Proceed to the next handler with the updated request
    return handler(updated);
  };
}
