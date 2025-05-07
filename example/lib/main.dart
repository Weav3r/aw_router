import 'package:aw_router/aw_router.dart';
import 'package:awr_example/users.dart';

Future<dynamic> main(final context) async {
  try {
    final log = context.log;
    final router = Router(context);

    foo(RequestHandler handler) {
      return (Request request) async {
        final modReq =
            request.copyWith(context: {...request.context, 'foo': 'Hi'});
        log('foo ${modReq.context}');
        final r = await handler(modReq);
        return r.modify(body: "foo(${r.body})");
        // return Response().modify(body: 'Sooo()');
      };
    }

    Middleware sooo() {
      return (handler) {
        return (request) async {
          final modReq =
              request.copyWith(context: {...request.context, 'me': 'Hey'});
          log('sooo ${modReq.context}');
          final r = await handler(modReq);
          return r.modify(body: "soo(${r.body})");
          // return Response().modify(body: 'Sooo()');
        };
      };
    }

    Middleware s1() {
      return (handler) {
        return (request) async {
          final modReq =
              request.copyWith(context: {...request.context, 's1': 'Heya'});
          log('s1 ${modReq.context}');
          final r = await handler(modReq);
          return r.modify(body: "s1(${r.body})");
          // return Response().modify(body: 'Sooo()');
        };
      };
    }

    router.get('/', (Request req) {
      // if (res case Response _) {
      // res.modify(body: "You got users root with modify()");
      // }
      log("Request runtime type: $req");
      final res = Response().modify(body: "Index page got", code: 200);
      log("CURRENT RESPONSE ${res}");
      return res;
    });

    router.get('/redirect', (Request req) {
      // if (res case Response _) {
      // res.modify(body: "You got users root with modify()");
      // }
      log("Request runtime type: $req");
      req.headers['redirectUrl'] = true;
      // final res = Response().modify(body: "Index page got", code: 200);
      final res = Response(body: 'https://exmaple.com', code: 200);
      // log("CURRENT RESPONSE ${res}");
      return res;
    });

    router.mount('/users', UsersRouter(context).router.call);

    router.all('/<chaff|.*>', middlewares: [sooo(), s1(), foo], (req) async {
      return Response(body: "[AWR] Sorry, I'm Default modify(${req.context})");
      // return Response(body: "Sorry, I'm Default modify()", code: 404);
    });

    final Response res = await Pipeline()
        // .addMiddleware(sooo())
        .handler(router.call)(Request.parse(context.req));
    return res.runtimeResponse(context.res);

    // return res.modify(body: 'Helooo me').resBody(context.res);
    // return (await router.call()).runtimeResponse(context.res);
    // return context.res.text('Handled successfully');
  } catch (e, st) {
    context.error('Error occured  $e --- $st');
    return context.res.empty();
  }
}
