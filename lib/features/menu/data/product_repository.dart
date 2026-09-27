import '../../../core/network/api_client.dart';
import '../domain/menu_item.dart';

class ProductRepository {
  ProductRepository(this.token);

  final String token;

  Future<List<MenuItem>> readAll() async {
    final response = await ApiClient(token: token)
        .get('/products/read.php', queryParameters: {'id': ''});
    final rawItems = response is List
        ? response
        : response is Map<String, dynamic>
        ? (response['data'])
        : const [];

    if (rawItems is! List) {
      throw const ApiException('La respuesta de productos no es válida.');
    }
    return rawItems
        .whereType<Map>()
        .map((item) => MenuItem.fromJson(Map<String, dynamic>.from(item)))
        .toList();
  }
}
