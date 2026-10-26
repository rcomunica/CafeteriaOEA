import 'package:cafeteria_oea/core/network/api_client.dart';
import 'package:cafeteria_oea/features/auth/domain/user.dart';

class UserAdminRepository {
  UserAdminRepository(this.token, {this.onTokenExpired});

  final String token;
  final TokenRefreshCallback? onTokenExpired;

  ApiClient get _client =>
      ApiClient(token: token, onTokenExpired: onTokenExpired);

  Future<List<User>> readAll() async {
    final response = await _client.get('/users/read.php');
    final rawUsers = response is List
        ? response
        : response is Map<String, dynamic>
        ? (response['users'] ?? response['data'])
        : null;
    if (rawUsers is! List) {
      throw const ApiException('La respuesta de usuarios no es válida.');
    }
    return rawUsers
        .whereType<Map>()
        .map((item) => User.fromJson(Map<String, dynamic>.from(item)))
        .toList();
  }

  Future<void> updateUser({
    required int id,
    required String name,
    required String email,
    required String phone,
    required String role,
    required String status,
    String? password,
  }) async {
    await _client.post(
      '/users/update.php',
      {
        'name': name,
        'email': email,
        'phone': phone,
        'role': role,
        'status': status,
        if (password != null && password.isNotEmpty) 'password': password,
      },
      queryParameters: {'id': '$id'},
    );
  }
}
