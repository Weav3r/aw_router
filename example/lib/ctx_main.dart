import 'package:aw_router/aw_router.dart';

import 'middleware/auth.dart';
import 'middleware/normalize_trailing_slash.dart';
import 'middleware/response_wrapper.dart';
import 'routers/product_router.dart';

void main() async {
  // final router = Router(null); // No context needed!
  final router =
      Router(null, fallbackLogLevel: LogLevel.debug); // No context needed!

// Construct a test request with all required fields
  final request = AwRequest(
    method: 'get',
    // path: '/users/123',
    // path: '/products/shoe',
    path: '/products/',
    // path: '/rmid/',
    // path: '/products/1/',
    // path: '/text',
    // headers: {'authorization': 'valid-token'},
    headers: {},
    bodyText: '',
    bodyJson: {
      "title": "Valid Product",
      "description": "Works great",
      "price": 29.99
    },
    query: {},
    queryString: '',
    scheme: 'https',
    host: 'localhost',
    port: 443,
    url: 'https://localhost/products/155',
    // url: 'https://localhost/text',
    context: <String, dynamic>{},
  );

  try {
    final productPipeline = Pipeline()
        .addMiddleware(awrWrapWithIntrospection(
            awrLogMiddleware(level: LogLevel.info), 'awrLog'))
        .addMiddleware(
            awrWrapWithIntrospection(stripTrailingSlashMiddleware, 'strip'))
        .addMiddleware(awrWrapWithIntrospection(authMiddleware, 'auth'))
        .addMiddleware(
            awrWrapWithIntrospection(responseWrapperMiddleware, 'responseWrapper'))
        .handler(ProductRouter(null).router.call);

    router.mount('/products', productPipeline);
    router.get('/products/shoe', (req) {
      return AwResponse.ok('I got the shoes');
    });

    router.get('/rmid', middlewares: [
      awrWrapWithIntrospection(stripTrailingSlashMiddleware, 'strip'),
      awrWrapWithIntrospection(authMiddleware, 'auth'),
      awrWrapWithIntrospection(responseWrapperMiddleware, 'resWrapper'),
    ], (AwRequest req) {
      return AwResponse.ok({'msg': 'hello'});
    });

    router.get('/text', middlewares: [awrLogMiddleware()], (AwRequest req) {
      return AwResponse.ok({'msg': 'hello'});
    });

    final response = await router.call(request);
    print(response);
  } catch (e, st) {
    router.log('$e\n$st');
  }
}
