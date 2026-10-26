import 'package:cafeteria_oea/features/orders/domain/order_item.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('parsea los items de una orden desde la respuesta de la API', () {
    final order = OrderItem.fromJson({
      'id': 33,
      'user_id': 4,
      'status': 'pending_payment',
      'total': '10500.00',
      'pickup_code': '30BBCEC4',
      'notes': 'test',
      'created_at': '2026-10-21 17:59:28',
      'updated_at': '2026-10-24 21:54:19',
      'order_items': [
        {
          'id': 19,
          'order_id': 33,
          'product_id': 9,
          'product_name': 'Empanada de pollo',
          'price': '3500.00',
          'quantity': 1,
          'subtotal': '3500.00',
        },
      ],
    });

    expect(order.orderItems, hasLength(1));
    expect(order.orderItems.single.productName, 'Empanada de pollo');
    expect(order.orderItems.single.price, 3500);
    expect(order.orderItems.single.quantity, 1);
    expect(order.orderItems.single.subtotal, 3500);
  });
}
