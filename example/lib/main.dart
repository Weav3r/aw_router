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

    Middleware modifyMiddleware() {
      return (handler) {
        return (request) async {
          //Modify original request
          final modifiedReq = request.copyWith(context: {
            ...request.context,
            'myinternal': 'This is passed around internally'
          });
          //Avoid using print. This is here for demonstration purposes
          print('Modified request: ${modifiedReq.context}');

          final Response r = await handler(modifiedReq);
          //Modify response from handler
          return r.modify(body: "Modfied response body(${r.body})");
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
      final res = Response(
          body: '', code: 301, headers: {'Location': 'https://exmaple.com'});
      // final res = Response(
      //     body: 'https://exmaple.com',
      //     code: 200,
      //     headers: {'redirectUrl': true});
      // log("CURRENT RESPONSE ${res}");
      return res;
    });

    router.mount('/users', UsersRouter(context).router.call);

    router.all('/<chaff|.*>', middlewares: [modifyMiddleware(), s1(), foo],
        (req) async {
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
