import '../logger.dart';
import '../middleware.dart';
import '../request.dart';

Middleware logMiddleware({
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
        'logger': logger,
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
