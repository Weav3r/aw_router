import 'logger.dart';

enum LogLevel {
  verbose,
  debug,
  info,
  warning,
  error,
  none, // For disabling logging
}

class DefaultLogger implements Logger {
  final bool isFallback;
  final LogLevel minimumLevel;
  final void Function(String message) _logFn;
  final void Function(String message) _errorFn;
  static bool _logFnWarn = false;
  static bool _logFnError = false;

  DefaultLogger({
    this.isFallback = false,
    this.minimumLevel = LogLevel.info,
    void Function(String)? logFn,
    void Function(String)? errorFn,
  })  : _logFn = logFn ??
            ((msg) {
              if (!_logFnWarn) {
                print(
                    '[WARN][DefaultLogger] logFn was not provided — using print.');
                _logFnWarn = true;
              }
              print(msg);
            }),
        _errorFn = errorFn ??
            ((msg) {
              if (!_logFnError) {
                print(
                    '[WARN][DefaultLogger] errorFn was not provided — using print.');
                _logFnError = true;
              }
              print(msg);
            });

  void _log(LogLevel level, String message,
      {dynamic error, StackTrace? stackTrace}) {
    if (level.index < minimumLevel.index) return;

    const isDebug = bool.fromEnvironment('dart.vm.product') == false;

    final levelLabel = level.name.toUpperCase();
    final timestamp = DateTime.now().toIso8601String();
    String logMessage = '[$timestamp] [$levelLabel] $message';
    logMessage = isDebug && isFallback ? '[fallback] $logMessage' : logMessage;

    // Use error sink if severity is high enough and errorFn is provided
    if ((level == LogLevel.error || level == LogLevel.warning)) {
      _errorFn(logMessage);
    } else {
      _logFn(logMessage);
    }

    if (error != null) _logFn('Error: $error');
    if (stackTrace != null) _logFn('Stack: $stackTrace');
  }

  @override
  void verbose(String message, {dynamic error, StackTrace? stackTrace}) =>
      _log(LogLevel.verbose, message, error: error, stackTrace: stackTrace);

  @override
  void debug(String message, {dynamic error, StackTrace? stackTrace}) =>
      _log(LogLevel.debug, message, error: error, stackTrace: stackTrace);

  @override
  void info(String message, {dynamic error, StackTrace? stackTrace}) =>
      _log(LogLevel.info, message, error: error, stackTrace: stackTrace);

  @override
  void warning(String message, {dynamic error, StackTrace? stackTrace}) =>
      _log(LogLevel.warning, message, error: error, stackTrace: stackTrace);

  @override
  void error(String message, {dynamic error, StackTrace? stackTrace}) =>
      _log(LogLevel.error, message, error: error, stackTrace: stackTrace);
}
