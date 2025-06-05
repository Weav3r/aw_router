import 'request_handler.dart';

typedef Middleware = RequestHandler Function(RequestHandler fn);
