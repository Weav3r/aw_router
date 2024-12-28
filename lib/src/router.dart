import 'middleware.dart';
import 'request.dart';
import 'request_handler.dart';
import 'response.dart';
import 'route/route.dart';
import 'route/route_entry.dart';

class Router {
  final dynamic _context;
  final dynamic log;
  final List<RouteEntry> _mRoutes = [];

  Router._(this._context, this.log);
  factory Router(dynamic context) {
    return Router._(context, context.log);
  }

  /// Mount a handler below a prefix.
  ///
  /// In this case prefix may not contain any parameters, nor
  void mount(
    String prefix,
    RequestHandler handler,
  ) {
    if (!prefix.startsWith('/')) {
      throw ArgumentError.value(prefix, 'prefix', 'must start with a slash');
    }

    // first slash is always in request.handlerPath
    final path = prefix.substring(1);
    if (prefix.endsWith('/')) {
      all('$prefix<path|[^]*>', (Request request) {
        var newPath = request.path.substring(prefix.length);
        if (!newPath.startsWith('/')) {
          newPath = '/$newPath';
        }
        final nReq = request.copyWith(path: newPath);
        return handler(nReq);
      });
    } else {
      all(prefix, (Request request) {
        var newPath = request.path.substring(prefix.length);
        if (!newPath.startsWith('/')) {
          newPath = '/$newPath';
        }
        return handler(request.copyWith(path: newPath));
      });
      all('$prefix/<path|[^]*>', (Request request) {
        var newPath = request.path.substring(prefix.length);
        if (!newPath.startsWith('/')) {
          newPath = '/$newPath';
        }
        return handler(request.copyWith(path: newPath));
        // return handler(request.copyWith(path: '$newPath/'));
      });
    }
  }

  /// Handle all request to [path] using [handler].
  void all(String path, RequestHandler handler,
      {List<Middleware>? middlewares}) {
    _mRoutes.add(RouteEntry(
        route: Route('ALL', path),
        middlewares: middlewares ?? [],
        handler: handler));
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

  /// The [reqst] parameter is to ensure the function signature conforms to
  /// [RequestHandler]. Thus this method can be called in `mount()` and in a
  /// `Pipeline.handler()`
  Future<Response> call([Request? reqst]) async {
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
        return (await entry.invoke(request, params));
      }
      // print('Matched ${entry.route}');
    }

    log('Not for loop()');
    return Response();
    // return context.res.text('Not found', 404);
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
