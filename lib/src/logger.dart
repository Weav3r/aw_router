// lib/src/logger.dart (New File)

enum LogLevel {
  debug,
  info,
  warning,
  error,
  none, // For disabling logging
}

class DefaultLogger {
  final LogLevel minimumLevel;
  final void Function(String message) _logFn;
  final void Function(String message) _errorFn;

  DefaultLogger({
    this.minimumLevel = LogLevel.info,
    void Function(String)? logFn,
    void Function(String)? errorFn,
  })  : _logFn = logFn ??
            ((msg) {
              print(
                  '[WARN][DefaultLogger] logFn was not provided — using print.');
              print(msg);
            }),
        _errorFn = errorFn ??
            ((msg) {
              print(
                  '[WARN][DefaultLogger] errorFn was not provided — using print.');
              print(msg);
            });

  // DefaultLogger({
  //   this.minimumLevel = LogLevel.info,
  //   void Function(String message)? logFn,
  //   void Function(String message)? errorFn,
  // })  : _logFn = logFn ?? print,
  //       _errorFn = errorFn;

  void _log(LogLevel level, String message,
      {dynamic error, StackTrace? stackTrace}) {
    if (level.index < minimumLevel.index) return;

    final levelLabel = level.toString().split('.').last.toUpperCase();
    final timestamp = DateTime.now().toIso8601String();
    final logMessage = '[$timestamp] [$levelLabel] $message';

    // Use error sink if severity is high enough and errorFn is provided
    if ((level == LogLevel.error || level == LogLevel.warning) &&
        _errorFn != null) {
      _errorFn!(logMessage);
    } else {
      _logFn(logMessage);
    }

    if (error != null) _logFn('Error: $error');
    if (stackTrace != null) _logFn('Stack: $stackTrace');
  }

  void debug(String message, {dynamic error, StackTrace? stackTrace}) =>
      _log(LogLevel.debug, message, error: error, stackTrace: stackTrace);

  void info(String message, {dynamic error, StackTrace? stackTrace}) =>
      _log(LogLevel.info, message, error: error, stackTrace: stackTrace);

  void warning(String message, {dynamic error, StackTrace? stackTrace}) =>
      _log(LogLevel.warning, message, error: error, stackTrace: stackTrace);

  void error(String message, {dynamic error, StackTrace? stackTrace}) =>
      _log(LogLevel.error, message, error: error, stackTrace: stackTrace);
}
