import 'dart:convert';

import 'package:http/http.dart' as http;

class ApiException implements Exception {
  const ApiException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  @override
  String toString() => message;
}

class ApiClient {
  ApiClient({http.Client? client, this.token})
    : _client = client ?? http.Client();

  static const baseUrl = 'http://10.0.2.2/api.cafeteria.test/';
  // static const baseUrl = 'http://api.cafeteria.test/';

  final http.Client _client;
  final String? token;

  Future<Object?> get(String path, {Map<String, String>? queryParameters}) {
    return _send(
      () => _client.get(_uri(path, queryParameters), headers: _headers()),
    );
  }

  Future<Object?> post(String path, Map<String, dynamic> body) {
    return _send(
      () => _client.post(
        _uri(path),
        headers: {..._headers(), 'Content-Type': 'application/json'},
        body: jsonEncode(body),
      ),
    );
  }

  Map<String, String> _headers() => {
    if (token != null && token!.isNotEmpty) 'Authorization': 'Bearer $token',
  };

  Uri _uri(String path, [Map<String, String>? queryParameters]) {
    return Uri.parse('$baseUrl$path').replace(queryParameters: queryParameters);
  }

  Future<Object?> _send(Future<http.Response> Function() request) async {
    final response = await request();
    Object? decoded;
    if (response.body.isNotEmpty) {
      try {
        decoded = jsonDecode(response.body);
      } on FormatException {
        throw ApiException('La API devolvió una respuesta inválida.');
      }
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      final message = decoded is Map<String, dynamic>
          ? '${decoded['message'] ?? decoded['error'] ?? 'Error de la API.'}'
          : 'Error de la API (${response.statusCode}).';
      throw ApiException(message, statusCode: response.statusCode);
    }
    return decoded;
  }
}
