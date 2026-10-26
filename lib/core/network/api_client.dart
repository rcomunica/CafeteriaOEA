import 'dart:convert';

import 'package:http/http.dart' as http;

typedef TokenRefreshCallback = Future<String?> Function();

class ApiException implements Exception {
  const ApiException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  @override
  String toString() => message;
}

class ApiClient {
  ApiClient({http.Client? client, this.token, this.onTokenExpired})
    : _client = client ?? http.Client();

  // static const baseUrl = 'https://cafeteriaoea.cloud'
  static const baseUrl = 'http://10.0.2.2/api.cafeteria.test';

  final http.Client _client;
  final String? token;
  final TokenRefreshCallback? onTokenExpired;

  Future<Object?> get(String path, {Map<String, String>? queryParameters}) {
    return _send(
      (requestToken) => _client.get(
        _uri(path, queryParameters),
        headers: _headers(requestToken),
      ),
    );
  }

  Future<Object?> post(
    String path,
    Map<String, dynamic> body, {
    Map<String, String>? queryParameters,
  }) {
    return _send(
      (requestToken) => _client.post(
        _uri(path, queryParameters),
        headers: {
          ..._headers(requestToken),
          'Content-Type': 'application/json',
        },
        body: jsonEncode(body),
      ),
    );
  }

  Future<Object?> postMultipart(
    String path, {
    required Map<String, String> fields,
    String? filePath,
    String fileField = 'image',
    Map<String, String>? queryParameters,
  }) async {
    var requestToken = token;
    var request = await _multipartRequest(
      path,
      fields: fields,
      filePath: filePath,
      fileField: fileField,
      queryParameters: queryParameters,
      requestToken: requestToken,
    );
    var response = await http.Response.fromStream(await request.send());
    if (response.statusCode == 401 && onTokenExpired != null) {
      final refreshedToken = await onTokenExpired!();
      if (refreshedToken != null && refreshedToken.isNotEmpty) {
        requestToken = refreshedToken;
        request = await _multipartRequest(
          path,
          fields: fields,
          filePath: filePath,
          fileField: fileField,
          queryParameters: queryParameters,
          requestToken: requestToken,
        );
        response = await http.Response.fromStream(await request.send());
      }
    }
    return _decodeResponse(response);
  }

  Future<http.MultipartRequest> _multipartRequest(
    String path, {
    required Map<String, String> fields,
    required String? filePath,
    required String fileField,
    required Map<String, String>? queryParameters,
    required String? requestToken,
  }) async {
    final request = http.MultipartRequest('POST', _uri(path, queryParameters))
      ..headers.addAll(_headers(requestToken));
    request.fields.addAll(fields);
    if (filePath != null && filePath.isNotEmpty) {
      request.files.add(await http.MultipartFile.fromPath(fileField, filePath));
    }
    return request;
  }

  Map<String, String> _headers(String? requestToken) => {
    if (requestToken != null && requestToken.isNotEmpty)
      'Authorization': 'Bearer $requestToken',
  };

  Uri _uri(String path, [Map<String, String>? queryParameters]) {
    return Uri.parse('$baseUrl$path').replace(queryParameters: queryParameters);
  }

  Future<Object?> _send(
    Future<http.Response> Function(String? token) request,
  ) async {
    var requestToken = token;
    var response = await request(requestToken);
    if (response.statusCode == 401 && onTokenExpired != null) {
      final refreshedToken = await onTokenExpired!();
      if (refreshedToken != null && refreshedToken.isNotEmpty) {
        requestToken = refreshedToken;
        response = await request(requestToken);
      }
    }

    return _decodeResponse(response);
  }

  Object? _decodeResponse(http.Response response) {
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
