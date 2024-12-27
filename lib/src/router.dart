import 'middleware.dart';
import 'request.dart';
import 'request_handler.dart';
import 'response.dart';
import 'route/route.dart';
import 'route/route_entry.dart';

class Router {
  // final Map<String, List<Middleware>> routes = {};
  final dynamic _context;
  final dynamic log;
  // final Response _outResponse = Response();
  final List<RouteEntry> _mRoutes = [];

  Router._(this._context, this.log);
  factory Router(dynamic context) {
    return Router._(context, context.log);
  }

  /// Mount a handler below a prefix.
  ///
  /// In this case prefix may not contain any parameters, nor
  void mount(
    // String path,
    String prefix,
    // MRouteHandler handler,
    RequestHandler handler,
    // List<Middleware>? middlewares,
    // HandlerCallback handler,
  ) {
    if (!prefix.startsWith('/')) {
      throw ArgumentError.value(prefix, 'prefix', 'must start with a slash');
    }

    // first slash is always in request.handlerPath
    final path = prefix.substring(1);
    if (prefix.endsWith('/')) {
      all('$prefix<path|[^]*>', (Request request) {
        var x = request.path.substring(prefix.length);
        if (!x.startsWith('/')) {
          x = '/$x';
        }
        final nReq = request.copyWith(path: x);
        return handler(nReq);
      });
    } else {
      all(prefix, (Request request) {
        return handler(request.copyWith(path: path));
      });
      all('$prefix/<path|[^]*>', (Request request) {
        return handler(request.copyWith(path: '$path/'));
      });
    }

    // routes[prefix] = []
    // registerRoute(path + prefix, middlewares);
  }

  /// Handle all request to [path] using [handler].
  void all(String path, RequestHandler handler,
      {List<Middleware>? middlewares}) {
    _mRoutes.add(RouteEntry(
            route: Route('ALL', path),
            middlewares: middlewares ?? [],
            handler: handler)
        // RouteEntry('ALL', path, handler),
        );
  }

  void add(
    String verb,
    String path,
    List<Middleware>? middlewares,
    Function handler,
  ) {
    _mRoutes.add(RouteEntry(
        route: Route(verb, path),
        middlewares: middlewares ?? [],
        handler: handler));
    // if (_mRoutes)) {
    // }
    // routes[path] = middlewares ?? [];
  }

  Future<Response> call(Request? reqst) async {
    log('Context path ${_context.req.path}');
    Request request = reqst ?? Request.parse(_context.req);
    // dynamic response = context.res;
    String path = request.path;
    String method = request.method;
    for (var entry in _mRoutes) {
      if (entry.route.method != method.toUpperCase() &&
          entry.route.method != 'ALL') {
        continue;
      }
      // if (method != entry.route.method || path != entry.route.path) continue;

      final toMatchPath = '${path}';
      var params = entry.match(toMatchPath);
      _context
          .log('==========[$method| $toMatchPath] Matched params: ${params}');
      if (params != null) {
        // _outResponse = entry.invoke(request, params);

        return (await entry.invoke(request, params));
        // _executeMiddlewares(request, response, entry, params);
        // var sss = Response().resBody(response);

        // return Response();
      }
      // print('Matched ${entry.route}');
    }

    log('Not for loop()');
    return Response();
    // return context.res.text('Not found', 404);
  }

  Future<void> _executeMiddlewares(dynamic request, dynamic response,
      RouteEntry routeEntry, Map<String, String> params) async {
    Map<int, Response> responses = {};
    Future<void> execute(int index) async {
      if (index >= routeEntry.middlewares.length) {
        // _outResponse = handler(request, response);

        // var params = routeEntry.match('/${request.path}');
        // if (params != null) {
        await routeEntry.invoke(request, params);
        log('Re-assign response');
        // _outResponse = response.text('Hello');
        // }

        return;
        // log('Runtime type of response: ${_outResponse.runtimeType}');
      }
      final middleware = routeEntry.middlewares[index];
      //   middleware(request, () async {
      //     // log('returning from index: $index');
      //     // if (index < routeEntry.middlewares.length - 1) {
      //     await execute(index + 1);
      //   });
    }

    await execute(0);
  }

  /// Handle `GET` request to [route] using [handler].
  ///
  /// If no matching handler for `HEAD` requests is registered, such requests
  /// will also be routed to the [handler] registered here.
  void get(String path, Function handler, {List<Middleware>? middlewares}) =>
      add('GET', path, middlewares, handler);

  /// Handle `HEAD` request to [route] using [handler].
  void head(String path, Function handler, {List<Middleware>? middlewares}) =>
      add('HEAD', path, middlewares, handler);

  /// Handle `POST` request to [route] using [handler].
  void post(String path, Function handler, {List<Middleware>? middlewares}) =>
      add('POST', path, middlewares, handler);

  /// Handle `PUT` request to [route] using [handler].
  void put(String path, Function handler, {List<Middleware>? middlewares}) =>
      add('PUT', path, middlewares, handler);

  /// Handle `DELETE` request to [route] using [handler].
  void delete(String path, Function handler, {List<Middleware>? middlewares}) =>
      add('DELETE', path, middlewares, handler);

  /// Handle `CONNECT` request to [route] using [handler].
  void connect(String path, Function handler,
          {List<Middleware>? middlewares}) =>
      add('CONNECT', path, middlewares, handler);

  /// Handle `OPTIONS` request to [route] using [handler].
  void options(String path, Function handler,
          {List<Middleware>? middlewares}) =>
      add('OPTIONS', path, middlewares, handler);

  /// Handle `TRACE` request to [route] using [handler].
  void trace(String path, Function handler, {List<Middleware>? middlewares}) =>
      add('TRACE', path, middlewares, handler);

  /// Handle `PATCH` request to [route] using [handler].
  void patch(String path, Function handler, {List<Middleware>? middlewares}) =>
      add('PATCH', path, middlewares, handler);
}
