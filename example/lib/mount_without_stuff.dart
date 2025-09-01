import 'package:aw_router/aw_router.dart';

typedef RequestHandler = FutureOr<AwResponse> Function(AwRequest req);

/// Mounts a sub-router or handler at a dynamic or static prefix,
/// forwarding the remaining unmatched path as the request's new path.
/// 
/// Example usage:
///   mountWithRemainingPath(router, '/<userId|[a-z0-9]+>/posts/', (req) {
///     final userId = req.routeParams['userId'];
///     // req.routeParams['path'] is the rest after the prefix.
///     final subRequest = req.copyWith(path: req.routeParams['path'] ?? '');
///     return PostsRouter(userId).router.call(subRequest);
///   });
void mountWithRemainingPath(
  Router router,
  String prefix,
  RequestHandler handler,
) {
  final normalizedPrefix = normalizePath(prefix);
  // The trailing slash is optional; if missing, add both variants.
  if (normalizedPrefix.endsWith('/')) {
    router.all('$normalizedPrefix<path|[^]*>', (AwRequest req) {
      final path = req.routeParams['path'] ?? '';
      final subRequest = req.copyWith(path: path);
      return handler(subRequest);
    });
  } else {
    // Exact match (no remaining path)
    router.all(normalizedPrefix, (AwRequest req) {
      final subRequest = req.copyWith(path: '');
      return handler(subRequest);
    });
    // Prefix match (with remaining path)
    router.all('$normalizedPrefix/<path|[^]*>', (AwRequest req) {
      final path = req.routeParams['path'] ?? '';
      final subRequest = req.copyWith(path: path);
      return handler(subRequest);
    });
  }
}