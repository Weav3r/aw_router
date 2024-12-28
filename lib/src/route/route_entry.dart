// ignore_for_file: public_member_api_docs, sort_constructors_first

import 'dart:async';

import '../middleware.dart';
import 'route.dart';
import '../pipeline.dart';
import '../request.dart';
import '../request_handler.dart';
import '../response.dart';

// typedef HandlerCallback = dynamic Function();
// typedef RequestHandler = Response Function(
//     dynamic request, Response response);
// typedef Handler = dynamic Function;

class RouteEntry {
  final Route route;
  final List<Middleware> middlewares;
  final Function handler;
  final List<String> _params;
  final RegExp _routePattern;

  static final _pathRegex = RegExp(r'([^<]*)(?:<([^>|]+)(?:\|([^>]*))?>)?');

  RouteEntry._(
    this.route,
    this.middlewares,
    this.handler,
    this._params,
    this._routePattern,
  );

  factory RouteEntry({
    required Route route,
    required List<Middleware> middlewares,
    required Function handler,
  }) {
    final params = <String>[];
    String pattern = '';
    final matches = _pathRegex.allMatches(route.path);

    RegExpMatch? mm;
    for (final m in matches) {
      mm ??= m;
      if (m[0] != null) {
        pattern += RegExp.escape(m[1]!);
      }
      if (m[2] != null) {
        params.add(m[2]!);
        if (m[3] != null && !_isNoCapture(m[3]!)) {
          throw ArgumentError.value(
              route, 'route', 'expression for "${m[2]}" is capturing');
        }
        pattern += "(${m[3] ?? r'[^/]+'})";
      }
    }
    final routePattern = RegExp('^$pattern\$');
    print('''
Create route entry
path: $route
Groups: ${mm!.groupCount}
M0: ${mm[0]}
M1: ${mm[1]}
M2: ${mm[2]}
M3: ${mm[3]}
params: $params
route pattern: $pattern
''');
    return RouteEntry._(route, middlewares, handler, params, routePattern);
  }

  /// Returns a map from parameter name to value, if the path matches the
  /// route pattern. Otherwise returns null.
  Map<String, String>? match(String path) {
    var match = _routePattern.firstMatch(path);
    if (match == null) {
      print('Route pattern match is null');
      return null;
    }

    // Construct map from parameter name to matched value
    final params = <String, String>{};
    for (var (i, p) in _params.indexed) {
      params[p] = match[i + 1]!;
    }
    print('''
match
path: $path
route pattern: $_routePattern
params: $params
''');
    return params;
  }

  FutureOr<Response> invoke(
      Request request, Map<String, String>? params) async {
    var p = Pipeline();
    for (final m in middlewares) {
      p = p.addMiddleware(m);
    }
    return await p.handler((req) async {
      if (handler is RequestHandler || _params.isEmpty) {
        print('####### invoking RequestHandler with no params');
        return await handler(req) as Response;
      }
      print('####### invoking non RequestHandler');
      return await Function.apply(handler, [
        request,
        ..._params.map((n) => params![n]),
      ]) as Response;
    })(request);
  }
}

/// Check if the [regexp] is non-capturing.
bool _isNoCapture(String regexp) {
  // Construct a new regular expression matching anything containing regexp,
  // then match with empty-string and count number of groups.
  return RegExp('^(?:$regexp)|.*\$').firstMatch('')!.groupCount == 0;
}
