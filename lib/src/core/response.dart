import 'dart:collection';
import 'dart:typed_data';

/// Represents an HTTP response within the `aw_router` framework.
///
/// This class encapsulates the status code, body, headers, and an optional
/// redirect location for a response. It's designed to be passed around
/// internally within your router and middleware pipeline.
class AwResponse {
  final int _statusCode;
  final Object? _body;
  final Map<String, dynamic> _headers;
  final String? _redirectLocation;

  /// A special sentinel response indicating that no route matched the request.
  ///
  /// This helps differentiate an intentionally handled "not found" response
  /// from a result where no route was found at all.
  static final routeNotFound = _NoRouteMatchResponse();

  /// Private constructor for [AwResponse]. Use factory constructors for creation.
  AwResponse._(this._body, this._statusCode,
      Map<String, dynamic>? responseHeaders, this._redirectLocation)
      : _headers = responseHeaders ?? {};

  /// Creates a generic [AwResponse] instance.
  ///
  /// Defaults to a 404 Not Found status code if [code] is not provided.
  factory AwResponse({Object? body, int? code, Map<String, dynamic>? headers}) {
    return AwResponse._(body, code ?? 404, headers, null);
  }

  /// Creates a 200 OK [AwResponse].
  factory AwResponse.ok(Object? body, {Map<String, dynamic>? headers}) =>
      AwResponse._(body, 200, headers, null);

  /// Creates a 404 Not Found [AwResponse] with an optional `message`.
  factory AwResponse.notFound(
          {String message = 'Not Found', Map<String, dynamic>? headers}) =>
      AwResponse._(message, 404, headers, null);

  /// Creates a 500 Internal Server Error [AwResponse] with an optional `message`.
  factory AwResponse.internalServerError(
          {String message = 'Internal Server Error',
          Map<String, dynamic>? headers}) =>
      AwResponse._(message, 500, headers, null);

  /// Creates a redirect [AwResponse] (e.g., 302) to `url`.
  factory AwResponse.redirect(String url,
          {int code = 302, Map<String, dynamic>? headers}) =>
      AwResponse._('Redirecting to $url', code, headers, url);

  /// Creates a new [AwResponse] instance by modifying existing properties.
  ///
  /// This method allows you to change the [body], [code], [headers],
  /// and [redirectLocation] of the current response. It intelligently handles
  /// redirect logic:
  /// - An explicitly provided `redirectLocation` takes precedence.
  /// - If the new status code isn't 3xx, any existing or inferred redirect
  ///   location is cleared.
  /// - If the new status code is 3xx and the new body is a URL string,
  ///   the `redirectLocation` is inferred if not explicitly set.
  AwResponse modify({
    Object? body,
    int? code,
    Map<String, dynamic>? headers,
    String? redirectLocation,
  }) {
    final newCode = code ?? _statusCode;
    final newBody = body ?? _body;

    String? updatedRedirectLocation;

    // 1. Explicit override/unset takes highest precedence
    if (redirectLocation != null) {
      updatedRedirectLocation = redirectLocation;
    } else {
      // 2. Propagate existing redirect if still a 3xx status
      if (_redirectLocation != null && (newCode >= 300 && newCode < 400)) {
        updatedRedirectLocation = _redirectLocation;
      }
      // 3. Infer redirect if new code is 3xx and body is a URL string
      else if (newBody is String && (newCode >= 300 && newCode < 400)) {
        // Simple runtime check if string body looks like a URL
        if (newBody.startsWith(RegExp(r'https?://'))) {
          updatedRedirectLocation = newBody;
        } else {
          updatedRedirectLocation = null; // String body is not a URL
        }
      } else {
        // Clear redirect if code not 3xx or body not a URL
        updatedRedirectLocation = null;
      }
    }

    return AwResponse._(
        newBody, newCode, headers ?? _headers, updatedRedirectLocation);
  }

  /// Converts this `aw_router` [AwResponse] into a framework-specific response format.
  ///
  /// This method is crucial for adapting the internal `Response` object
  /// to the format expected by the underlying Appwrite (or other) function
  /// runtime. It handles different body types (String, Map, Uint8List)
  /// and redirect responses.
  dynamic runtimeResponse(dynamic response) {
    if (_redirectLocation != null && _statusCode >= 300 && _statusCode < 400) {
      return response.redirect(_redirectLocation!, _statusCode);
    }

    return switch (_body) {
      String s => response.text(s, _statusCode, _headers),
      Map _ => response.json(_body, _statusCode, _headers),
      Uint8List _ => response.binary(_body, _statusCode, _headers),
      _ => () {
          print("Empty response");
          return response.empty(); // Ensure empty() is called and returned
        }()
    };
  }

  /// The body of the HTTP response.
  Object? get body => _body;

  /// The HTTP status code of the response.
  int? get statusCode => _statusCode;

  /// The HTTP headers of the response, provided as an unmodifiable map.
  Map<String, dynamic> get headers => UnmodifiableMapView(_headers);

  @override
  String toString() =>
      'Response(statusCode: $_statusCode, body: $_body, redirectLocation: $_redirectLocation)';
}

/// A special internal [AwResponse] subclass used as a sentinel for "no route matched".
///
/// This class is not intended for direct instantiation or modification outside
/// of its specific use case within the router. Its `modify` method is overridden
/// to preserve its sentinel property if no actual changes are requested.
class _NoRouteMatchResponse extends AwResponse {
  /// Creates a [_NoRouteMatchResponse] instance.
  ///
  /// Uses a distinct status code (999) to signify its special nature.
  _NoRouteMatchResponse() : super._(null, 999, {}, null);

  @override
  AwResponse modify({
    Map<String, Object?>? headers,
    Object? body,
    int? code,
    String? redirectLocation,
  }) {
    // If no actual changes are requested, return the sentinel itself
    // to maintain its "no route match" identity.
    if (body == null &&
        headers == null &&
        code == null &&
        redirectLocation == null) {
      return this;
    }
    // Otherwise, create a new regular Response based on the sentinel's properties
    // and the requested modifications.
    return super.modify(
        headers: headers,
        code: code,
        body: body,
        redirectLocation: redirectLocation);
  }
}
