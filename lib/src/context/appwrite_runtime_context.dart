import 'route_context.dart';

class AppwriteRouterContext implements RouterContext {
  final dynamic _ctx;

  AppwriteRouterContext(this._ctx);

  @override
  get req => _ctx.req;

  @override
  void log(message) => _ctx.log(message);

  @override
  void error(message) => _ctx.error(message);
}
