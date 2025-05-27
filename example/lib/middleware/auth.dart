// example/middleware/auth.dart

import 'package:aw_router/aw_router.dart' as awr;

/// Middleware that checks if the incoming request contains a valid authorization token.
/// If the token is invalid or missing, it responds with a 401 Unauthorized status.
/// Otherwise, it forwards the request to the next handler in the pipeline.
awr.RequestHandler authMiddleware(awr.RequestHandler handler) {
  return (awr.Request request) async {
    // Retrieve the 'authorization' header from the request
    final authHeader = request.headers['authorization'];

    if (authHeader != 'valid-token') {
      return awr.Response(code: 401, body: {'error': 'Unauthorized'});
    }
    // If the token is valid, forward the request to the next handler
    return handler(request);
  };
}
