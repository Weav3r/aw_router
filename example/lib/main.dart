// example/main.dart

import 'dart:typed_data' show Uint8List;

import 'package:aw_router/aw_router.dart' as awr;
import 'package:awr_example/routers/response_types_router.dart';
import 'middleware/introspection.dart';
import 'middleware/logging.dart';
import 'middleware/auth.dart';
import 'middleware/response_wrapper.dart';
import 'middleware/normalize_trailing_slash.dart';
import 'routers/appwrite_router.dart';
import 'routers/product_router.dart';
import 'routers/user_router.dart';
import 'routers/auth_router.dart';

/// The main entry point for the application.
/// Sets up the root router and mounts all route pipelines with relevant middleware.
Future<dynamic> main(final context) async {
  try {
    // Create the root router instance.
    // final rootRouter = awr.Router(context);
    final rootRouter =
        awr.Router(context, fallbackLogLevel: awr.LogLevel.verbose);

    // Product routes with full middleware pipeline
    // Middleware includes: strip trailing slashes, logging, auth, and response wrapping
    final productPipeline = awr.Pipeline()
        .addMiddleware(wrapWithIntrospection(
            awr.awrLogMiddleware(
                level: awr.LogLevel.warning,
                logFn: rootRouter.log,
                errorFn: rootRouter.error),
            'awrLog'))
        .addMiddleware(wrapWithIntrospection(
            stripTrailingSlashMiddleware, 'stripTrailingSlash'))
        .addMiddleware(wrapWithIntrospection(authMiddleware, 'auth'))
        .addMiddleware(
            wrapWithIntrospection(responseWrapperMiddleware, 'responseWrapper'))
        .handler(ProductRouter(context).router.call);

    // User routes pipeline
    final userPipeline = awr.Pipeline()
        .addMiddleware(stripTrailingSlashMiddleware)
        .addMiddleware(exampleLogMiddleware)
        .addMiddleware(authMiddleware)
        .addMiddleware(responseWrapperMiddleware)
        .handler(UserRouter(context).router.call);

    // Auth routes pipeline (no auth middleware)
    final authPipeline = awr.Pipeline()
        .addMiddleware(stripTrailingSlashMiddleware)
        .addMiddleware(exampleLogMiddleware)
        .addMiddleware(responseWrapperMiddleware)
        .handler(AuthRouter(context).router.call);

    final appwritePipeline = awr.Pipeline()
        .addMiddleware(wrapWithIntrospection(
            stripTrailingSlashMiddleware, 'stripTrailing'))
        .addMiddleware(
            wrapWithIntrospection(exampleLogMiddleware, 'exampleLog'))
        .addMiddleware(
            wrapWithIntrospection(responseWrapperMiddleware, 'wrapResponse'))
        .handler(AppwriteRouter(context).router.call);

    // Mount all pipelines to their respective root paths
    rootRouter.mount('/products', productPipeline);
    rootRouter.mount('/users', userPipeline);
    rootRouter.mount('/auth', authPipeline);
    rootRouter.mount('/appwrite', appwritePipeline);

    // Mount routers without middleware
    rootRouter.mount('/responses', ResponseTypesRouter(context).router.call);

    rootRouter.group('/api/v1', middlewares: [
      wrapWithIntrospection(
          (handler) => (request) async {
                request.logDebug('Middleware for /api/v1 group applied.');
                return await handler(request);
              },
          'group-middleware'),
    ], (v1) {
      // All routes/mounts here are under /api/v1 and have the above middleware

      v1.get('/users/<userName>/whoami', (awr.Request req) {
        final userName = req
            .routeParams['userName']; // Access parameters via req.routeParams
        req.logInfo('${req.query}');
        req.logInfo('${req.routeParams}');
        return awr.Response.ok('You are $userName');
      });
      v1.get('/users', (awr.Request req) {
        return awr.Response.ok('List of users from /api/v1/users');
      });
      v1.get('/users/<x|[a-z]?>eet', (awr.Request req, String x) {
        return awr.Response.ok('You are a ${x.toUpperCase()}EEET!!');
      });

      v1.post('/users', (awr.Request req) {
        return awr.Response(code: 201, body: 'User created at /api/v1/users');
      });

      // Nested Group: /api/v1/admin
      v1.group('/admin', middlewares: [
        wrapWithIntrospection(
            (handler) => (request) async {
                  request
                      .logDebug('Middleware for /api/v1/admin group applied.');
                  // Simulate admin-specific auth check
                  if (request.headers['x-admin-key'] != 'super-secret') {
                    return awr.Response(
                        code: 401, body: 'Admin key missing or invalid');
                  }
                  return await handler(request);
                },
            'admin-key'),
      ], (v1Admin) {
        v1Admin.get('/settings', (awr.Request req) {
          return awr.Response.ok('Admin settings from /api/v1/admin/settings');
        });

        v1Admin.get('/dashboard', (awr.Request req) {
          req.logDebug('${req.context}');
          return awr.Response.ok(
              'Admin dashboard from /api/v1/admin/dashboard');
        });
      });

      v1.get('/products/<id>', (awr.Request req, String productId) {
        return awr.Response.ok(
            'Product details for ID: $productId from /api/v1/products/$productId');
      });
    });
    // Plain text/html response
    rootRouter.get('/html', middlewares: [exampleLogMiddleware],
        (awr.Request req) {
      return awr.Response.ok('<h1>This is a heading 1</h1>', headers: {
        'Content-Type': 'text/html',
      });
    });

    // Catch-all route for any unmatched request paths
    rootRouter.all('/<root_ignore|.*>', (awr.Request req) {
      return awr.Response(code: 404, body: {'error': 'Not Found'});
    });

    // Parse the incoming request and pass data/resources around using context
    final req = awr.Request.parse(
        context.req); //.copyWith(context: {'log': context.log});

    // Route the request through the root router
    final res = await rootRouter.call(req);

    // Alternatively, apply one or more middleware layers (e.g., logging)
    // to the rootRouter before handling the request:
    // final awr.Response res = await awr.Pipeline()
    //     // .addMiddleware(logMiddleware)
    //     .addMiddleware(awr.awrLogMiddleware(
    //         level: awr.LogLevel.debug,
    //         logFn: rootRouter.log,
    //         errorFn: rootRouter.error))
    //     .handler(rootRouter.call)(req);

    // context.log('Response: ${res.body}');
// return the runtime response
    return res.runtimeResponse(context.res);
  } catch (e, st) {
    // Global error handler for catching unexpected failures
    context.error('Server Error: $e\n$st');
    return context.res.empty();
  }
}
