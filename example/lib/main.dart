// example/main.dart

import 'package:aw_router/aw_router.dart' as awr;
import 'middleware/logging.dart';
import 'middleware/auth.dart';
import 'middleware/response_wrapper.dart';
import 'middleware/normalize_trailing_slash.dart';
import 'routers/product_router.dart';
import 'routers/user_router.dart';
import 'routers/auth_router.dart';

/// The main entry point for the application.
/// Sets up the root router and mounts all route pipelines with relevant middleware.
Future<dynamic> main(final context) async {
  try {
    // Create the root router instance.
    final rootRouter = awr.Router(context);

    // Product routes with full middleware pipeline
    // Middleware includes: strip trailing slashes, logging, auth, and response wrapping
    final productPipeline = awr.Pipeline()
        .addMiddleware(stripTrailingSlashMiddleware)
        .addMiddleware(logMiddleware)
        .addMiddleware(authMiddleware)
        .addMiddleware(responseWrapperMiddleware)
        .handler(ProductRouter(context).router.call);

    // User routes pipeline
    final userPipeline = awr.Pipeline()
        .addMiddleware(stripTrailingSlashMiddleware)
        .addMiddleware(logMiddleware)
        .addMiddleware(authMiddleware)
        .addMiddleware(responseWrapperMiddleware)
        .handler(UserRouter(context).router.call);

    // Auth routes pipeline (no auth middleware)
    final authPipeline = awr.Pipeline()
        .addMiddleware(stripTrailingSlashMiddleware)
        .addMiddleware(logMiddleware)
        .addMiddleware(responseWrapperMiddleware)
        .handler(AuthRouter(context).router.call);

    // rootRouter.mount(
    //   '/users',
    //   stripTrailingSlashMiddleware(
    //     awr.Pipeline()
    //         .addMiddleware(logMiddleware)
    //         .addMiddleware(authMiddleware)
    //         .addMiddleware(responseWrapperMiddleware)
    //         .handler(UserRouter(context).router.call),
    //   ),
    // );

    // Mount all pipelines to their respective root paths
    rootRouter.mount('/products', productPipeline);
    rootRouter.mount('/users', userPipeline);
    rootRouter.mount('/auth', authPipeline);

    // Catch-all route for any unmatched request paths
    rootRouter.all('/<ignore|.*>', (awr.Request req) {
      return awr.Response(code: 404, body: {'error': 'Not Found'});
    });

    // Parse the incoming request and include logging context
    final req =
        awr.Request.parse(context.req).copyWith(context: {'log': context.log});

    // Route the request through the root router and return the runtime response
    final res = await rootRouter.call(req);
    context.log('Response: ${res.body}');
    return res.runtimeResponse(context.res);
  } catch (e, st) {
    // Global error handler for catching unexpected failures
    context.error('Server Error: $e\n$st');
    return context.res.empty();
  }
}
