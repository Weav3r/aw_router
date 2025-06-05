/// An abstract interface for wrapping different context objects used by the router.
///
/// This provides a unified way for the router to access the raw request object
/// and perform logging operations, decoupling the router from specific
/// underlying framework contexts.
abstract interface class RouterContext {
  /// The raw request object from the underlying framework or environment.
  dynamic get req;

  /// Logs an informational or debug message.
  void log(String message);

  /// Logs an error message.
  void error(String message);
}
