import 'dart:collection';

import 'package:aw_router/src/utils/util.dart';

/// {@template my_request}
/// A class that represents the request object.
/// {@endtemplate}
class Request {
  /// {@macro my_request}
  Request({
    required this.bodyText,
    required this.bodyJson,
    required this.headers,
    required this.scheme,
    required this.method,
    required this.url,
    required this.host,
    required this.port,
    required this.path,
    required this.queryString,
    required this.query,
    required Map<String, dynamic> context,
    Map<String, dynamic> routeParams = const <String, dynamic>{},
  })  : _routeParams = routeParams,
        context = UnmodifiableMapView(context);

  static Map<String, dynamic> _getBodyJson(dynamic request) {
    try {
      return request.bodyJson;
    } catch (_) {
      return {};
    }
  }

  /// Parsing the Request from Appwrite,
  factory Request.parse(dynamic req) {
    return Request(
      bodyText: req.bodyRaw as String,
      bodyJson: _getBodyJson(req),
      headers: req.headers as Map<String, dynamic>,
      scheme: req.scheme as dynamic,
      method: req.method as String,
      url: req.url as String,
      host: req.host as String,
      port: req.port as int,
      path: req.path as String,
      queryString: req.queryString as String,
      query: req.query as Map<String, dynamic>,
      context: <String, dynamic>{},
    );
  }

  /// The raw body of the request as String.
  final String bodyText;

  /// The body of the request as Map.
  final Map<String, dynamic> bodyJson;

  /// The headers of the request.
  final Map<String, dynamic> headers;

  /// The scheme of the request.
  final dynamic scheme;

  /// The method of the request.
  String method;

  /// The url of the request.
  final String url;

  /// The host of the request.
  final String host;

  /// The port of the request.
  final int port;

  /// The path of the request.
  String path;

  /// The query string of the request.
  final String queryString;

  /// The query of the request.
  final Map<String, dynamic> query;

  /// The context of the request. Maninly used to pass variables
  /// to next() function i.e. middleware/handlers
  final Map<String, dynamic> context;

  /// The map of matched parameters in the route url
  /// Note this is not the same as query parameters (filter parameters)
  final Map<String, dynamic> _routeParams;

  UnmodifiableMapView<String, dynamic> get routeParams =>
      UnmodifiableMapView(_routeParams);

  Map<String, dynamic> _modifyContext(Map<String, dynamic>? updates) =>
      updateMap<String, dynamic>(context, updates);

  /// Copy with
  Request copyWith({
    String? bodyText,
    Map<String, dynamic>? bodyJson,
    Map<String, dynamic>? headers,
    dynamic scheme,
    String? method,
    String? url,
    String? host,
    int? port,
    String? path,
    String? queryString,
    Map<String, dynamic>? query,
    Map<String, dynamic>? context,
    Map<String, dynamic>? routeParams,
  }) {
    return Request(
      bodyText: bodyText ?? this.bodyText,
      bodyJson: bodyJson ?? this.bodyJson,
      headers: headers ?? this.headers,
      scheme: scheme ?? this.scheme,
      method: method ?? this.method,
      url: url ?? this.url,
      host: host ?? this.host,
      port: port ?? this.port,
      path: path ?? this.path,
      queryString: queryString ?? this.queryString,
      query: query ?? this.query,
      context: _modifyContext(context), // context ?? this.context,
      routeParams: routeParams ?? _routeParams,
    );
  }

  @override
  String toString() {
    return '''
Request(
bodyText: $bodyText,
bodyJson: $bodyJson,
headers: $headers,
scheme: $scheme,
url: $url,
host: $host,
port: $port,
path: $path,
queryString: $queryString,
query: $query,
context: $context,
routeParams: $_routeParams,
)''';
  }
}
