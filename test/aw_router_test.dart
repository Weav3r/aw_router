import 'package:aw_router/aw_router.dart';
import 'package:test/test.dart';

void main() {
  group('Zone-scoped latest request', () {
    test('onError receives latest request after handler copyWith and async throw', () async {
      final router = Router(null);

      AwRequest? seen;
      router.onError((req, error, st) {
        seen = req;
        return AwResponse.internalServerError();
      });

      router.get('/error-demo/<id|[0-9]+>', (
        AwRequest req,
        String id,
      ) async {
        final enriched = req.copyWith(context: {
          ...req.context,
          'traceId': 't-$id',
        });
        // simulate async boundary
        await Future<void>.delayed(const Duration(milliseconds: 5));
        // Throw without returning enriched; zone should still have latest
        throw StateError('boom-$id');
      });

      final req = AwRequest(
        method: 'GET',
        path: '/error-demo/42',
        bodyText: '',
        bodyJson: const {},
        headers: const {},
        scheme: 'https',
        url: 'https://example.com/error-demo/42',
        host: 'example.com',
        port: 443,
        queryString: '',
        query: const {},
        context: const {},
      );

      final resp = await router.call(req);
      expect(resp.statusCode, 500);
      expect(seen, isNotNull);
      expect(seen!.routeParams['id'], '42');
      expect(seen!.context['traceId'], 't-42');
    });

    test('onError sees request modified in middleware via copyWith, even when throwing after next', () async {
      // Middleware that enriches the request via copyWith, forwards, then throws
      final Middleware mw = (next) {
        return (AwRequest req) async {
          final r2 = req.copyWith(context: {
            ...req.context,
            'mw': '1',
          });
          final res = await next(r2);
          // throw after awaiting downstream
          throw StateError('mw-fail');
        };
      };

      final router = Router(null);

      AwRequest? seen;
      router.onError((req, error, st) {
        seen = req;
        return AwResponse.internalServerError();
      });

      router.get('/mw/<id>', (AwRequest req, String id) async {
        return AwResponse.ok({'ok': id});
      }, middlewares: [mw]);

      final req = AwRequest(
        method: 'GET',
        path: '/mw/abc',
        bodyText: '',
        bodyJson: const {},
        headers: const {},
        scheme: 'https',
        url: 'https://example.com/mw/abc',
        host: 'example.com',
        port: 443,
        queryString: '',
        query: const {},
        context: const {},
      );

      final resp = await router.call(req);
      expect(resp.statusCode, 500);
      expect(seen, isNotNull);
      expect(seen!.routeParams['id'], 'abc');
      expect(seen!.context['mw'], '1');
    });
  });
}
