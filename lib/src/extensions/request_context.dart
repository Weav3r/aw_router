import '../core/request.dart';

extension RequestContextUpdater on Request {
  /// Returns a new Request with an updated context.
  Request withContext(String key, dynamic value) {
    return copyWith(context: {...context, key: value});
  }

  /// Returns a new Request with a key removed from context.
  Request removeContext(String key) {
    final newContext = Map<String, dynamic>.from(context)..remove(key);
    return copyWith(context: newContext);
  }
}
