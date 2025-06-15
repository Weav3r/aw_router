import '../core/request.dart';
import 'route_context.dart';

/// A default implementation of [RouterContext] for testing or simple environments.
///
/// This context provides a basic [AwRequest] object (mocked if not provided)
/// and prints log and error messages to the console.
class DefaultContext implements RouterContext {
  final AwRequest _mockRequest;

  /// Creates a [DefaultContext] instance.
  ///
  /// If a [request] is provided, it's used as the underlying raw request.
  /// Otherwise, a default mock [AwRequest] for a `GET /` operation is created.
  DefaultContext({AwRequest? request})
      : _mockRequest = request ??
            AwRequest(
                method: 'GET',
                path: '/',
                bodyText: '',
                bodyJson: {},
                headers: {},
                scheme: 'https',
                url: '',
                host: '',
                port: 443,
                queryString: '',
                query: {},
                context: {});

  /// Provides the raw [AwRequest] object.
  @override
  get req => _mockRequest;

  /// Logs a message to the console, prefixed with `[aw_router]`.
  @override
  void log(message) => print('[aw_router] $message');

  /// Logs an error message to the console, prefixed with `[aw_router]`.
  @override
  void error(message) => print('[aw_router] $message');
}
