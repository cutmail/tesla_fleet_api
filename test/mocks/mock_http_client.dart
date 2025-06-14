import 'dart:convert';
import 'package:http/http.dart' as http;

class MockHttpClient extends http.BaseClient {
  http.Response? _response;
  Exception? _throwError;
  http.BaseRequest? lastRequest;

  void setResponse(http.Response response) {
    _response = response;
    _throwError = null;
  }

  void setThrowError(Exception error) {
    _throwError = error;
    _response = null;
  }

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    lastRequest = request;

    if (_throwError != null) {
      throw _throwError!;
    }

    if (_response != null) {
      return http.StreamedResponse(
        Stream.fromIterable([utf8.encode(_response!.body)]),
        _response!.statusCode,
        headers: _response!.headers,
        request: request,
      );
    }

    return http.StreamedResponse(
      Stream.fromIterable([utf8.encode('{}')]),
      200,
      request: request,
    );
  }
}