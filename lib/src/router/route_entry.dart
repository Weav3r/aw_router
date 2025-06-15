import 'dart:async';

import '../core/middleware.dart';
import 'route.dart';
import '../core/pipeline.dart';
import '../core/request.dart';
import '../core/request_handler.dart';
import '../core/response.dart';

/// Represents a single route entry in the router.
///
/// Encapsulates the route definition, middlewares, handler, and compiled routing logic.
class RouteEntry {
  /// The base route definition (method and path).
  final Route route;

  /// Middlewares specific to this route, applied before the handler.
  final List<Middleware> middlewares;

  /// The function that handles the request for this route.
  /// Can be a [RequestHandler] or a function taking path parameters.
  final Function handler;

  /// List of parameter names extracted from the route path (e.g., `['id']` for `/users/<id>`).
  final List<String> _params;

  /// The compiled regular expression for path matching and parameter extraction.
  final RegExp _routePattern;

  /// Cached [Pipeline] instance for composed middlewares.
  final Pipeline _pipeline;

  /// Regex to parse route path segments and identify parameter placeholders.
  static final _pathRegex = RegExp(r'([^<]*)(?:<([^>|]+)(?:\|([^>]*))?>)?');

  /// Private constructor for [RouteEntry].
  RouteEntry._(
    this.route,
    this.middlewares,
    this.handler,
    this._params,
    this._routePattern,
    this._pipeline,
  );

  /// Creates a [RouteEntry] from a [Route], middlewares, and a handler.
  ///
  /// Parses the route path for parameters, compiles the regex, and sets up the pipeline.
  /// Throws [ArgumentError] if a parameter regex is capturing.
  factory RouteEntry({
    required Route route,
    required List<Middleware> middlewares,
    required Function handler,
  }) {
    final params = <String>[];
    String pattern = '';
    final matches = _pathRegex.allMatches(route.path);

    for (final m in matches) {
      if (m[0] != null) {
        pattern += RegExp.escape(m[1]!);
      }
      if (m[2] != null) {
        params.add(m[2]!);
        // Ensure parameter regexes are non-capturing.
        if (m[3] != null && !_isNoCapture(m[3]!)) {
          throw ArgumentError.value(
              route, 'route', 'expression for "${m[2]}" is capturing');
        }
        // Add parameter regex to the pattern, defaulting to '[^/]+'.
        pattern += "(${m[3] ?? r'[^/]+'})";
      }
    }
    final routePattern = RegExp('^$pattern\$');
    // Cache the composed middleware pipeline.
    final pipeline = Pipeline().addMiddlewares(middlewares);
    return RouteEntry._(
      route,
      middlewares,
      handler,
      params,
      routePattern,
      pipeline,
    );
  }

  /// Returns a map of parameter name to value if the [path] matches, otherwise `null`.
  Map<String, String>? match(String path) {
    var match = _routePattern.firstMatch(path);
    if (match == null) {
      return null;
    }
    final params = <String, String>{};
    // Extract parameter values from regex match.
    for (var (i, p) in _params.indexed) {
      final value = match[i + 1];
      if (value == null) {
        throw StateError(
          'Route param "$p" not found in path match for "$path"',
        );
      }
      params[p] = value;
    }
    return params;
  }

  /// Invokes the route's handler after applying middlewares.
  ///
  /// Dynamically calls the [handler] with [request] and extracted [paramArgs].
  FutureOr<AwResponse> invoke(
      AwRequest request, Map<String, String>? paramArgs) {
    final RequestHandler finalRouteHandler;

    // If the handler is a RequestHandler (takes only Request) OR if there are no path parameters,
    // it can be treated as a direct RequestHandler. This covers mounted handlers and simple routes.
    if (handler is RequestHandler || _params.isEmpty) {
      finalRouteHandler = handler as RequestHandler;
    } else {
      // Otherwise, assume the handler expects path parameters and use Function.apply
      // to pass Request and extracted parameter values.
      finalRouteHandler = (AwRequest req) async {
        final args = [req, ..._params.map((n) => paramArgs![n])];
        final dynamic result = Function.apply(handler, args);
        return await result as AwResponse;
      };
    }
    final composedHandler = _pipeline.handler(finalRouteHandler);
    return composedHandler(request);
  }
}

/// Check if the [regexp] is non-capturing.
bool _isNoCapture(String regexp) {
  // Construct a new regular expression matching anything containing regexp,
  // then match with empty-string and count number of groups.
  return RegExp('^(?:$regexp)|.*\$').firstMatch('')!.groupCount == 0;
}
