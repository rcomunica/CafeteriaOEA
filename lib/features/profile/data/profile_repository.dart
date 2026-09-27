import 'package:cafeteria_oea/core/network/api_client.dart';

import '../domain/profile_item.dart';

class ProfileRepository {
  ProfileRepository(this.token);

  final String token;

  Future<ProfileItem> readProfile() async {
    final response = await ApiClient(token: token).get('/auth/me.php');
    if (response is! Map<String, dynamic> ||
        response['user'] is! Map<String, dynamic>) {
      throw const ApiException('La respuesta del perfil no es válida.');
    }

    return ProfileItem.fromJson(response['user'] as Map<String, dynamic>);
  }
}
