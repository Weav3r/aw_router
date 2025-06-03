import 'package:aw_router/aw_router.dart';

import 'middleware/auth.dart';
import 'middleware/normalize_trailing_slash.dart';
import 'middleware/response_wrapper.dart';
import 'routers/product_router.dart';

void main() async {
  final router = Router(); // No context needed!

// Construct a test request with all required fields
  final request = Request(
    method: 'get',
    // path: '/users/123',
    path: '/products',
    // path: '/text',
    headers: {'authorization': 'valid-token'},
    // headers: {},
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
        .addMiddleware(stripTrailingSlashMiddleware)
        .addMiddleware(logMiddleware(
            level: LogLevel.debug, logFn: router.log, errorFn: router.error))
        .addMiddleware(authMiddleware)
        .addMiddleware(responseWrapperMiddleware)
        .handler(ProductRouter().router.call);

    router.mount('/products', productPipeline);
    router.get('/text', middlewares: [logMiddleware()], (req) {
      return Response.ok({'msg': 'hello'});
    });

    final response = await router.call(request);
    print(response);
  } catch (e, st) {
    router.log(e.toString());
  }
}
