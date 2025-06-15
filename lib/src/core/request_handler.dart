import 'dart:async';

import 'response.dart';
import 'request.dart';

typedef RequestHandler = FutureOr<AwResponse> Function(AwRequest request);
