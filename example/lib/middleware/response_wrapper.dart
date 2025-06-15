// example/middleware/response_wrapper.dart

import 'package:aw_router/aw_router.dart' as awr;

/// Middleware that wraps the response body in a `data` key.
///
/// This is useful for enforcing a consistent API response structure, where
/// all response payloads are encapsulated in a `data` field. For example,
/// a response body like `{'id': 1}` will be transformed to:
/// `{'data': {'id': 1}}`
awr.RequestHandler responseWrapperMiddleware(awr.RequestHandler handler) {
  return (awr.AwRequest request) async {
    final res = await handler(request);

    // If the status code is not 2xx, return the response unchanged
    if (res.statusCode == null ||
        res.statusCode! < 200 ||
        res.statusCode! >= 300) {
      return res;
    }

    // Wrap successful responses with a data envelope
    return res.modify(
      body: {'data': res.body},
    );
  };
}
