import 'package:aw_router/aw_router.dart' as awr;

class ProductRouter {
  final dynamic context;
  ProductRouter([this.context]);

  // Simulate a product store using an in-memory map.
  final Map<String, Map<String, dynamic>> _products = {
    '1': {
      'id': '1',
      'title': 'Laptop',
      'description': 'A laptop',
      'price': 999.99
    },
    '2': {
      'id': '2',
      'title': 'Phone',
      'description': 'A smartphone',
      'price': 499.99
    },
  };

  // Define a router that handles product-related endpoints.
  awr.Router get router {
    // final r = awr.Router(context, fallbackLogLevel: awr.LogLevel.none);
    final r = awr.Router(context);

    // List all products.
    r.get('/', (awr.AwRequest req) async {
      // req.context['logger'] = 'foo';
      req.logDebug('I debug you');
      req.logInfo('Informing you');
      // req.logWarning('I WARN you');
      // req.logError('Fetching all products');
      r.error('I WARN you');
      r.error('Fetching all products');
      return awr.AwResponse.ok(_products.values.toList());
    });

    // Retrieve a single product by ID (only numeric IDs allowed).
    r.get('/<id|[0-9]+>', (awr.AwRequest req, String id) async {
      final product = _products[id];
      if (product == null) {
        return awr.AwResponse(code: 404, body: {'error': 'Product not found'});
      }
      return awr.AwResponse.ok(product);
    });

    r.head('/<id|[0-9]+>', (awr.AwRequest req, String id) async {
      final product = _products[id];
      if (product == null) {
        return awr.AwResponse(code: 404, body: {'error': 'Product not found'});
      }
      return awr.AwResponse.ok(product);
    });

    // Create a new product.
    r.post('/', (awr.AwRequest req) async {
      final product = req.bodyJson;

      // Perform basic validation.
      final errors = <String>[];
      if (product['title'] == null ||
          product['title'].toString().trim().isEmpty) {
        errors.add('Title is required.');
      }
      if (product['price'] == null || product['price'] is! num) {
        errors.add('Price must be a number.');
      }

      if (errors.isNotEmpty) {
        return awr.AwResponse(
            code: 400, body: {'error': 'Validation failed', 'details': errors});
      }

      // Simulate ID assignment for new product.
      final newId = (_products.length + 1).toString();
      final newProduct = {...product, 'id': newId};
      _products[newId] = newProduct;

      return awr.AwResponse(
        code: 201,
        body: {'message': 'Product created', 'product': newProduct},
      );
    });

    // Update fields of an existing product.
    r.patch('/<id|[0-9]+>', (awr.AwRequest req, String id) async {
      final updates = req.bodyJson;
      final product = _products[id];

      if (product == null) {
        return awr.AwResponse(code: 404, body: {'error': 'Product not found'});
      }

      // Validate fields if present in the update.
      final errors = <String>[];
      if (updates.containsKey('title') &&
          (updates['title'] == null ||
              updates['title'].toString().trim().isEmpty)) {
        errors.add('Title is required.');
      }
      if (updates.containsKey('price') && updates['price'] is! num) {
        errors.add('Price must be a number.');
      }

      if (errors.isNotEmpty) {
        return awr.AwResponse(
            code: 400, body: {'error': 'Validation failed', 'details': errors});
      }

      // Apply updates to the product.
      _products[id] = {...product, ...updates, 'id': id};

      return awr.AwResponse.ok({
        'message': 'Product updated',
        'product': _products[id],
      });
    });

    r.get('/shoe', (awr.AwRequest req) {
      return awr.AwResponse.routeNotFound;
    });

    // r.get('/waakye', (awr.Request req) {
    //   return awr.Response.ok({'food': 'Waakye!'});
    // });

    // r.all('/<ignored|.*>', (awr.Request req) {
    //   return awr.Response(body: {'error': 'Not Found in /products'});
    // });

    return r;
  }
}
