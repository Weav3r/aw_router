// example/routers/appwrite_router.dart

import 'dart:io' show Platform;

import 'package:aw_router/aw_router.dart' as awr;
import 'package:dart_appwrite/dart_appwrite.dart';

class AppwriteRouter {
  final dynamic context;
  late final awr.Request parsedRequest;

  AppwriteRouter(this.context) {
    parsedRequest = awr.Request.parse(context.req);
  }

  /// Setup your Appwrite client here
  Client get _client => Client()
      .setEndpoint(Platform.environment['APPWRITE_FUNCTION_API_ENDPOINT'] ?? '')
      .setProject(Platform.environment['APPWRITE_FUNCTION_PROJECT_ID'] ?? '')
      .setKey(parsedRequest.headers['x-appwrite-key'] ?? '');

  Databases get _db => Databases(_client);
  // final String _databaseId = '[DATABASE_ID]'; // Replace with your database ID
  final String _databaseId =
      '6835256b000116cb91d2'; // Replace with your database ID
  final String _collectionId =
      '683525e100187d3aa6cb'; // Create a messages collection and set permission to 'Any'

  awr.Router get router {
    final r = awr.Router(context);

    // Create a message
    r.post('/messages', (awr.Request req) async {
      final body = req.bodyJson;
      final content = body['content'];

      final result = await _db.createDocument(
        databaseId: _databaseId,
        collectionId: _collectionId,
        documentId: 'unique()',
        data: {
          'content': content,
        },
      );
      return awr.Response.ok(result.toMap());
    });

    // Read all messages
    r.get('/messages', (awr.Request req) async {
      final result = await _db.listDocuments(
        databaseId: _databaseId,
        collectionId: _collectionId,
      );
      return awr.Response.ok(result.toMap());
    });

    // Get a specific message by ID
    r.get('/messagesy/<id|[a-z0-9]+>', (awr.Request req, String id) async {
      final result = await _db.getDocument(
        databaseId: _databaseId,
        collectionId: _collectionId,
        documentId: id,
      );
      return awr.Response.ok(result.toMap());
    });

    // Update a message
    r.put('/messages/<id>', (awr.Request req, String id) async {
      final body = req.bodyJson;
      final content = body['content'];

      final result = await _db.updateDocument(
        databaseId: _databaseId,
        collectionId: _collectionId,
        documentId: id,
        data: {'content': content},
      );
      return awr.Response.ok(result.toMap());
    });

    // Delete a message
    r.delete('/messages/<id>', (awr.Request req, String id) async {
      final result = await _db.deleteDocument(
        databaseId: _databaseId,
        collectionId: _collectionId,
        documentId: id,
      );
      return awr.Response.ok({"res": "$result", 'deleted': true});
    });

    return r;
  }
}
