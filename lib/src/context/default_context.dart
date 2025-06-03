import '../request.dart';
import 'route_context.dart';

class DefaultContext implements RouterContext {
  Request _mockRequest;

  DefaultContext({Request? request})
      : _mockRequest = request ??
            Request(
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

  @override
  get req => _mockRequest;

  @override
  void log(message) => print('[aw_router] $message');

  @override
  void error(message) => print('[aw_router][error] $message');

  @override
  void overrideRequest(Request req) {
    _mockRequest = req;
  }
}
