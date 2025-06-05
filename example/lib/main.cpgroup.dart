import 'dart:convert';

import 'package:aw_router/aw_router.dart';
import 'package:awr_example/extensions/mock_request.dart';

import 'middleware/auth.dart';
import 'middleware/introspection.dart';
import 'middleware/normalize_trailing_slash.dart';
import 'middleware/response_wrapper.dart';
import 'routers/product_router.dart';

void main() async {
  final router = Router(null, fallbackLogLevel: LogLevel.verbose);

  router.onNotFound((request) {
    request.logWarning(
        'Route not found for path: ${request.path} method: ${request.method}');
    return Response.notFound(
        message:
            'Sorry, the path "${request.path}" does not exist on this server.');
  });

  router.onError((request, error, stackTrace) {
    request.logError(
        'An unhandled exception occurred during request processing for path: ${request.path}',
        error: error,
        stackTrace: stackTrace);
    return Response.internalServerError(
        message: jsonEncode({
      'message': 'Oops! Something went wrong on our end.',
      'error_details': error.toString(),
    }));
  });

  final productPipeline = Pipeline()
      .addMiddleware(awrLogMiddleware())
      .addMiddleware(stripTrailingSlashMiddleware)
      .addMiddleware(authMiddleware)
      .addMiddleware(responseWrapperMiddleware)
      .handler(ProductRouter(null).router.call);

  // router.mount('/products', ProductRouter(null).router);
  router.mount('/products', productPipeline);
  router.get('/products/shoe', (req) {
    return Response.ok('I got the shoes');
  });
  router.get('/text/', middlewares: [awrLogMiddleware()], (Request req) {
    return Response.ok('Hello, text world!');
  });

  router.get('/trigger-error', (Request req) {
    req.logInfo('Attempting to trigger an error...');
    throw Exception('Simulated Internal Server Error for /trigger-error');
  });

  // --- Route Grouping Example using internal _GroupedRouter (router.dart v5) ---
  router.log('--- Testing Route Grouping ---');

  // Group 1: /api/v1 with shared middleware
  router.group('/api/v1', middlewares: [
    (handler) => (request) async {
          request.logDebug('Middleware for /api/v1 group applied.');
          return await handler(request);
        }
  ], (v1) {
    // All routes/mounts here are under /api/v1 and have the above middleware

    v1.get('/users/<userName>/whoami', (Request req) {
      final userName =
          req.routeParams['userName']; // Access parameters via req.routeParams
      req.logDebug('${req.query}');
      req.logDebug('${req.routeParams}');
      return Response.ok('You are $userName');
    });
    v1.get('/users', (Request req) {
      return Response.ok('List of users from /api/v1/users');
    });

    v1.post('/users', (Request req) {
      return Response(code: 201, body: 'User created at /api/v1/users');
    });
    v1.get('/users/<userName>/messages/<msgId|[\\d]+>',
        (req, String userName, String msgId) {
      // final userName = req.routeParams['userName'];
      // final msgId = req.routeParams['msgId'];
      final id = int.tryParse(msgId ?? ''); // Safely parse integer
      if (id == null) {
        return Response(code: 400, body: 'Invalid message ID');
      }
      return Response.ok('Message ID: $id from $userName');
    });

    // Nested Group: /api/v1/admin
    v1.group('/admin', middlewares: [
      wrapWithIntrospection(
          (handler) => (request) async {
                request.logDebug('Middleware for /api/v1/admin group applied.');
                // Simulate admin-specific auth check
                if (request.headers['x-admin-key'] != 'super-secret') {
                  return Response(
                      code: 401, body: 'Admin key missing or invalid');
                }
                return await handler(request);
              },
          'admin-key'),
    ], (v1Admin) {
      v1Admin.get('/settings', (Request req) {
        return Response.ok('Admin settings from /api/v1/admin/settings');
      });

      v1Admin.get('/dashboard', (Request req) {
        req.logDebug('${req.context}');
        return Response.ok('Admin dashboard from /api/v1/admin/dashboard');
      });
    });

    v1.get('/products/<id>', (Request req, String productId) {
      return Response.ok(
          'Product details for ID: $productId from /api/v1/products/$productId');
    });
  });

  // Test requests to grouped routes
  final rootRequest = mockRequest(path: '/text/');
  final rootResponse = await router.call(rootRequest);
  router.log(
      'GET /text/ Response: ${rootResponse.statusCode} - ${rootResponse.body}');
  router.log('\n');

  final prods = mockRequest(
      path: '/products/shoe', headers: {'authorization': 'valid-token'});
  final prodsResponse = await router.call(prods);
  router.log(
      'GET ${prods.path} Response: ${prodsResponse.statusCode} - ${prodsResponse.body}');
  router.log('\n');
  // return;

  final prodsHead = mockRequest(
      method: 'head',
      path: '/products/2',
      headers: {'authorization': 'valid-token'});
  final prodsHeadResponse = await router.call(prodsHead);
  router.log(
      '${prods.method.toUpperCase()} ${prods.path} Response: ${prodsHeadResponse.statusCode} - ${prodsHeadResponse.body} == ${prodsHeadResponse.headers}');
  router.log('\n');

  final userListRequest = mockRequest(path: '/api/v1/users');
  final userListResponse = await router.call(userListRequest);
  router.log(
      'GET /api/v1/users Response: ${userListResponse.statusCode} - ${userListResponse.body}');
  router.log('\n');

  final adminSettingsRequest = mockRequest(path: '/api/v1/admin/settings');
  final adminSettingsResponse = await router.call(adminSettingsRequest);
  router.log(
      'GET /api/v1/admin/settings Response (with key): ${adminSettingsResponse.statusCode} - ${adminSettingsResponse.body}');
  router.log('\n');

  return;

  final unauthorizedAdminRequest = mockRequest(
      path: '/api/v1/admin/dashboard',
      headers: {'x-admin-key': 'super-secret'});

  final unauthorizedAdminResponse = await router.call(unauthorizedAdminRequest);
  router.log(
      'GET /api/v1/admin/dashboard Response (without key): ${unauthorizedAdminResponse.statusCode} - ${unauthorizedAdminResponse.body}');
  router.log('\n');

  // router.get('', (Request req) {
  final usersBRequest = mockRequest(
      path: '/api/v1/users/sammy/messages/45',
      headers: {'x-admin-key': 'super-secret'});

  final usersBResponse = await router.call(usersBRequest);
  router.log(
      'GET /api/v1/users/sammy/whoami Response (without key): ${usersBResponse.statusCode} - ${usersBResponse.body}');
  router.log('\n');

  return;

  final productByIdRequest = mockRequest(path: '/api/v1/products/123');
  final productByIdResponse = await router.call(productByIdRequest);
  router.log(
      'GET /api/v1/products/123 Response: ${productByIdResponse.statusCode} - ${productByIdResponse.body}');
  router.log('\n');

  // --- Existing Error Handling Test Scenarios ---

  router.log('--- Testing 404 Not Found ---');
  final notFoundRequest = mockRequest(path: '/non-existent-route');
  final notFoundResponse = await router.call(notFoundRequest);
  router.log(
      '404 Response: ${notFoundResponse.statusCode} - ${notFoundResponse.body}');
  router.log('\n');

  router.log('--- Testing 500 Internal Server Error ---');
  final errorRequest = mockRequest(path: '/trigger-error');
  final errorResponse = await router.call(errorRequest);
  router
      .log('500 Response: ${errorResponse.statusCode} - ${errorResponse.body}');
  router.log('\n');
}
