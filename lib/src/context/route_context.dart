import '../request.dart';

abstract class RouterContext {
  dynamic get req;
  void log(String message);
  void error(String message);

  void overrideRequest(Request req) {}
}
