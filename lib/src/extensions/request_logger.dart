import '../logger.dart';
import '../request.dart';

extension RequestLogExtension on Request {
  void logInfo(String message) => _getLogger().info(message);
  void logDebug(String message) => _getLogger().debug(message);
  void logWarning(String message) => _getLogger().warning(message);
  void logError(String message, {dynamic error, StackTrace? stackTrace}) =>
      _getLogger().error(message, error: error, stackTrace: stackTrace);

  DefaultLogger _getLogger() {
    final logger = context['logger'];
    if (logger is! DefaultLogger) {
      throw ArgumentError(
        'Expected context["logger"] to be a DefaultLogger, '
        'but got: ${logger.runtimeType}. '
        'This likely means it was overridden incorrectly.',
      );
    }
    return logger;
  }
}
