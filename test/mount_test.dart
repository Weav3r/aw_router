import 'package:aw_router/aw_router.dart';
import 'package:test/test.dart';

void main() {
  group('Router.mount - static prefix', () {
    test('exact match forwards empty path', () async {
      final router = Router(null);

      // Mounted handler echoes forwarded path
      router.mount('/api', (AwRequest req) async {
        return AwResponse.ok({'forwardedPath': req.path});
      });

      final req = AwRequest(
        method: 'GET',
        path: '/api', // exact
        bodyText: '',
        bodyJson: const {},
        headers: const {},
        scheme: 'https',
        url: 'https://example.com/api',
        host: 'example.com',
        port: 443,
        queryString: '',
        query: const {},
        context: const {},
      );

      final res = await router.call(req);
      expect(res.statusCode, 200);
      expect((res.body as Map)['forwardedPath'], '');
    });

    test('remainder is forwarded with a leading slash', () async {
      final router = Router(null);

      router.mount('/api', (AwRequest req) async {
        return AwResponse.ok({'forwardedPath': req.path});
      });

      final req = AwRequest(
        method: 'GET',
        path: '/api/users/42',
        bodyText: '',
        bodyJson: const {},
        headers: const {},
        scheme: 'https',
        url: 'https://example.com/api/users/42',
        host: 'example.com',
        port: 443,
        queryString: '',
        query: const {},
        context: const {},
      );

      final res = await router.call(req);
      expect(res.statusCode, 200);
      expect((res.body as Map)['forwardedPath'], '/users/42');
    });
  });

  group('Router.mount - dynamic prefix', () {
    test('exact match forwards empty path and captures param', () async {
      final router = Router(null);

      router.mount('/orgs/<orgId|[0-9]+>/', (AwRequest req) async {
        return AwResponse.ok({
          'forwardedPath': req.path,
          'orgId': req.routeParams['orgId'],
        });
      });

      final req = AwRequest(
        method: 'GET',
        path: '/orgs/123', // exact to dynamic prefix
        bodyText: '',
        bodyJson: const {},
        headers: const {},
        scheme: 'https',
        url: 'https://example.com/orgs/123',
        host: 'example.com',
        port: 443,
        queryString: '',
        query: const {},
        context: const {},
      );

      final res = await router.call(req);
      expect(res.statusCode, 200);
      final body = res.body as Map;
      expect(body['forwardedPath'], '');
      expect(body['orgId'], '123');
    });

    test('remainder forwarded with leading slash and captures param', () async {
      final router = Router(null);

      router.mount('/orgs/<orgId|[0-9]+>/', (AwRequest req) async {
        return AwResponse.ok({
          'forwardedPath': req.path,
          'orgId': req.routeParams['orgId'],
        });
      });

      final req = AwRequest(
        method: 'GET',
        path: '/orgs/456/repos',
        bodyText: '',
        bodyJson: const {},
        headers: const {},
        scheme: 'https',
        url: 'https://example.com/orgs/456/repos',
        host: 'example.com',
        port: 443,
        queryString: '',
        query: const {},
        context: const {},
      );

      final res = await router.call(req);
      expect(res.statusCode, 200);
      final body = res.body as Map;
      expect(body['forwardedPath'], '/repos');
      expect(body['orgId'], '456');
    });

    test('non-matching dynamic prefix returns 404', () async {
      final router = Router(null);

      // Ensure unmatched routes return a real 404 response
      router.onNotFound((AwRequest req) => AwResponse.notFound());

      router.mount('/orgs/<orgId|[0-9]+>/', (AwRequest req) async {
        return AwResponse.ok({'forwardedPath': req.path});
      });

      final req = AwRequest(
        method: 'GET',
        path: '/orgs/abc', // does not match [0-9]+
        bodyText: '',
        bodyJson: const {},
        headers: const {},
        scheme: 'https',
        url: 'https://example.com/orgs/abc',
        host: 'example.com',
        port: 443,
        queryString: '',
        query: const {},
        context: const {},
      );

      final res = await router.call(req);
      expect(res.statusCode, 404);
    });
  });

  // New: static prefix with trailing slash
  group('Router.mount - static prefix with trailing slash', () {
    test('exact match forwards empty path', () async {
      final router = Router(null);

      router.mount('/api/', (AwRequest req) async {
        return AwResponse.ok({'forwardedPath': req.path});
      });

      final req = AwRequest(
        method: 'GET',
        path: '/api/',
        bodyText: '',
        bodyJson: const {},
        headers: const {},
        scheme: 'https',
        url: 'https://example.com/api/',
        host: 'example.com',
        port: 443,
        queryString: '',
        query: const {},
        context: const {},
      );

      final res = await router.call(req);
      expect(res.statusCode, 200);
      expect((res.body as Map)['forwardedPath'], '');
    });

    test('remainder forwarded with leading slash', () async {
      final router = Router(null);

      router.mount('/api/', (AwRequest req) async {
        return AwResponse.ok({'forwardedPath': req.path});
      });

      final req = AwRequest(
        method: 'GET',
        path: '/api/users',
        bodyText: '',
        bodyJson: const {},
        headers: const {},
        scheme: 'https',
        url: 'https://example.com/api/users',
        host: 'example.com',
        port: 443,
        queryString: '',
        query: const {},
        context: const {},
      );

      final res = await router.call(req);
      expect(res.statusCode, 200);
      expect((res.body as Map)['forwardedPath'], '/users');
    });
  });

  // New: dynamic prefix without trailing slash
  group('Router.mount - dynamic prefix without trailing slash', () {
    test('exact match forwards empty path and captures param', () async {
      final router = Router(null);

      router.mount('/orgs/<orgId|[0-9]+>', (AwRequest req) async {
        return AwResponse.ok({
          'forwardedPath': req.path,
          'orgId': req.routeParams['orgId'],
        });
      });

      final req = AwRequest(
        method: 'GET',
        path: '/orgs/789',
        bodyText: '',
        bodyJson: const {},
        headers: const {},
        scheme: 'https',
        url: 'https://example.com/orgs/789',
        host: 'example.com',
        port: 443,
        queryString: '',
        query: const {},
        context: const {},
      );

      final res = await router.call(req);
      expect(res.statusCode, 200);
      final body = res.body as Map;
      expect(body['forwardedPath'], '');
      expect(body['orgId'], '789');
    });

    test('remainder forwarded with leading slash and captures param', () async {
      final router = Router(null);

      router.mount('/orgs/<orgId|[0-9]+>', (AwRequest req) async {
        return AwResponse.ok({
          'forwardedPath': req.path,
          'orgId': req.routeParams['orgId'],
        });
      });

      final req = AwRequest(
        method: 'GET',
        path: '/orgs/321/repos',
        bodyText: '',
        bodyJson: const {},
        headers: const {},
        scheme: 'https',
        url: 'https://example.com/orgs/321/repos',
        host: 'example.com',
        port: 443,
        queryString: '',
        query: const {},
        context: const {},
      );

      final res = await router.call(req);
      expect(res.statusCode, 200);
      final body = res.body as Map;
      expect(body['forwardedPath'], '/repos');
      expect(body['orgId'], '321');
    });
  });

  // New: smartMount wrapper delegating to mount
  group('Router.smartMount wrapper', () {
    test('smartMount forwards empty path on exact match', () async {
      final router = Router(null);

      // migrated: use mount instead of smartMount
      router.mount('/api', (AwRequest req) async {
        return AwResponse.ok({'forwardedPath': req.path});
      });

      final req = AwRequest(
        method: 'GET',
        path: '/api',
        bodyText: '',
        bodyJson: const {},
        headers: const {},
        scheme: 'https',
        url: 'https://example.com/api',
        host: 'example.com',
        port: 443,
        queryString: '',
        query: const {},
        context: const {},
      );

      final res = await router.call(req);
      expect(res.statusCode, 200);
      expect((res.body as Map)['forwardedPath'], '');
    });

    test('smartMount forwards remainder with leading slash', () async {
      final router = Router(null);

      // migrated: use mount instead of smartMount
      router.mount('/api', (AwRequest req) async {
        return AwResponse.ok({'forwardedPath': req.path});
      });

      final req = AwRequest(
        method: 'GET',
        path: '/api/users',
        bodyText: '',
        bodyJson: const {},
        headers: const {},
        scheme: 'https',
        url: 'https://example.com/api/users',
        host: 'example.com',
        port: 443,
        queryString: '',
        query: const {},
        context: const {},
      );

      final res = await router.call(req);
      expect(res.statusCode, 200);
      expect((res.body as Map)['forwardedPath'], '/users');
    });
  });

  // New: mountRouter convenience
  group('Router.mountRouter convenience', () {
    test('routes into sub-router at root and nested path', () async {
      final root = Router(null);
      final sub = Router(null);

      sub.get('/', (AwRequest req) async => AwResponse.ok({'route': 'sub-root'}));
      sub.get('/ping', (AwRequest req) async => AwResponse.ok({'pong': true}));

      // migrated: use mount with sub.call
      root.mount('/api', sub.call);

      // Exact match -> sub receives '' which normalizes to '/' for matching
      final reqRoot = AwRequest(
        method: 'GET',
        path: '/api',
        bodyText: '',
        bodyJson: const {},
        headers: const {},
        scheme: 'https',
        url: 'https://example.com/api',
        host: 'example.com',
        port: 443,
        queryString: '',
        query: const {},
        context: const {},
      );
      final resRoot = await root.call(reqRoot);
      expect(resRoot.statusCode, 200);
      expect((resRoot.body as Map)['route'], 'sub-root');

      // Remainder -> sub sees '/ping'
      final reqPing = AwRequest(
        method: 'GET',
        path: '/api/ping',
        bodyText: '',
        bodyJson: const {},
        headers: const {},
        scheme: 'https',
        url: 'https://example.com/api/ping',
        host: 'example.com',
        port: 443,
        queryString: '',
        query: const {},
        context: const {},
      );
      final resPing = await root.call(reqPing);
      expect(resPing.statusCode, 200);
      expect((resPing.body as Map)['pong'], true);
    });
  });
}
