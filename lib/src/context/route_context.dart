abstract class RouterContext {
  dynamic get req;
  void log(String message);
  void error(String message);
}
