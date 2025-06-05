import 'middleware.dart';
import 'request_handler.dart';

/// A composable pipeline for chaining middleware in an "onion" fashion.
///
/// Middlewares are executed in the order they are added (first added is outermost).
///
/// Example:
/// ```dart
/// final pipeline = Pipeline()
///   .addMiddleware(middlewareA) // Outermost layer
///   .addMiddleware(middlewareB); // Innermost layer before finalHandler
///
/// final handler = pipeline.handler(finalRouteHandler); // Results in middlewareA(middlewareB(finalRouteHandler))
/// ```
class Pipeline {
  final List<Middleware> _middlewares;
  // This field now correctly caches the *composed Middleware function* itself.
  // This is the result of applying the `fold` operation to combine all
  // individual middlewares into one large middleware.
  final Middleware _cachedMiddlewareComposition;

  // Private constructor to enforce that _middlewares and _cachedMiddlewareComposition
  // are always correctly set together.
  // This constructor cannot be `const` because _cachedMiddlewareComposition (a closure) isn't `const`.
  Pipeline._(this._middlewares, this._cachedMiddlewareComposition);

  /// Creates an empty pipeline.
  /// Use `addMiddleware` to add layers to this pipeline.
  factory Pipeline() => Pipeline._(
        const [],
        (RequestHandler h) => h, // No-op middleware
      );

  /// Returns a new [Pipeline] with [mid] appended as a new *inner* layer.
  ///
  /// The internal `_middlewares` list will grow in the order of `addMiddleware` calls.
  /// This design naturally maintains the "onion" model, where earlier added
  /// middlewares (at the beginning of the list) will be the outermost in the composed chain.
  Pipeline addMiddleware(Middleware mid) {
    final newMiddlewares = [
      ..._middlewares,
      mid
    ]; // Create a new list for immutability

    // Recalculate the entire middleware composition for the new pipeline.
    // This is the "expensive" part, but it only happens when the pipeline is built or modified.
    final newComposition = newMiddlewares.reversed.fold<Middleware>(
      (RequestHandler h) => h, // Initial value for fold is a no-op Middleware
      (Middleware nextAccumulator, Middleware currentMiddleware) {
        return (RequestHandler h) {
          return currentMiddleware(nextAccumulator(h));
        };
      },
    );

    return Pipeline._(newMiddlewares, newComposition);
  }

  /// Returns a new [Pipeline] with all [mids] appended as new *inner* layers.
  /// This is a convenience method for adding multiple middlewares at once.
  Pipeline addMiddlewares(List<Middleware> mids) {
    final newMiddlewares = [..._middlewares, ...mids];
    // Correction applied here: The combine function now correctly returns a Middleware.
    final newComposition = newMiddlewares.reversed.fold<Middleware>(
      (RequestHandler h) => h,
      (Middleware nextAccumulator, Middleware currentMiddleware) {
        return (RequestHandler h) {
          return currentMiddleware(nextAccumulator(h));
        };
      },
    );
    return Pipeline._(newMiddlewares, newComposition);
  }

  /// Returns the composed [RequestHandler], applying all added middlewares in order.
  ///
  /// This method leverages the internally cached `_cachedMiddlewareComposition`,
  /// making repeated calls to `handler()` extremely fast after the initial
  /// pipeline building (via `factory Pipeline()` or `addMiddleware`).
  RequestHandler handler(RequestHandler finalRouteHandler) =>
      _cachedMiddlewareComposition(finalRouteHandler);

  // Basic equality and hashcode for Pipeline instances.
  // Note: Directly comparing function identities for `_cachedMiddlewareComposition`
  // might not always work as expected for complex closures in Dart.
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Pipeline &&
        _middlewares ==
            other._middlewares && // List equality might require deep compare
        _cachedMiddlewareComposition == other._cachedMiddlewareComposition;
  }

  @override
  int get hashCode => Object.hash(_middlewares, _cachedMiddlewareComposition);
}
