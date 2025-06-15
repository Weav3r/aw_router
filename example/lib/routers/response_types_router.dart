// example/routers/response_types_router.dart

import 'dart:typed_data';
import 'package:aw_router/aw_router.dart' as awr;

class ResponseTypesRouter {
  final dynamic context;
  ResponseTypesRouter(this.context);

  awr.Router get router {
    final r = awr.Router(context);

    // Plain text response
    r.get('/text', (awr.AwRequest req) {
      return awr.AwResponse.ok('This is a plain text response.', headers: {
        'Content-Type': 'text/plain',
      });
    });

    // Return a JSON object explicitly
    r.get('/json', (awr.AwRequest req) {
      return awr.AwResponse.ok({'message': 'This is JSON!'});
    });

    // Binary response (Uint8List)
    r.get('/binary', (awr.AwRequest req) {
      final bytes =
          Uint8List.fromList([0x48, 0x65, 0x6C, 0x6C, 0x6F]); // "Hello"
      return awr.AwResponse.ok(bytes, headers: {
        'Content-Type': 'application/octet-stream',
      });
    });

    // Redirect response, url must always start with http[s]://
    r.get('/redirect', (awr.AwRequest req) {
      return awr.AwResponse.redirect('https://example.com');
    });

    return r;
  }
}
