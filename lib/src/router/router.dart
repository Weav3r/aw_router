import 'dart:async';

import '../core/request_handler.dart';
import '../utils/constants.dart';
import '../extensions/request_logger.dart';
import '../extensions/request_context.dart';

import '../context/appwrite_runtime_context.dart';
import '../context/default_context.dart';
import '../context/route_context.dart';
import '../logger/default_logger.dart';
import '../logger/logger.dart';
import '../core/middleware.dart';
import '../middleware/remove_body.dart';
import '../core/request.dart';
import '../core/response.dart';
import 'route.dart';
import 'route_entry.dart';
import '../utils/util.dart' show normalizePath;

/// A typedef for a function that handles exceptions occurring during request processing.
///
/// This handler receives the [AwRequest] that caused the exception, the [error] object,
/// and the [stack] trace where the error occurred. It should return a [AwResponse]
/// to be sent back to the client.
typedef ErrorHandler = FutureOr<AwResponse> Function(
    AwRequest req, Object error, StackTrace stack);

/// A composable [Router] for declarative route definitions, grouping routes
/// with shared prefixes and middleware composition, mounting sub-handlers, and handling
/// unfound routes and exceptions.
///
/// ```dart
/// import 'package:aw_router/aw_router.dart';
///
/// // Example middleware (replace with your actual auth middleware)
/// Middleware authMiddleware = (handler) {
///   return (AwRequest request) async {
///     // Your authentication logic here
///     if (Awrequest.headers.containsKey('x-auth-token')) {
///       print('AuthMiddleware: Token found, proceeding.');
///       return handler(Awrequest);
///     } else {
///       print('AuthMiddleware: No token, unauthorized.');
///       return Response.unauthorized('Authentication required.');
///     }
///   };
/// };
///
/// // Create a Router instance
/// final router = Router(null); // Pass null or a context object
///
/// // Basic route with a path parameter
/// router.get('/users/<userName>/whoami', (req, String userName) {
///   // final userName = req.routeParams['userName']; // Alternatively access parameters via req.routeParams
///   return Response.ok('You are $userName');
/// });
///
/// // Route handler using parameters from req.routeParams
/// router.get('/users/<userName>/say-hello', (req) {
///   final userName = req.routeParams['userName'];
///   return Response.ok('Hello $userName');
/// });
///
/// // Route with multiple parameters and custom regex
/// // Parameters are still accessed from req.routeParams as Strings
/// router.get('/users/<userName>/messages/<msgId|\\d+>', (req) {
///   final userName = req.routeParams['userName'];
///   final msgId = req.routeParams['msgId'];
///   final id = int.tryParse(msgId ?? ''); // Safely parse integer
///   if (id == null) {
///     return Response.badRequest('Invalid message ID');
///   }
///   return Response.ok('Message ID: $id from $userName');
/// });
///
/// // Grouped routes with shared middleware
/// router.group(
///   '/api',
///   (group) {
///     // Middlewares defined on the group apply to all routes within this group
///     group.get('/profile', (req) => Response.ok('User profile'));
///     group.post('/upload', (req) => Response.ok('Upload complete'));
///   },
///   middlewares: [authMiddleware], // Middlewares applied to the group
/// );
///
/// // Final handler for the server is the router instance itself
/// // Example of how to use it with a hypothetical server:
/// /*
/// Future<void> main() async {
///   final server = HttpServer.bind(InternetAddress.loopbackIPv4, 8080);
///   print('Server listening on port ${server.port}');
///   await for (var httpRequest in await server) {
///     // Convert HttpServerRequest to your Request object
///     final request = Request.fromHttp(httpRequest); // Assuming a converter
///     final response = await router(Awrequest); // The router instance is callable
///     // Convert your Response object back to HttpServerResponse
///     response.sendToHttp(httpRequest.response); // Assuming a converter
///   }
/// }
/// */
///
/// If multiple routes match a request, the first matched route is used.
/// If no match is found, a default 404 response is returned (customizable via `onNotFound`).
///
class Router {
  /// The context provider for the router, handling logging and request/response wrapping.
  final RouterContext _context;

  /// A fallback logger used if no logger is explicitly provided in the request context.
  final Logger _fallbackLogger;

  /// A list of all registered [RouteEntry] objects.
  final List<RouteEntry> _mRoutes = [];

  /// The handler for requests that do not match any defined route.
  /// Defaults to a sentinel that returns a 404 Not Found response.
  RequestHandler _notFoundHandler =
      (AwRequest request) => AwResponse.routeNotFound;

  /// An optional handler for exceptions thrown during request processing.
  /// If not set, a default internal server error response is returned.
  ErrorHandler? _exceptionHandler;

  /// Provides access to the logging function from the internal router context.
  void Function(String message) get log => _context.log;

  /// Provides access to the error logging function from the internal router context.
  void Function(String message) get error => _context.error;

  /// Private constructor for [Router].
  ///
  /// Initializes the router with a [RouterContext] and a [Logger] for fallback.
  Router._(this._context, this._fallbackLogger);

  /// Creates a new [Router] routing requests to handlers.
  ///
  /// It wraps the [rawContext] into a [RouterContext] and initializes a
  /// [fallbackLogger] if one is not provided. The [fallbackLogLevel] can be
  /// adjusted for the fallback logger.
  factory Router(
    dynamic rawContext, {
    Logger? fallbackLogger,
    LogLevel? fallbackLogLevel,
  }) {
    final context = _wrapContext(rawContext);
    final bool isDebug = bool.fromEnvironment('dart.vm.product') == false;
    final LogLevel defaultLevel = isDebug ? LogLevel.debug : LogLevel.info;

    final fblogger = fallbackLogger ??
        DefaultLogger(
            minimumLevel: fallbackLogLevel ?? defaultLevel,
            isFallback: true,
            logFn: context.log,
            errorFn: context.error);

    return Router._(context, fblogger);
  }

  /// Wraps a dynamic context object into a concrete [RouterContext].
  ///
  /// Supports `null`, an existing [RouterContext], or an Appwrite-specific context
  /// by checking for a `req` property. Defaults to [DefaultContext].
  static RouterContext _wrapContext(dynamic ctx) {
    if (ctx == null) return DefaultContext();
    if (ctx is RouterContext) return ctx;
    // Assuming ctx.req implies an Appwrite-like context
    if (ctx.req != null) return AppwriteRouterContext(ctx);
    return DefaultContext();
  }

  /// Groups routes under a common [prefix] and applies optional [middlewares]
  /// to all routes defined within the [builder] function.
  ///
  /// The [builder] function receives a [Router] instance
  /// which automatically prepends the [prefix] to all paths and applies the
  /// specified middlewares.
  void group(String prefix, void Function(Router groupRouter) builder,
      {List<Middleware>? middlewares}) {
    final grouped = _GroupedRouter(this, prefix, middlewares ?? []);
    builder(grouped);
  }

  /// Normalize forwarded sub-path for mounted handlers:
  /// '' for exact mount match, leading '/' otherwise.
  String _normalizeMountedSubPath(String path) {
    if (path.isEmpty) return '';
    return path.startsWith('/') ? path : '/$path';
  }

  /// Mounts a [handler] under a [prefix].
  ///
  /// - Supports static and dynamic prefixes (e.g. '/api', '/<id|\\d+>/v1/').
  /// - For exact matches (no remainder), forwards '' as the new request.path.
  /// - For prefix matches with remainder, forwards the remaining path with a leading '/'.
  void mount(String prefix, RequestHandler handler) {
    final normPrefix = normalizePath(prefix);
    if (!normPrefix.startsWith('/')) {
      throw ArgumentError.value(normPrefix, 'prefix', 'must start with a slash');
    }

    if (normPrefix.endsWith('/')) {
      // Forward any remaining path (possibly empty) as new path
      all('$normPrefix<path|[^]*>', (AwRequest req) {
        final rest = req.routeParams['path'] ?? '';
        final subReq = req.copyWith(path: _normalizeMountedSubPath(rest));
        return handler(subReq);
      });
    } else {
      // Exact match: forward empty path
      all(normPrefix, (AwRequest req) {
        return handler(req.copyWith(path: ''));
      });
      // Prefix match: forward remainder with leading '/'
      all('$normPrefix/<path|[^]*>', (AwRequest req) {
        final rest = req.routeParams['path'] ?? '';
        return handler(req.copyWith(path: _normalizeMountedSubPath(rest)));
      });
    }
  }

  /// Handle all request to [path] using [handler]. Optional [middlewares]>
  /// can be applied to this specific route.
  void all(String path, RequestHandler handler,
      {List<Middleware>? middlewares}) {
    final normalizedPath = normalizePath(path);
    _mRoutes.add(RouteEntry(
        route: Route('ALL', normalizedPath),
        middlewares: middlewares ?? [],
        handler: handler));
    _fallbackLogger.verbose('Added route: ALL "$normalizedPath"');
  }

  /// Add [handler] for [verb] requests to [path].
  ///
  /// If [verb] is `GET`, the [handler] will also be called for `HEAD` requests
  /// matching [path]. This is because handling `GET` requests without handling
  /// `HEAD` is always wrong. To explicitly implement a `HEAD` handler, it must
  /// be registered before the `GET` handler. The [path] is normalized.
  void _add(
    String verb,
    String path,
    List<Middleware>? middlewares,
    Function handler,
  ) {
    final normalizedPath = normalizePath(path);
    verb = verb.toUpperCase();
    if (verb == 'GET') {
      // Handling in a 'GET' request without handling a 'HEAD' request is always
      // wrong, thus, we add a default implementation that discards the body.
      _mRoutes.add(RouteEntry(
          route: Route('HEAD', normalizedPath),
          handler: handler,
          middlewares: [coreRemoveBodyMiddleware, ...?middlewares]));
      _fallbackLogger.verbose('Added route: HEAD "$normalizedPath"');
    }
    _mRoutes.add(RouteEntry(
        route: Route(verb, normalizedPath),
        middlewares: middlewares ?? [],
        handler: handler));
    _fallbackLogger.verbose('Added route: $verb "$normalizedPath"');
  }

  /// Route incoming requests to registered handlers, acting as the primary entry point.
  ///
  /// This initializes the request, injects a fallback logger if needed,
  /// matches against routes, and invokes handlers with middleware.
  /// Unmatched requests go to [Router.onNotFound]; unhandled errors to [Router.onError].
  ///
  /// The optional [request] parameter uses an external request, otherwise the internal context's request.
  Future<AwResponse> call([AwRequest? request]) async {
    late AwRequest req;
    // Determine the request object to use (from context or provided argument)
    if (_context.req is AwRequest) {
      req = request ?? _context.req as AwRequest;
    } else {
      req = request ?? AwRequest.parse(_context.req);
    }

    // Inject fallback logger into request context if not already present
    final existingLogger = req.context[ctxLoggerKey];
    if (existingLogger == null) {
      req = req.withContext(ctxLoggerKey, _fallbackLogger);
      _context.log('[aw_router] ⚠️ Injected fallbackLogger at router init');
    } else if (existingLogger is! Logger) {
      // Ensure the existing logger is of the correct type
      throw ArgumentError(
        'Invalid logger found in Request.context["logger"]: Must implement Logger',
      );
    }

    // Zone-scoped holder for freshest request
    final ref = CurrentRequestRef(req);
    AwResponse? finalResp;

    await runZonedGuarded(() async {
      String path = normalizePath(req.path);
      String method = req.method;
      try {
        _fallbackLogger.verbose('Request path ${req.path}');
        _fallbackLogger.verbose('Normalised path $path');
        for (var entry in _mRoutes) {
          _fallbackLogger
              .verbose('Checking ($method) $path against ${entry.route} ');
          if (entry.route.method != method.toUpperCase() &&
              entry.route.method != 'ALL') {
            continue;
          }

          var params = entry.match(path);
          if (params != null) {
            _fallbackLogger
                .verbose('Matched ${entry.route} with parameters $params');
            // copyWith updates the zone-held latest request via request.copyWith
            final updatedRequest = req.copyWith(routeParams: params);
            final response = await entry.invoke(updatedRequest, params);

            if (response != AwResponse.routeNotFound) {
              finalResp = response;
              return;
            }
          }
        }
        _fallbackLogger.verbose('No route found for path ${req.path}');
        finalResp = await _notFoundHandler(req);
      } catch (e, st) {
        // Use the freshest request held in the Zone
        final latest =
            (Zone.current[zoneCurrentRequestRefKey] as CurrentRequestRef?)
                    ?.current as AwRequest? ??
                req;
        latest.logError('Unhandled exception during request processing',
            error: e, stackTrace: st);
        if (_exceptionHandler != null) {
          finalResp = await _exceptionHandler!(latest, e, st);
        } else {
          finalResp = AwResponse.internalServerError();
        }
      }
    }, (Object e, StackTrace st) async {
      // Catch uncaught async errors in the router pipeline
      final latest =
          (Zone.current[zoneCurrentRequestRefKey] as CurrentRequestRef?)
                  ?.current as AwRequest? ??
              req;
      latest.logError('Unhandled async exception in router zone',
          error: e, stackTrace: st);
      if (_exceptionHandler != null) {
        finalResp = await _exceptionHandler!(latest, e, st);
      } else {
        finalResp = AwResponse.internalServerError();
      }
    }, zoneValues: {
      zoneCurrentRequestRefKey: ref,
    });

    return finalResp!;
  }

  /// Sets the handler for requests that do not match any defined route.
  ///
  /// The [handler] will be called if no route is found for an incoming request.
  void onNotFound(RequestHandler handler) {
    _notFoundHandler = handler;
  }

  /// Sets the global exception handler for the router.
  ///
  /// The [handler] will be invoked if any unhandled exception occurs
  /// during the processing of a request.
  void onError(ErrorHandler handler) {
    _exceptionHandler = handler;
  }

  // --- HTTP Verb Helpers ---

  /// Registers a handler for HTTP `GET` requests to the given [path].
  ///
  /// The [handler] will be invoked when a GET request matches the path.
  /// Optional [middlewares] can be applied to this specific route.
  void get(String path, Function handler, {List<Middleware>? middlewares}) =>
      _add('GET', path, middlewares, handler);

  /// Handle `HEAD` request to [path] using [handler] with optinal [middlewares].
  void head(String path, Function handler, {List<Middleware>? middlewares}) =>
      _add('HEAD', path, middlewares, handler);

  /// Handle `POST` request to [path] using [handler] with optinal [middlewares].
  void post(String path, Function handler, {List<Middleware>? middlewares}) =>
      _add('POST', path, middlewares, handler);

  /// Handle `PUT` request to [path] using [handler] with optinal [middlewares].
  void put(String path, Function handler, {List<Middleware>? middlewares}) =>
      _add('PUT', path, middlewares, handler);

  /// Handle `DELETE` request to [path] using [handler] with optinal [middlewares].
  void delete(String path, Function handler, {List<Middleware>? middlewares}) =>
      _add('DELETE', path, middlewares, handler);

  /// Handle `PATCH` requests to [path] using [handler] with optional [middlewares].
  void patch(String path, Function handler, {List<Middleware>? middlewares}) =>
      _add('PATCH', path, middlewares, handler);
}

/// A private helper class for defining routes within a [Router.group].
///
/// This router automatically prepends a [_prefix] to all defined routes
/// and applies a list of [_groupMiddlewares] before any route-specific middlewares.
class _GroupedRouter extends Router {
  final Router _parent;
  final String _prefix;
  final List<Middleware> _groupMiddlewares;

  /// Creates a [_GroupedRouter] instance.
  ///
  /// It takes the [_parent] router, the common [_prefix], and
  /// the [_groupMiddlewares] to be applied.
  _GroupedRouter(this._parent, this._prefix, this._groupMiddlewares)
      : super._(_parent._context, _parent._fallbackLogger);

  /// Combines a [prefix] and a [path] to form a full, normalized route path.
  ///
  /// Ensures correct joining of paths, avoiding double slashes.
  String _combine(String prefix, String path) {
    // Use normalized paths for both prefix and path, then join
    final normPrefix = normalizePath(prefix);
    final normPath = normalizePath(path);
    if (normPrefix == '/') return normPath;
    // Avoid double slash when combining if path is just '/'
    if (normPath == '/') return normPrefix;
    return '$normPrefix$normPath';
  }

  /// Adds a route to the parent router with the group's prefix and middlewares applied.
  @override
  void all(String path, RequestHandler handler,
      {List<Middleware>? middlewares}) {
    _parent.all(
      _combine(_prefix, path),
      handler,
      middlewares: [..._groupMiddlewares, ...?middlewares],
    );
  }

  /// Adds a route to the parent router with the group's prefix and middlewares applied.
  @override
  void _add(String verb, String path, List<Middleware>? middlewares,
      Function handler) {
    _parent._add(
      verb,
      _combine(_prefix, path),
      [..._groupMiddlewares, ...?middlewares],
      handler,
    );
  }
}
