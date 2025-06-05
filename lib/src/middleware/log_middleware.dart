import '../utils/constants.dart';
import '../logger/default_logger.dart';
import '../core/middleware.dart';
import '../core/request.dart';

/// Injects a [Logger] into the request context and logs request details.
///
/// Configures the logger with `level`, optional `logFn`, and `errorFn`.
/// Logs request method, path, response status, and duration.
Middleware awrLogMiddleware({
  LogLevel level = LogLevel.debug,
  void Function(String message)? logFn,
  void Function(String message)? errorFn,
}) {
  return (handler) {
    return (Request request) async {
      final stopwatch = Stopwatch()..start();
      final logger = DefaultLogger(
        minimumLevel: level,
        logFn: logFn,
        errorFn: errorFn,
      );

      final updatedRequest = request.copyWith(context: {
        ...request.context,
        ctxLoggerKey: logger,
      });

      final response = await handler(updatedRequest);
      stopwatch.stop();

      logger.info(
        'Request: ${request.method} ${request.path} | '
        'Status: ${response.statusCode} | '
        'Duration: ${stopwatch.elapsedMilliseconds}ms',
      );

      return response;
    };
  };
}
