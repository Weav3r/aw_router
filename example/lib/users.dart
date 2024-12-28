import 'package:aw_router/aw_router.dart';

class UsersRouter {
  final dynamic context;
  UsersRouter(this.context);

  Router get router {
    final router = Router(context);
    final List<Map<String, dynamic>> dummyData = [
      {'id': '0', 'name': 'John Doe'},
      {'id': '1', 'name': 'Jane Doe'},
    ];

    router.get(
        '/',
        (Request request) =>
            Response.ok({'feature': 'users', 'total': 2, 'data': dummyData}));

    router.post('/', (Request request) {
      if (request.bodyJson.isEmpty) throw Exception('Body is null');

      dummyData.add(request.bodyJson);

      return Response.ok({'feature': 'users', 'total': 2, 'data': dummyData});
    });

    router.get('/<userId|[0-9]+>', (Request req, id) {
      // log("I'm in the user with id");
      return Response.ok(
          {'id': id, 'name': 'Jay Doe', 'verified': true, 'age': 23});
    });

    router.all('/<nop|.*>', (req) async {
      return Response(body: "No response from users");
      // return Response(body: "Sorry, I'm Default modify()", code: 404);
    });

    return router;
  }
}
