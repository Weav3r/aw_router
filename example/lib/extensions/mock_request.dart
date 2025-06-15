import 'package:aw_router/aw_router.dart' show AwRequest;

/// Helper to create a mock [AwRequest] for testing with sensible defaults.
AwRequest mockRequest({
  String path = '/',
  String method = 'get',
  Map<String, String>? headers,
  String? bodyText,
  Map<String, dynamic>? bodyJson,
  Map<String, dynamic>? query,
  String? queryString,
  String scheme = 'https',
  String host = 'localhost',
  int port = 443,
  String? url,
  Map<String, dynamic>? context,
}) {
  url ??=
      '$scheme://$host$path${(queryString != null && queryString.isNotEmpty) ? '?$queryString' : ''}';
  return AwRequest(
    method: method,
    path: path,
    headers: headers ?? {},
    bodyText: bodyText ?? '',
    bodyJson: bodyJson ?? {},
    query: query ?? {},
    queryString: queryString ?? '',
    scheme: scheme,
    host: host,
    port: port,
    url: url,
    context: context ?? <String, dynamic>{},
  );
}
