import 'package:cafeteria_oea/core/network/api_client.dart';
import 'package:cafeteria_oea/features/menu/domain/menu_item.dart';
import 'package:cafeteria_oea/features/orders/domain/order_item.dart';
import 'package:cafeteria_oea/features/orders/domain/order_status.dart';

class OrdersRepository {
  OrdersRepository({
    required List<MenuItem>? items,
    required this.token,
    required this.userId,
    this.onTokenExpired,
  }) : items = items == null ? null : List<MenuItem>.of(items);

  final String token;
  final int userId;
  final TokenRefreshCallback? onTokenExpired;
  final List<MenuItem>? items;

  Future<List<OrderItem>> fetchOrders() async {
    final response = await ApiClient(
      token: token,
      onTokenExpired: onTokenExpired,
    ).get('/orders/read.php', queryParameters: {'user_id': '$userId'});

    final rawItems = switch (response) {
      List<dynamic>() => response,
      Map<String, dynamic>() =>
        response['data'] is List
            ? response['data']
            : response['id'] != null
            ? [response]
            : const [],
      _ => const [],
    };

    if (rawItems is! List) {
      throw const ApiException('La respuesta de productos no es válida.');
    }

    return rawItems
        .map((json) => OrderItem.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  Future<List<OrderItem>> fetchAllOrders() async {
    final response = await ApiClient(
      token: token,
      onTokenExpired: onTokenExpired,
    ).get('/orders/read.php');

    final rawItems = switch (response) {
      List<dynamic>() => response,
      Map<String, dynamic>() =>
        response['data'] is List
            ? response['data']
            : response['id'] != null
            ? [response]
            : const [],
      _ => const [],
    };

    if (rawItems is! List) {
      throw const ApiException('La respuesta de productos no es válida.');
    }

    return rawItems
        .map((json) => OrderItem.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  Future<OrderItem> fetchOrderById(String orderId) async {
    final response = await ApiClient(
      token: token,
      onTokenExpired: onTokenExpired,
    ).get('/orders/read.php', queryParameters: {'order_id': orderId});

    final rawOrder = switch (response) {
      Map<String, dynamic>() when response['data'] is Map => response['data'],
      Map<String, dynamic>() when response['data'] is List =>
        (response['data'] as List).firstOrNull,
      Map<String, dynamic>() => response,
      List<dynamic>() => response.firstOrNull,
      _ => null,
    };

    if (rawOrder is! Map) {
      throw const ApiException('La API no devolvió la orden solicitada.');
    }

    return OrderItem.fromJson(Map<String, dynamic>.from(rawOrder));
  }

  Future<void> updateOrderStatus(String orderId, OrderStatus status) async {
    await ApiClient(
      token: token,
      onTokenExpired: onTokenExpired,
    ).post(
      '/orders/update.php',
      {'status': status.value},
      queryParameters: {'id': orderId},
    );
  }

  Future<Map<String, dynamic>> createOrderItem(
    int orderId,
    int productId,
    int quantity,
    int unitPrice,
  ) async {
    final response =
        await ApiClient(token: token, onTokenExpired: onTokenExpired).post(
          '/order_items/create.php',
          {
            'order_id': orderId,
            'product_id': productId,
            'quantity': quantity,
            'unit_price': unitPrice,
          },
        );

    if (response is! Map<String, dynamic>) {
      throw const ApiException(
        'La respuesta de creación de item de orden no es válida.',
      );
    }

    return response;
  }

  Future<Map<String, dynamic>> createOrder(int total, String notes) async {
    final response = await ApiClient(
      token: token,
      onTokenExpired: onTokenExpired,
    ).post('/orders/create.php', {'total': total, 'notes': notes});

    if (response is! Map<String, dynamic>) {
      throw const ApiException(
        'La respuesta de creación de orden no es válida.',
      );
    }
    final orderId = _parseId(
      response['id'],
      'La API no devolvió el id de la orden.',
    );
    for (final item in items ?? const <MenuItem>[]) {
      await createOrderItem(
        orderId,
        _parseId(item.id, 'El producto ${item.name} no tiene un id válido.'),
        1,
        item.price,
      );
    }

    return response;
  }

  int _parseId(Object? value, String errorMessage) {
    final id = value is int ? value : int.tryParse('$value');
    if (id == null) {
      throw ApiException(errorMessage);
    }
    return id;
  }
}
