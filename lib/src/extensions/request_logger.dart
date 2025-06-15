import '../utils/constants.dart';
import '../logger/logger.dart';
import '../core/request.dart';

extension RequestLogExtension on AwRequest {
  static bool _globalMissingLoggerWarningEmitted = false;
  static const _loggerMissingWarning =
      '[aw_router] ⚠️ Logger is missing in Request.context. '
      'Add logMiddleware() or inject a logger manually.';

  void logInfo(String message) => _logger?.info(message);
  void logDebug(String message) => _logger?.debug(message);
  void logWarning(String message) => _logger?.warning(message);
  void logError(String message, {dynamic error, StackTrace? stackTrace}) =>
      _logger?.error(message, error: error, stackTrace: stackTrace);

  Logger? get _logger {
    final logger = context[ctxLoggerKey];
    const isDebug = bool.fromEnvironment('dart.vm.product') == false;

    if (logger == null) {
      if (!isDebug) return null;
      if (!_globalMissingLoggerWarningEmitted) {
        print(_loggerMissingWarning);
        _globalMissingLoggerWarningEmitted = true;
      }
      return null;
    }

    if (logger is! Logger) {
      throw ArgumentError(
        'Expected context["logger"] to be a Logger, '
        'but got: ${logger.runtimeType}. '
        'This likely means it was overridden incorrectly.',
      );
    }

    return logger;
  }

  // Optional: For testing purposes
  static void resetWarningStateForTesting() {
    _globalMissingLoggerWarningEmitted = false;
  }
}
