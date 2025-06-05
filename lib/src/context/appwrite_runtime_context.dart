import 'route_context.dart';

/// Wraps an Appwrite context object to conform to the [RouterContext] interface.
///
/// This allows `aw_router` to interact with Appwrite's native context,
/// providing access to its request object and logging utilities.
class AppwriteRouterContext implements RouterContext {
  final dynamic _ctx;

  AppwriteRouterContext(this._ctx);

  /// Provides the raw request object from the Appwrite context (`_ctx.req`).
  @override
  get req => _ctx.req;

  /// Delegates logging to the Appwrite context's log function (`_ctx.log`).
  @override
  void log(message) => _ctx.log(message);

  /// Delegates error logging to the Appwrite context's error function (`_ctx.error`).
  @override
  void error(message) => _ctx.error(message);
}
