import 'dart:async';

import 'response.dart';
import 'request.dart';

typedef RequestHandler = FutureOr<Response> Function(Request request);
