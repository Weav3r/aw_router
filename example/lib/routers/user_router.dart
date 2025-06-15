// example/routers/user_router.dart

import 'package:aw_router/aw_router.dart' as awr;

class UserRouter {
  final dynamic context;
  UserRouter(this.context);

  awr.Router get router {
    final r = awr.Router(context, fallbackLogLevel: awr.LogLevel.debug);

    r.get('/me', (awr.AwRequest req) async {
      return awr.AwResponse.ok({'id': 'user-123', 'name': 'John Doe'});
    });

// Example requests:
// - {{host}}/users/hi+hey/role/moderator?permission=full&role=admin ✅ valid (matches [\w]+)
// - {{host}}/users/hi+hey/role/mod-erator?permission=full&role=admin ❌ invalid (hyphen in 'mod-erator' not matched by [\w]+)

    r.get('/<random>/role/<userRole|[\\w]+>',
        (awr.AwRequest req, String random, String userRole) async {
      // Handles GET requests to /<random>/role/<userRole>
      // where <userRole> must match the regular expression [\w]+ (alphanumeric and underscores only).
      //
      // Returns:
      // - a static user ID
      // - a message string composed from the dynamic path parameters
      // - all query parameters included in the request

      return awr.AwResponse.ok({
        'id': 'user-123',
        'path-param': 'Random is $random and role is $userRole',
        'query-params': req.query
      });
    });

    r.all('/<userR_ignored|.*>', (awr.AwRequest req) {
      return awr.AwResponse(body: {'error': 'Not Found in /users'});
    });

    return r;
  }
}
