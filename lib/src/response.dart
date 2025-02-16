// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:typed_data';

class Response {
  final int _statusCode;
  final Object? _body;
  final Map? headers;

  // Getter to get the body
  Object? get body => _body;
  int? get statusCode => _statusCode;

  // Private constructor to ensure singleton
  Response._(this._body, this._statusCode, this.headers);

  factory Response({Object? body, int? code, Map? headers}) {
    return Response._(body, code ?? 404, headers);
  }
  factory Response.ok(Object? body, {Map? headers}) {
    return Response._(body, 200, headers);
  }

  // Method to modify the body
  Response modify({required Object? body, int? code, Map? headers}) {
    return Response._(body ?? _body, code ?? _statusCode, headers);
  }

  dynamic runtimeResponse(dynamic response) {
    return switch (body) {
      String _ => response.text(body, _statusCode, headers),
      Map _ => response.json(body, _statusCode, headers),
      Uint8List _ => response.binary(body, _statusCode, headers),
      _ => response.empty(),
    };
  }

  // dynamic resBody(dynamic response) {
  //   if (body is String) {
  //     print('body is string');
  //     return response.text(body, _statusCode);
  //   } else if (body is Map) {
  //     print('body is json');
  //     return response.json(body, _statusCode);
  //   } else if (body is Uint8List) {
  //     print('body is binary');
  //     return response.binary(body, _statusCode);
  //   }
  //   print('body is empty');
  //   return response.empty();
  // }

  @override
  String toString() => 'Response(statusCode: $_statusCode, body: $_body)';
}
