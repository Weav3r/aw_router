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
    r.post('/login', (awr.AwRequest req) async {
      final credentials = req.bodyJson;
      if (credentials['email'] == 'test@example.com' &&
          credentials['password'] == '123456') {
        return awr.AwResponse.ok({'token': 'valid-token'});
      }
      return awr.AwResponse(code: 401, body: {'error': 'Invalid credentials'});
    });

    r.all('/<authR_ignored|.*>', (awr.AwRequest req) {
      return awr.AwResponse(body: {'error': 'Not Found in /auth'});
    });

    return r;
  }
}
