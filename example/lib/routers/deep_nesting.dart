import 'package:aw_router/aw_router.dart' as awr;
import 'package:aw_router/aw_router.dart';
import 'package:awr_example/routers/user_router.dart';

import '../middleware/response_wrapper.dart';

class Deeper {
  final dynamic context;
  Deeper([this.context]);

  // Define a router that handles product-related endpoints.
  awr.Router get router {
    final r = awr.Router(context, fallbackLogLevel: awr.LogLevel.verbose);
    // final r = awr.Router(context);

    // final userPipeline = Pipeline().handler(UserRouter(context).router.call);

    // r.mountgpt4('/<he|[0-9]+>/users/', userPipeline);

    // List all products.
    r.get('/', (AwRequest req) async {
      // req.context['logger'] = 'foo';
      r.error('Fetching all products');
      return AwResponse.ok('Deep index');
    });

    // Retrieve a single product by ID (only numeric IDs allowed).
    r.get('/<id|[0-9]+>', (AwRequest req, String id) async {
      return AwResponse.ok('Deep id = $id');
    });

    r.post('/<id|[0-9]+>/deeper/<name>',
        (AwRequest req, String id, String name) async {
      return AwResponse.ok('Deeper post with id: $id and name: $name');
    });

    // r.smartMount('/<he|[0-9]+>/users/', UserRouter(context).router);
    r.mount('/orgs/<orgId>/dept/<deptId>/staff/', UserRouter(context).router.call);
  //  r.mountWithRemainingPath(r, '/orgs/<orgId>/dept/<deptId>/staff/', (req) {
  //    final orgd = req.routeParams['orgId'];
  //    req.logInfo('ORG ID:========================>>>>> $orgd');
  //    final subRequest = req.copyWith(path: req.routeParams['path'] ?? '');
  //    return UserRouter(null).router.call(subRequest);
  //  });

    // // NOT using .mount() for dynamic prefixes
    // r.all('/<he|[0-9]+>/users/<path|[^]*>', (AwRequest req) async {
    //   // Manually extract parameters from req.routeParams
    //   final he = req.routeParams['he'];
    //   final path = req.routeParams['path'];

    //   // Now, pass a modified request to your 'users' handler
    //   // which expects '/<path|[^]*>' relative to its own base
    //   final usersRequest = req.copyWith(
    //     path: '$path', // Adjust path for the users handler
    //     // You might need to manually set or pass parameters specific to this level
    //   );
    //   return await UserRouter(context).router.call(usersRequest);
    // });

    return r;
  }
}
