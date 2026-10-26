import '../../../core/network/api_client.dart';
import '../domain/menu_item.dart';

class ProductRepository {
  ProductRepository(this.token, {this.onTokenExpired});

  final String token;
  final TokenRefreshCallback? onTokenExpired;

  Future<List<MenuItem>> readAll() async {
    final response = await ApiClient(
      token: token,
      onTokenExpired: onTokenExpired,
    ).get('/products/read.php', queryParameters: {'id': ''});
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

  Future<void> createProduct({
    required String name,
    required String category,
    required int price,
    String? imagePath,
  }) async {
    await ApiClient(token: token, onTokenExpired: onTokenExpired).postMultipart(
      '/products/create.php',
      fields: {
        'name': name,
        'category': category,
        'price': '$price',
        'qty': '99',
      },
      filePath: imagePath,
    );
  }

  Future<void> updateProduct({
    required String id,
    required String name,
    required String category,
    required int price,
    String? imagePath,
  }) async {
    await ApiClient(token: token, onTokenExpired: onTokenExpired).postMultipart(
      '/products/update.php',
      queryParameters: {'id': id},
      fields: {
        'name': name,
        'category': category,
        'price': '$price',
        'qty': '99',
      },
      filePath: imagePath,
    );
  }
}
