import 'middleware.dart';
import 'request_handler.dart';

class Pipeline {
  final Middleware middleware;
  final Middleware parent;
  Pipeline({Middleware? p, Middleware? c})
      : middleware = p ?? ((RequestHandler fn) => fn),
        parent = c ?? ((RequestHandler fn) => fn);
  // factory Pipeline({
  //   required MyMid parent,
  //   MyMid? child,
  // }) {
  //   final c = child ?? ((RequestHandler fn) => fn);
  //   return Pipeline._(parent, last);
  //   // return Pipeline._(c);
  // }

// b(c(d(h())))
  Pipeline addMiddleware(Middleware mid) => Pipeline(p: mid, c: handler);
  // Pipeline addMid(MyMid mid) => Pipeline(child: mid,  last);
  RequestHandler handler(RequestHandler h) {
    // return parent(child(c));
    return parent(middleware(h));
  }
}
