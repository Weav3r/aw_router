import '../core/request.dart';

extension RequestContextUpdater on AwRequest {
  /// Returns a new Request with an updated context.
  AwRequest withContext(String key, dynamic value) {
    return copyWith(context: {...context, key: value});
  }

  /// Returns a new Request with a key removed from context.
  AwRequest removeContext(String key) {
    return copyWith(context: {key: null});
  }
}
