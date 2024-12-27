import 'package:aw_router/aw_router.dart';

Future<dynamic> main(final context) async {
  try {
    final log = context.log;
    final routeHandler = MRouteHandler(context);

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

    routeHandler.get('/users', (Request req) {
      // if (res case Response _) {
      // res.modify(body: "You got users root with modify()");
      // }
      log("Request runtime type: $req");
      final res = Response()
          .modify(body: "You got users root with modify()", code: 200);
      log("CURRENT RESPONSE ${res}");
      return res;
    });

    routeHandler.get('/users/<userId|[0-9]+>', (req, id) {
      log("I'm in the user with id");
      return Response.ok(
        "Here's your user id $id modify()",
      );
    });

    // routeHandler.mount('/api/', Api(context).router.call);

    routeHandler.all('/<chaff|.*>', middlewares: [sooo(), s1(), foo],
        (req) async {
      return Response(body: "Sorry, I'm Default modify(${req.context})");
      // return Response(body: "Sorry, I'm Default modify()", code: 404);
    });

    // final res =
    //     await Wrapr().addMid(sooo()).last(routeHandler.call())(context.req);
    // log("Finoooi ${res.body}");

    // return res.modify(body: 'Helooo me').resBody(context.res);
    return (await routeHandler.call(null)).response(context.res);
    // return context.res.text('Handled successfully');
  } catch (e, st) {
    context.error('Error occured  $e --- $st');
    return context.res.empty();
  }
}
