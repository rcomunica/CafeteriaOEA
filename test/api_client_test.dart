import 'dart:convert';

import 'package:cafeteria_oea/core/network/api_client.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

void main() {
  test(
    'renueva la clave una vez y reintenta la solicitud tras un 401',
    () async {
      final client = _QueueClient([
        http.Response('{}', 401),
        http.Response(jsonEncode({'data': 'ok'}), 200),
      ]);
      var refreshes = 0;

      final response = await ApiClient(
        client: client,
        token: 'expired-token',
        onTokenExpired: () async {
          refreshes++;
          return 'new-token';
        },
      ).get('/products/read.php');

      expect(response, {'data': 'ok'});
      expect(refreshes, 1);
      expect(client.requests, 2);
      expect(client.authorizationHeaders, [
        'Bearer ${'expired-token'}',
        'Bearer ${'new-token'}',
      ]);
    },
  );
}

class _QueueClient extends http.BaseClient {
  _QueueClient(this.responses);

  final List<http.Response> responses;
  final authorizationHeaders = <String?>[];
  var requests = 0;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    authorizationHeaders.add(request.headers['Authorization']);
    requests++;
    final response = responses.removeAt(0);
    return http.StreamedResponse(
      Stream<List<int>>.value(response.bodyBytes),
      response.statusCode,
      headers: response.headers,
      request: request,
    );
  }
}
