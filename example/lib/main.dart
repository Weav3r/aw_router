import 'package:aw_router/aw_router.dart' as awr;
import 'package:awr_example/users.dart';

Future<dynamic> main(final context) async {
  try {
    final log = context.log;
    final router = awr.Router(context);

    foo(awr.RequestHandler handler) {
      return (awr.Request request) async {
        final modReq =
            request.copyWith(context: {...request.context, 'foo': 'Hi'});
        log('foo ${modReq.context}');
        final r = await handler(modReq);
        return r.modify(body: "foo(${r.body})");
        // return awr.Response().modify(body: 'Sooo()');
      };
    }

    awr.Middleware modifyMiddleware() {
      return (handler) {
        return (request) async {
          //Modify original request
          final modifiedReq = request.copyWith(context: {
            ...request.context,
            'myinternal': 'This is passed around internally'
          });
          //Avoid using print. This is here for demonstration purposes
          print('Modified request: ${modifiedReq.context}');

          final awr.Response r = await handler(modifiedReq);
          //Modify response from handler
          return r.modify(body: "Modfied response body(${r.body})");
        };
      };
    }

    awr.Middleware s1() {
      return (handler) {
        return (request) async {
          final modReq =
              request.copyWith(context: {...request.context, 's1': 'Heya'});
          log('s1 ${modReq.context}');
          final r = await handler(modReq);
          return r.modify(body: "s1(${r.body})");
          // return awr.Response().modify(body: 'Sooo()');
        };
      };
    }

    router.get('/', (awr.Request req) {
      // if (res case awr.Response _) {
      // res.modify(body: "You got users root with modify()");
      // }
      log("awr.Request runtime type: $req");
      final res = awr.Response().modify(body: "Index page got", code: 200);
      log("CURRENT RESPONSE ${res}");
      return res;
    });

    router.get('/redirect', (awr.Request req) {
      // if (res case awr.Response _) {
      // res.modify(body: "You got users root with modify()");
      // }
      log("awr.Request runtime type: $req");
      req.headers['redirectUrl'] = true;
      // final res = awr.Response().modify(body: "Index page got", code: 200);
      final res = awr.Response(
          body: '', code: 301, headers: {'Location': 'https://exmaple.com'});
      // final res = awr.Response(
      //     body: 'https://exmaple.com',
      //     code: 200,
      //     headers: {'redirectUrl': true});
      // log("CURRENT RESPONSE ${res}");
      return res;
    });

    router.mount('/users', UsersRouter(context).router.call);

    router.all('/<chaff|.*>', middlewares: [modifyMiddleware(), s1(), foo],
        (req) async {
      return awr.Response(
          body: "[AWR] Sorry, I'm Default modify(${req.context})");
      // return awr.Response(body: "Sorry, I'm Default modify()", code: 404);
    });

    final awr.Response res = await awr.Pipeline()
        // .addMiddleware(sooo())
        .handler(router.call)(awr.Request.parse(context.req));
    return res.runtimeResponse(context.res);

    // return res.modify(body: 'Helooo me').resBody(context.res);
    // return (await router.call()).runtimeResponse(context.res);
    // return context.res.text('Handled successfully');
  } catch (e, st) {
    context.error('Error occured  $e --- $st');
    return context.res.empty();
  }
}
