import 'package:aw_router/aw_router.dart';

import '../core/request.dart';
import '../core/request_handler.dart';

/// Middleware to remove body from request.
RequestHandler coreRemoveBodyMiddleware(RequestHandler handler) {
  return (AwRequest r) async {
    AwResponse res = await handler(r);
    if (res.headers.containsKey('content-length')) {
      res = res.modify(headers: {'content-length': '0'});
    }
    return res.modify(body: '');
    // return Response(code: 200, headers: res.headers);
  };
}
