// example/middleware/logging.dart

import 'package:aw_router/aw_router.dart' as awr;

/// A middleware that logs HTTP request and response details.
///
/// It expects a `log` function to be present in the request context.
/// When a request is received, it logs the HTTP method and path.
/// After the request is processed, it logs the response status code.
awr.RequestHandler logMiddleware(awr.RequestHandler handler) {
  return (awr.Request request) async {
    // Log the request method and path if a logger is provided in context.
    request.context['log']?.call('Log: ${request.method} ${request.path}');

    // Process the request.
    final res = await handler(request);

    // Log the response status code.
    request.context['log']?.call('Status: ${res.statusCode}');

    return res;
  };
}
