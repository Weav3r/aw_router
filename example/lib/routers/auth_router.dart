// example/routers/auth_router.dart

import 'package:aw_router/aw_router.dart' as awr;

/// A router class that handles authentication-related routes.
class AuthRouter {
  /// The shared context passed from the main router, can be used to access
  /// shared resources like loggers, databases, etc.
  final dynamic context;

  /// Constructor accepting the shared context.
  AuthRouter(this.context);

  /// Returns a configured router with auth-related routes.
  awr.Router get router {
    final r = awr.Router(context);

    // POST /login
    // This endpoint expects a JSON body with 'email' and 'password' fields.
    // It performs a simple hardcoded authentication check.
    // On success, it returns a mock token. On failure, it returns a 401 error.
    r.post('/login', (awr.Request req) async {
      final credentials = req.bodyJson;
      if (credentials['email'] == 'test@example.com' &&
          credentials['password'] == '123456') {
        return awr.Response.ok({'token': 'valid-token'});
      }
      return awr.Response(code: 401, body: {'error': 'Invalid credentials'});
    });

    r.all('/<authR_ignored|.*>', (awr.Request req) {
      return awr.Response(body: {'error': 'Not Found in /auth'});
    });

    return r;
  }
}
