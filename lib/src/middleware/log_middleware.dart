import 'package:aw_router/aw_router.dart';

/// Logs HTTP method, path, response code and duration.
/// Useful for local development or debugging.
Middleware logMiddleware = (RequestHandler next) {
  return (Request req) async {
    final stopwatch = Stopwatch()..start();
    try {
      print('core middleware called');
      final res = await next(req);
      final duration = stopwatch.elapsedMilliseconds;
      print('[${req.method}] ${req.url} => ${res.statusCode} (${duration}ms)');
      print('[${req.method}] ${req.path} => ${res.statusCode} (${duration}ms)');
      return res;
    } catch (e, st) {
      final duration = stopwatch.elapsedMilliseconds;
      print('[${req.method}] ${req.url} => ERROR (${duration}ms)\n$e\n$st');
      print('[${req.method}] ${req.path} => ERROR (${duration}ms)\n$e\n$st');
      rethrow;
    }
  };
};
