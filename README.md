# aw_router

A lightweight, composable, and middleware-friendly router designed for use with [Appwrite Cloud Functions](https://appwrite.io/docs/functions). It provides expressive route definitions, parameter parsing, and middleware pipelines for robust request handling. Inspired by [shelf_router](https://pub.dev/packages/shelf_router) tailored for Dart functions, and built to be modular and ergonomic.

## 📎 Quick Links

- [Features](#features)
- [Getting Started](#getting-started)
- [Usage Example](#usage-example)
- [Routes](#routes)
- [Defining Routes](#defining-routes)
- [Path Parameters](#path-parameters)
- [Defining a Router](#defining-a-router)
- [Mounting Routers](#mounting-routers)
- [Middleware](#middleware)
- [Modify Requests and Responses](#modify-requests-and-responses)
- [Contributing](#contributing)
- [Credits](#credits)
- [License](#license)

## Features

- Appwrite-native: Fully compatible with Appwrite Cloud Function context
- Declarative route registration for`GET`, `POST`, `PATCH`, `DELETE`, etc.
- Regex-powered routing for dynamic parameters (e.g. `/user/<id|[0-9]+>`)
- Composable middleware pipelines with support for short circuit and transformations
- Router mounting using `.mount()` for modular route organization (`/api/`, `/users/`, etc.)
- Graceful error handling and response management
- Testable request/response objects with support for local invocation
- Zero-dependency core for performance and simplicity

---

# Getting Started

Add the package in your `pubspec.yaml`:

```dart
dependencies:
  aw_router:
    git:
      url: "https://github.com/Weav3r/aw_router.git"
      ref: dev
      version: "0.0.18" // or later
```

To prevent name collisions with appwrite's `Request` and `Response` import as:

```dart
import 'package:aw_router/aw_router.dart' as awr;
```

## Usage Example

```dart
import 'package:aw_router/aw_router.dart' as awr;

/// Middleware to log incoming requests
awr.RequestHandler logMiddleware(awr.RequestHandler handler) {
  return (awr.Request request) async {
    final appwriteLogFunction = request.context['appwrite_log'];
    appwriteLogFunction('Incoming headers: ${request.headers}');
    appwriteLogFunction('Incoming request: ${request.method} ${request.path}');
    final awr.Response response = await handler(request);
    appwriteLogFunction('Response status: ${response.statusCode}');
    return response;
  };
}

// Define a router to group routes, typically defined in a separate file
class UserRouter {
  final dynamic context;
  UserRouter(this.context);

  awr.Router get router {
    final r = awr.Router(context);

    r.get('/<userId|[0-9]+>', (req, userId) async {
      return awr.Response.ok({'userId': userId});
    });

    return r;
  }
}

Future<dynamic> main(final context) async {
  try {
    final rootRouter = awr.Router(context);

    // Construct the UserRouter and add middleware that will be
    // called before any request handler in UserRouter gets called
    final userPipeline = awr.Pipeline()
        .addMiddleware(logMiddleware)
        .handler(UserRouter(context).router.call);

    // mount the 'UserRouter' to handle <function_url>/users/ requests
    rootRouter.mount('/users/', userPipeline);

    // default route for unmatched paths regardless of http method
    rootRouter.all('/<ignore|.*>', (awr.Request req) {
      return awr.Response(code: 404, body: {'error': 'Not found'});
    });

    // convert appwrite's Request to aw_router Request
    final req = awr.Request.parse(context.req)
        .copyWith(context: {'appwrite_log': context.log});

    final res = await rootRouter.call(req);
    return res.runtimeResponse(context.res);
  } catch (e, st) {
    context.error('Error occured $e --- $st');
    return context.res.empty();
  }
}
```

## Routes

Routes define the endpoints that your Appwrite function will handle.
Here's how to define a route in `aw_router`:

### Defining Routes

```dart
final router = awr.Router(context);

router.get('/hello', (req) async {
  return awr.Response.ok({'message': 'Hello world!'});
});

router.get('/webpage', (Request req) {
  return awr.Response.ok("<h1>Hellow world</h1>", headers: {
  'content-type': 'text/html',
  'Access-Control-Allow-Origin': '\*',
  });
});

router.post('/submit', (req) async {
  final data = req.bodyJson;
  // Create your response
  return Response(body: {'received': data} , code: 201, headers: {'x-awr-header': 'My header'});
});
```

### Path Parameters

Routes supports inline path parameters with optional regex constraints just as in `[shelf_router](https://pub.dev/packages/shelf_router)`:

```dart
router.get('/user/<id|[0-9]+>', (req, String id) async {
  return awr.Response.ok({'userId': id});
});
```

## Defining a Router

A `router` is used to encapsulate routes to be served. To create a `router`:

```dart
class UserRouter {
  /// To accept appwrite's context to pass it into `awr.Router(context)`
  final dynamic context;
  UserRouter(this.context);

  awr.Router get router {
  final router = awr.Router(context);

      router.get('/<userId|[0-9]+>', (awr.Request req, String userId) async {
        return awr.Response.ok({'userId': userId, 'name': 'User $userId'});
      });

      router.all('/<ignore|.*>', (awr.Request req) {
        return awr.Response(code: 404, body: {'error': 'User route not found'});
      });

      return router;

  }
}
```

## Mounting Routers

Routers can be composed and mounted under specific paths. Organize your routes cleanly with `.mount()`:

```dart
final root = awr.Router(context);
root.mount('/users/', UserRouter(context).router.call);
root.mount('/products/', ProductRouter(context).router.call);
```

> Each mounted `router` can have its own [middleware](#middleware) stack. See [middleware](#middleware) section below.

## Middleware

Middleware are simple wrappers around request handlers.
Middleware functions preprocess requests or postprocess responses:

```dart
/// Middleware to check for a valid Authorization header
awr.RequestHandler authMiddleware(awr.RequestHandler handler) {
  return (awr.Request request) async {
    final token = request.headers['authorization'];
    if (token != 'valid-token') {
// short circuit without executing deeper nested request handlers or middlewares
      return awr.Response(
        code: 401,
        body: {'error': 'Unauthorized'},
      );
    }
    return handler(request);
  };
}
```

Yet another way to define a middleware:

```dart
awr.Middleware myMiddleware() {
// Perform some preprocessing...
  return (handler) {
// Perform some other preprocessing...
    return (request) async {
// Even more preprocessing...
      return await handler(request);
    };
  };
}
```

Use `Pipeline().addMiddleware(...).handler(...)` to chain multiple middlewares for a given `router`.

```dart
final pipeline = awr.Pipeline()
  .addMiddleware(logMiddleware) //called first
  .addMiddleware(authMiddleware) //called next
  .handler(router.call); //called last
```

Routes can also have a stack of middleware. Middleware are passed-in as a list. Priority is given by the index of the middleware in the list.

```dart
// Priority is logMiddleware->middleware2->routeHandler
router.get('/webpage', middlewares: [logMiddleware, middleware2], (awr.Request req) {
  return awr.Response.ok("<h1>Hellow world</h1>", headers: {
  'content-type': 'text/html',
  'Access-Control-Allow-Origin': '\*',
  });
});
```

## Modify Requests and Responses

An `aw_router` `Request` and `Response` can be modified before passing them along or returning. This can be done in a `middleware` or `route` such as:

In a route

```dart
router.get('/', (awr.Request req) {
  //Avoid using print. This is here for demonstration purposes
  print("Request runtime type: $req");
  final res = awr.Response().modify(body: "Index page", code: 400);
  print("CURRENT RESPONSE ${res}");
  return res;
});
```

In a middleware

```dart
awr.RequestHandler modifyMiddleware(awr.RequestHandler handler) {
  return (request) async {
//Modify original request
    final modifiedReq = request.copyWith(context: {
      ...request.context,
      'myinternal': 'This is passed around internally'
    });

    final awr.Response response = await handler(modifiedReq);
    //Modify response from handler
    return response.modify(body: "Modfied response body(${response.body})");
  };
}
```

## Contributing

1. Fork the repo and clone it locally
2. Check out the `dev` branch
3. Open a PR with your enhancements (middleware, router features, docs, etc.)

> Feel free to open an issue or feature request first if you're not sure where to start!

## Credits

`shelf_router` for the bulk of the code relied upon by this package

## License

MIT © [Weav3r](https://github.com/Weav3r)
