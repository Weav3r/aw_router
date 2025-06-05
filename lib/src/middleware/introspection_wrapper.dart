import 'package:aw_router/aw_router.dart';

/// Wraps a [middleware] with introspection logic for logging entry/exit and execution time.
///
/// [name] provides a human-readable identifier for the middleware in logs.
Middleware awrWrapWithIntrospection(Middleware middleware, String name) {
  return (RequestHandler next) {
    return (request) async {
      final stopwatch = Stopwatch()..start();
      request.logInfo('▶ Enter: $name');

      var calledNext = false;
      final result = await middleware((req) {
        calledNext = true;
        return next(req);
      })(request);

      stopwatch.stop();
      if (!calledNext) {
        request.logWarning('⚠️ Middleware "$name" short-circuited');
      }
      request.logInfo('◀ Exit: $name [${stopwatch.elapsedMilliseconds}ms]');
      return result;
    };
  };
}
