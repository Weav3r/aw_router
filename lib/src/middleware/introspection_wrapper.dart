import 'package:aw_router/aw_router.dart';

enum IntrospectionTimeUnit {
  /// Automatically choose between microseconds and milliseconds based on elapsed time.
  auto,
  /// Always display time in microseconds (µs).
  microseconds,
  /// Always display time in milliseconds (ms).
  milliseconds,
}

/// Wraps a [middleware] with introspection logic for logging entry/exit and execution time.
///
/// [name] provides a human-readable identifier for the middleware in logs.
/// [timeUnit] allows specifying the preferred unit for displaying elapsed time,
/// overriding the automatic detection.
Middleware awrWrapWithIntrospection(
  Middleware middleware,
  String name, {
  IntrospectionTimeUnit timeUnit = IntrospectionTimeUnit.auto,
}) {
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

      String formattedTime;
      switch (timeUnit) {
        case IntrospectionTimeUnit.microseconds:
          formattedTime = '${stopwatch.elapsedMicroseconds}µs';
          break;
        case IntrospectionTimeUnit.milliseconds:
          formattedTime = '${stopwatch.elapsedMilliseconds}ms';
          break;
        case IntrospectionTimeUnit.auto:
          // Display in microseconds if less than 1ms, otherwise milliseconds
          if (stopwatch.elapsedMicroseconds < 1000) {
            formattedTime = '${stopwatch.elapsedMicroseconds}µs';
          } else {
            formattedTime = '${stopwatch.elapsedMilliseconds}ms';
          }
          break;
      }

      if (!calledNext) {
        request.logWarning('⚠️ Middleware "$name" short-circuited');
      }
      request.logInfo('◀ Exit: $name [$formattedTime]');
      return result;
    };
  };
}