// In response.dart

import 'dart:collection';
import 'dart:typed_data';

class Response {
  final int _statusCode;
  final Object? _body;
  final Map<String, dynamic> _headers;
  final String? _redirectLocation;

  Response._(this._body, this._statusCode,
      Map<String, dynamic>? responseHeaders, this._redirectLocation)
      : _headers = responseHeaders ?? {};

  factory Response({Object? body, int? code, Map<String, dynamic>? headers}) {
    return Response._(body, code ?? 404, headers, null);
  }

  factory Response.ok(Object? body, {Map<String, dynamic>? headers}) {
    return Response._(body, 200, headers, null);
  }

  /// Factory constructor for creating a 404 Not Found response.
  /// Optionally, a [message] can be provided for the response body.
  factory Response.notFound(
      {String message = 'Not Found', Map<String, dynamic>? headers}) {
    return Response._(message, 404, headers, null);
  }

  /// Factory constructor for creating a redirect response.
  /// This explicitly sets the redirect.
  factory Response.redirect(String url,
      {int code = 302, Map<String, dynamic>? headers}) {
    return Response._('Redirecting to $url', code, headers, url);
  }

  /// Method to modify the body, status code, and headers of the response.
  /// This method intelligently handles the `_redirectLocation` field:
  /// 1. If `redirectLocation` is explicitly provided, it takes precedence.
  /// 2. If the new status code is NOT a 3xx, `_redirectLocation` is cleared.
  /// 3. If the new body is a URL string and the new status code is 3xx,
  ///    and `_redirectLocation` wasn't explicitly set, it will be inferred.
  Response modify({
    Object? body,
    int? code,
    Map<String, dynamic>? headers,
    String? redirectLocation, // Added back to allow explicit override/unset
  }) {
    final newCode = code ?? _statusCode;
    final newBody = body ?? _body;

    String? updatedRedirectLocation;

    // 1. Explicit override/unset takes highest precedence
    if (redirectLocation != null) {
      // User provided a specific redirectLocation (or null to unset)
      updatedRedirectLocation = redirectLocation;
    } else {
      // No explicit override, so infer or propagate
      // 2. If current response is a redirect AND the new code is still 3xx, propagate existing redirectLocation
      if (_redirectLocation != null && (newCode >= 300 && newCode < 400)) {
        updatedRedirectLocation = _redirectLocation;
      }
      // 3. Otherwise, if new code is 3xx AND new body is a URL string, infer.
      // This covers cases where a non-redirect response is modified to be a redirect.
      else if (newBody is String && (newCode >= 300 && newCode < 400)) {
        // Simple runtime check to see if string body looks like a URL
        if (newBody.startsWith(RegExp(r'https?://'))) {
          updatedRedirectLocation = newBody;
        } else {
          // String body is not a URL, so no redirect
          updatedRedirectLocation = null;
        }
      } else {
        // In all other cases (e.g., code not 3xx, body not string/URL), clear redirect location
        updatedRedirectLocation = null;
      }
    }

    return Response._(
        newBody, newCode, headers ?? _headers, updatedRedirectLocation);
  }

  dynamic runtimeResponse(dynamic response) {
    if (_redirectLocation != null && _statusCode >= 300 && _statusCode < 400) {
      return response.redirect(_redirectLocation!, _statusCode);
    }

    return switch (_body) {
      String s => response.text(s, _statusCode, _headers),
      Map _ => response.json(_body, _statusCode, _headers),
      Uint8List _ => response.binary(_body, _statusCode, _headers),
      _ => response.empty(),
    };
  }

  Object? get body => _body;
  int? get statusCode => _statusCode;
  Map<String, dynamic> get headers => UnmodifiableMapView(_headers);

  @override
  String toString() =>
      'Response(statusCode: $_statusCode, body: $_body, redirectLocation: $_redirectLocation)';
}
