# aw_router

A lightweight, composable, and middleware-friendly router designed for use with [Appwrite Cloud Functions](https://appwrite.io/docs/functions). It provides expressive route definitions, robust parameter parsing, and flexible middleware pipelines for powerful request handling. Inspired by [shelf_router](https://pub.dev/packages/shelf_router) and tailored for Dart functions, it's built to be modular and ergonomic.

---

## Quick Links

- [Features](#features)
- [Getting Started](#getting-started)
- [Usage Example](#usage-example)
- [Routes](#routes)
- [Defining Routes](#defining-routes)
- [Path Parameters](#path-parameters)
- [Defining a Router](#defining-a-router)
- [Mounting Routers](#mounting-routers)
- [Grouping Routes](#grouping-routes)
- [Middleware](#middleware)
- [Modify Requests and Responses](#modify-requests-and-responses)
- [Error Handling](#error-handling)
- [Advanced Usage & Utilities](#advanced-usage--utilities)
  - [In-built Logging & Custom Loggers](#in-built-logging--custom-loggers)
  - [Middleware Introspection](#middleware-introspection)
- [Contributing](#contributing)
- [Credits](#credits)
- [License](#license)

---

## Features

- **Appwrite-native**: Fully compatible with Appwrite Cloud Function context.
- **Declarative Route Registration**: Define routes for `GET`, `POST`, `PATCH`, `DELETE`, and all other HTTP methods.
- **Regex-Powered Routing**: Supports dynamic path parameters with optional regex constraints (e.g., `/user/<id|[0-9]`>`).
- **Composable Middleware Pipelines**: Build flexible request/response processing chains with support for short-circuiting and transformations.
- **Router Mounting**: Organize routes modularly using `.mount()` for sub-applications (e.g., `/api/`, `/users/`).
- **Graceful Error Handling**: Customize `onNotFound` and `onError` handlers for comprehensive error management.
- **Testable Request/Response Objects**: Utilizes `AwRequest` and `AwResponse` for easy local invocation and testing.
- **Context Injection**: Automatically handles Appwrite context or provides a default context for local development/testing.
- **Built-in Logging**: Includes an `awrLogMiddleware` for easy request logging and `AwRequest` extensions for logger access.
- **Zero-Dependency Core**: A lean core for optimal performance and simplicity.

---

## Getting Started

Add the package to your `pubspec.yaml`:

```yaml
dependencies:
  aw_router: ^0.1.0-beta
```

## Usage Example

This is a basic example showcasing `aw_router`'s core features. See the [example/](example/) directory for a more advanced setup.

```dart
import 'package:aw_router/aw_router.dart';

// Define a router to group related routes, typically in a separate file.
// This encapsulates API logic for users.
class UserRouter {
  // Router takes a dynamic context, which can be Appwrite's context
  // or null for default local context.
  final dynamic context;
  UserRouter(this.context);

  Router get router {
    // Instantiate Router with the provided context.
    final r = Router(context);

    // Define a GET route with a path parameter.
    // Optionally access path parameters via req.routeParams.
    r.get('/<userId|[0-9]+>', (AwRequest req, String userId) async {
      return AwResponse.ok({'userId': userId, 'name': 'User $userId'});
    });

    // Catch-all route for paths within /users/ that don't match specific routes.
    r.all('/<ignore|.*>', (AwRequest req) {
      return AwResponse.notFound(message: 'User route not found');
    });

    return r;
  }
}

// Your main Appwrite Cloud Function entry point.
Future<dynamic> main(final context) async {
  try {
    // Initialize the root router with the Appwrite context.
    // Router intelligently wraps Appwrite's context or provides a default.
    final rootRouter = Router(context, fallbackLogLevel: LogLevel.verbose);

    // Apply global error handling (optional but recommended).
    rootRouter.onError((req, error, st) {
      req.logError('Unhandled router error: $error', error: error, stackTrace: st);
      return AwResponse.internalServerError(
          message: 'An unexpected error occurred.');
    });

    // Define a pipeline for the UserRouter.
    // This pipeline includes middleware that will run BEFORE any handler in UserRouter.
    final userPipeline = Pipeline()
        .addMiddleware(awrLogMiddleware(
          logFn: rootRouter.log,
          errorFn: rootRouter.error,
          level: LogLevel.info  //Applies to all middleware below and routes (in UserRouter)
        )) // Injects a logger and logs requests
        .addMiddleware(authMiddleware)   // Your custom auth middleware (see below)
        .handler(UserRouter(context).router.call); // The UserRouter instance is callable

    // Mount the 'UserRouter' pipeline to handle requests under '/users/'.
    // E.g., a request to '/users/123' will be handled by UserRouter.
    rootRouter.mount('/users/', userPipeline);

    // Define a simple root route.
    rootRouter.get('/', (AwRequest req) {
      return AwResponse.ok('Welcome to aw_router!');
    });

    // Define a fallback for any unmatched paths in the root router.
    rootRouter.onNotFound((AwRequest req) {
      req.logInfo('No route found for ${req.method} ${req.path}');
      return AwResponse.notFound();
    });

    // Parse the incoming Appwrite request into an AwRequest.
    // Router.call expects an AwRequest.
    final awRequest = AwRequest.parse(context.req);

    // Route the request. The router instance itself is a callable handler.
    final awResponse = await rootRouter.call(awRequest);

    // Convert the AwResponse back to Appwrite's response format.
    return awResponse.runtimeResponse(context.res);
  } catch (e, st) {
    // Catch any errors that occur before the router can handle them.
    context.error('Global unhandled error: $e --- $st');
    return context.res.empty(); // Return an empty response for catastrophic failures
  }
}

// Example custom authentication middleware
RequestHandler authMiddleware(RequestHandler handler)
  {
    return (AwRequest request) async {
      final token = request.headers['authorization'];
      if (token != 'Bearer valid-token') {
        request.logWarning('AuthMiddleware: Unauthorized attempt.');
        return AwResponse(code: 401, body: 'Unauthorized'); // Short-circuit, return 401
      }
      request.logDebug('AuthMiddleware: Token valid, proceeding.');
      return handler(request); // Pass to the next handler
    };
}
```

---

## Routes

Routes define the endpoints that your Appwrite function will handle.
Here's how to define routes in `aw_router`:

### Defining Routes

```dart
final router = Router(context); // Use Router

router.get('/hello', (AwRequest req) async {
  return AwResponse.ok({'message': 'Hello world!'});
});

router.get('/webpage', (AwRequest req) {
  return AwResponse.ok("<h1>Hello world</h1>", headers: {
    'content-type': 'text/html',
    'Access-Control-Allow-Origin': '*',
  });
});

router.post('/submit', (AwRequest req) async {
  final data = req.bodyJson; // Access request body as JSON
  return AwResponse(body: {'received': data}, code: 201, headers: {'x-awr-header': 'My header'});
});
```

### Path Parameters

Routes support inline path parameters with optional regex constraints, similar to `shelf_router`. Access parameters using `req.routeParams`.

```dart
router.get('/user/<id|[0-9]+>', (AwRequest req) async {
  final id = req.routeParams['id']; // Access parameter by name
  return AwResponse.ok({'userId': id});
});

// Path parameters map automatically to handler arguments their order.
rootRouter.get('/items/<category>/<itemId>', (AwRequest req, String category, String itemId) async {
  // Values are always Strings — use manual conversion when needed.
  final price = 10 * (int.tryParse(itemId) ?? 5);
  return AwResponse.ok({'category': category, 'itemId': itemId, 'price': price});
});
```

---

## Defining a Router

A `Router` instance is used to encapsulate routes to be served. You can define them in separate classes for better organization:

```dart
class UserRouter {
  /// Accepts Appwrite's context to pass it into `Router(context)`.
  final dynamic context;
  UserRouter(this.context);

  Router get router {
    final router = Router(context);

    router.get('/<userId|[0-9]+>', (AwRequest req, String userId) async {
      return AwResponse.ok({'userId': userId, 'name': 'User $userId'});
    });

    router.all('/<ignore|.*>', (AwRequest req) {
      return AwResponse.notFound(message: 'User route not found');
    });

    return router;
  }
}
```

---

## Mounting Routers

Routers can be composed and mounted under specific paths. This helps organize your routes cleanly with `.mount()`:

```dart
final rootRouter = Router(context);
rootRouter.mount('/users/', UserRouter(context).router.call); // Mount UserRouter
rootRouter.mount('/products/', ProductRouter(context).router.call); // Mount another router
```

> Each mounted `router` can have its own [middleware](#middleware) stack, applied via a `Pipeline` before mounting.

---

## Grouping Routes

The `router.group()` method allows you to organize routes under a common URL prefix and apply shared middlewares to them. This helps in building a cleaner, more modular API structure by reducing repetitive path definitions and middleware assignments.

The `builder` function passed to `group` receives a new `Router` instance (a special "grouped" router) where all paths you define will automatically be prepended with the group's prefix. Any `middlewares` provided to `group` will run _before_ any route-specific middlewares defined within that group.

```dart
final apiRouter = Router(context);

// Define a group for API v1 endpoints
apiRouter.group('/v1', (v1) {
  // All routes defined inside 'v1' will be prefixed with '/v1'
  // e.g., '/v1/status'
  v1.get('/status', (AwRequest req) {
    return AwResponse.ok({'api_version': '1.0', 'status': 'ok'});
  });

  // You can even nest groups (e.g., /v1/admin/users)
  v1.group('/admin', (admin) {
    admin.get('/users', (AwRequest req) {
      return AwResponse.ok({'message': 'Admin users list'});
    });
  }, middlewares: [
    // This middleware only applies to /v1/admin/* routes
    awrLogMiddleware(level: LogLevel.info)
  ]);

  // A route within '/v1' with its own specific middleware
  v1.post('/data', (AwRequest req) {
    final data = req.bodyJson;
    return AwResponse.created(body: {'received': data});
  }, middlewares: [
    // This middleware only applies to '/v1/data'
    myConfigurableMiddleware('Data Processed')
  ]);

}, middlewares: [
  // These middlewares apply to ALL routes under '/v1/*'
  // and run before any nested group or route-specific middlewares.
  authMiddleware,
  myConfigurableMiddleware('API V1 Global')
]);

// A request to /v1/status will hit:
// 1. authMiddleware
// 2. myConfigurableMiddleware('API V1 Global')
// 3. /v1/status handler
```

---

## Middleware

Middleware functions are simple wrappers around request handlers that preprocess requests or postprocess responses. They form a chain, where each middleware can modify the request, decide to pass it to the next handler, or short-circuit the pipeline by returning a response directly.

`aw_router` supports two common patterns for defining middleware:

### Pattern 1: Direct Handler Transformer

This pattern defines a middleware as a function that directly takes a `RequestHandler` and returns a new `RequestHandler`. It's concise when your middleware doesn't require any external configuration or state from its definition site.

```dart
/// Middleware to check for a valid Authorization header
RequestHandler authMiddleware(RequestHandler handler) {
  return (AwRequest request) async {
    final token = request.headers['authorization'];
    if (token != 'Bearer valid-token') {
      // short-circuit without executing deeper nested request handlers or middlewares
      return AwResponse(code: 401,
          body: {'error': 'Unauthorized - Invalid Token'});
    }
    return handler(request); // Continue to the next handler
  };
}

/// Middleware to log incoming requests (simpler version)
RequestHandler logMiddleware(RequestHandler handler) {
  return (AwRequest request) async {
    // Note: For advanced logging with injected logger, prefer awrLogMiddleware()
    print('Incoming request: ${request.method} ${request.path}');
    final AwResponse response = await handler(request);
    print('Response status: ${response.statusCode}');
    return response;
  };
}
```

### Pattern 2: Middleware Factory (Canonical)

This pattern defines a middleware as a function that _returns_ a `Middleware` (`RequestHandler Function(RequestHandler)`). This is the more flexible and canonical approach, as it allows your middleware to encapsulate configuration (e.g., `awrLogMiddleware` takes `level`, `logFn`, `errorFn`).

```dart
import 'package:aw_router/aw_router.dart';

/// A configurable middleware that adds a custom header and logs.
Middleware myConfigurableMiddleware(String headerValue) {
  return (RequestHandler next) { // 'next' is the subsequent handler in the pipeline
    return (AwRequest request) async {
      // --- Pre-processing logic ---
      request.logInfo('[Middleware] Request received for ${request.path}');
      
      // Optionally modify the request
      final modifiedRequest = request.copyWith(context: {
        ...request.context,
        'customData': 'Added by myConfigurableMiddleware'
      });

      // Pass the request to the next handler in the pipeline.
      final AwResponse response = await next(modifiedRequest);

      // --- Post-processing logic ---
      request.logInfo('[Middleware] Response status: ${response.statusCode}');
      // Optionally modify the response
      return response.modify(headers: {'X-Custom-Header': headerValue});
    };
  };
}
```

### **Chaining Middleware with `Pipeline`:**

Use `Pipeline().addMiddleware(...).handler(...)` to chain multiple middlewares. This is crucial when mounting a router or setting up a global middleware stack.

```dart
import 'package:aw_router/aw_router.dart'

final myRouter = UserRouter(context).router; // Assume UserRouter is defined

final pipeline = Pipeline()
  .addMiddleware(awrLogMiddleware())
  .addMiddleware(authMiddleware)
  // Configurable middleware (Pattern 2)
  .addMiddleware(myConfigurableMiddleware('CustomValue'))
  .handler(myRouter.call); // The final handler in this pipeline (the router itself)

// Now, mount this pipeline:
rootRouter.mount('/my-api/', pipeline);
```

### **Route-Specific Middleware:**

Routes can also have their own specific middleware stack. Middlewares are passed in as a list, and priority is given by their order in the list (left to right).

```dart
import 'package:aw_router/aw_router.dart'; // For awrLogMiddleware

// Priority: awrLogMiddleware -> myConfigurableMiddleware -> route handler
router.get('/secure-page', middlewares: [
  awrLogMiddleware(),
  myConfigurableMiddleware('Route Specific Value'),
], (AwRequest req) {
  return AwResponse.ok("<h1>Secure Content</h1>");
});
```

---

## Modify Requests and Responses

`AwRequest` and `AwResponse` objects are immutable, but you can create new instances with modified properties using their `copyWith` and `modify` methods, respectively. This is powerful for transformations in middlewares or route handlers.

### In a Route Handler

```dart
router.get('/', (AwRequest req) {
  // Use req.copyWith to get a new request with modifications (e.g., adding context). To "remove" data from the context, set its value to null.
  final modifiedReq = req.copyWith(context: {
    ...req.context,
    'myInternalData': 'Some value for this request'
  });

  // Use AwResponse.modify to create a new response with changes
  final res = AwResponse.ok("Original page")
      .modify(body: "Index page changed!", code: 202);

  req.logDebug("Modified request context: ${modifiedReq.getContext<String>('myInternalData')}");
  req.logDebug("Modified response body: ${res.body}");
  return res;
});


// Or use AwRequest.withContext and AwRequest.removeContext convenience methods
router.get('/context-example', (AwRequest req) {
  final reqWithAddedData = req
      .withContext('foo', 'some_value');
  req.logInfo('Foo data in context: ${req.context}');

  final reqWithoutFoo = reqWithAddedData.removeContext('foo');
  req.logInfo('Foo data after removal: ${req.context}');

  // Modify the response as usual.
  final res = AwResponse.ok("Context example response")
      .modify(body: "Context handling demonstrated!", code: 200);

  return res;
});
```

### In a Middleware

```dart
Middleware modifyMiddleware() {
  return (RequestHandler handler) {
    return (AwRequest request) async {
      // Modify original request before passing it down
      final modifiedReq = request.withContext(
        'myinternal', 'This is passed around internally by middleware'
      );

      // Pass modified request to the next handler
      final AwResponse response = await handler(modifiedReq);

      // Modify response from handler before returning it
      return response.modify(body: "Modified by middleware: ${response.body}");
    };
  };
}
```

---

## Error Handling

`aw_router` provides dedicated mechanisms for handling routes that don't match or for unhandled exceptions during request processing.

### Custom 404 Not Found Handler

Use `router.onNotFound()` to specify a custom handler for requests that don't match any registered route:

```dart
final router = Router(context);

router.onNotFound((AwRequest req) {
  req.logInfo('404: No route found for ${req.method} ${req.path}');
  return AwResponse.notFound(message: 'Sorry, this page does not exist.');
});
```

### Global Exception Handler

Use `router.onError()` to catch any unhandled exceptions that occur within your route handlers or middlewares:

```dart
final router = Router(context);

router.onError((AwRequest req, Object error, StackTrace stack) {
  req.logError('An unhandled error occurred for ${req.path}: $error', error: error, stackTrace: stack);
  // Return a user-friendly error response
  return AwResponse.internalServerError(message: 'Something went wrong on our end.');
});
```

---

## Advanced Usage & Utilities

`aw_router` includes several built-in utilities and patterns to enhance logging, debugging, and conditional application of middleware.

### In-built Logging & Custom Loggers

`aw_router` provides convenient logging capabilities through a `Logger` instance injected into the `AwRequest` context.

1.  **Injecting the Logger**:
    The recommended way to inject a `Logger` is by adding `awrLogMiddleware()` to your middleware pipeline (e.g., globally or at a mount point). This middleware creates a `DefaultLogger` and places it in `request.context`.

    ```dart
    import 'package:aw_router/aw_router.dart';

    // Global logger setup
    final rootRouter = Router(context);
    final globalPipeline = Pipeline()
      .addMiddleware(awrLogMiddleware()) // Injects a logger and logs request/response details
      // ... other global middlewares
      .handler(rootRouter.call);

    // Later, when calling the router:
    // final awResponse = await globalPipeline(awRequest);
    ```

2.  **Accessing the Logger**:
    Once injected, you can access the logger from any `AwRequest` instance using the `RequestLogExtension` methods: `logInfo`, `logDebug`, `logWarning`, `logError`.

    ```dart
    router.get('/my-route', (AwRequest req) {
      req.logInfo('Processing request for /my-route');
      req.logDebug('Headers: ${req.headers}');
      // ...
      try {
        // ... some operation
      } catch (e, st) {
        req.logError('Error processing /my-route', error: e, stackTrace: st);
      }
      return AwResponse.ok('Done');
    });
    ```

3.  **Customizing the Logger**:
    You can customize the `DefaultLogger`'s behavior (e.g., where it logs to) by providing custom `logFn` and `errorFn` callbacks to `awrLogMiddleware`. This is useful for integrating with external logging services or custom output formats.

    ```dart
    import 'package:aw_router/aw_router.dart';

    void customLogFunction(String message) {
      // Send to a monitoring service, or a custom file, etc.
      print('CUSTOM LOG [INFO]: $message');
    }

    void customErrorFunction(String message) {
      // Send error to an error tracking system
      print('CUSTOM LOG [ERROR]: $message');
    }

    // Apply custom logger configuration
    final customLoggerPipeline = Pipeline()
      .addMiddleware(awrLogMiddleware(
        level: LogLevel.info, // Set minimum logging level
        logFn: customLogFunction,
        errorFn: customErrorFunction,
      ))
      .handler(myRouter.call);
    ```

4.  **Fallback Logger**:
    If `awrLogMiddleware` is _not_ used, `Router` automatically provides a simple fallback logger that prints messages to standard output. You can control its minimum level during router instantiation:

    ```dart
    // In your main function
    final rootRouter = Router(
      context,
      fallbackLogLevel: LogLevel.warning, // Only warnings and errors will be logged by fallback
    );
    ```

### Middleware Introspection

The `awrWrapWithIntrospection` helper middleware allows you to easily monitor the execution flow and performance of other middlewares in your pipeline. It logs when a middleware is entered, exited, and how long it took. It also warns if a middleware "short-circuited" (didn't call the `next` handler).

```dart
import 'package:aw_router/aw_router.dart';

// A simple example middleware to be wrapped
Middleware myLoggingAuthMiddleware() {
  return (RequestHandler next) {
    return (AwRequest request) async {
      request.logInfo('Auth check inside myLoggingAuthMiddleware');
      final token = request.headers['x-auth-token'];
      if (token == 'secret') {
        return next(request); // Proceed
      }
      return AwResponse.unauthorized(); // Short-circuit
    };
  };
}

// Apply introspection
final introspectedPipeline = Pipeline()
  .addMiddleware(awrLogMiddleware()) // Make sure logger is available
  .addMiddleware(
    awrWrapWithIntrospection(
      myLoggingAuthMiddleware(), // The middleware you want to inspect
      'MyAuthMiddleware',         // A name for logging
    ),
  )
  .handler(myRouter.call);

// When a request goes through, you'll see logs like:
// [DEBUG] ▶ Enter: MyAuthMiddleware
// [INFO] Auth check inside myLoggingAuthMiddleware
// [DEBUG] ◀ Exit: MyAuthMiddleware [1234µs]
// Or if it short-circuited:
// [WARNING] ⚠️ Middleware "MyAuthMiddleware" short-circuited
```

---

## Contributing

#### Bug Reports & Feature Requests

Please use the [issue tracker](https://github.com/Weav3r/aw_router/issues) to report any bugs or file feature requests.

#### Developing

PRs are welcome. To begin developing, do this:

1.  Fork the repo and clone it locally.
2.  Check out the `dev` branch.
3.  Open a Pull Request (PR) with your enhancements (middleware, router features, docs, etc.).

> Feel free to open an issue or feature request first if you're not sure where to start!

---

## Credits

`aw_router` heavily relies on the foundational work from `shelf_router` for its core routing logic.

---

## License

MIT © [Weav3r](https://github.com/Weav3r)