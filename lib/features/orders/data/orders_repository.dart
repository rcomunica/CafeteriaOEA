import 'package:cafeteria_oea/core/network/api_client.dart';
import 'package:cafeteria_oea/features/menu/domain/menu_item.dart';

class OrdersRepository {
  OrdersRepository({required this.items, required this.token});

  final String token;
  final List<MenuItem>? items;

  Future<Map<String, dynamic>> createOrderItem(
    int orderId,
    int productId,
    int quantity,
    int unitPrice,
    int totalPrice,
  ) async {
    final response = await ApiClient(token: token)
        .post('/order_items/create.php', {
          'order_id': orderId,
          'product_id': productId,
          'quantity': quantity,
          'unit_price': unitPrice,
          'total_price': totalPrice,
        });

    if (response is! Map<String, dynamic>) {
      throw const ApiException(
        'La respuesta de creación de item de orden no es válida.',
      );
    }

    return response;
  }

  Future<Map<String, dynamic>> createOrder(int total, String notes) async {
    final response = await ApiClient(token: token)
        .post('/orders/create.php', {'total': total, 'notes': notes});

    if (response is! Map<String, dynamic>) {
      throw const ApiException(
        'La respuesta de creación de orden no es válida.',
      );
    }

    items?.forEach((item) async {
      await createOrderItem(
        response['id'] as int,
        int.parse(item.id),
        1,
        item.price,
        item.price,
      );
    });

    return response;
  }
}
