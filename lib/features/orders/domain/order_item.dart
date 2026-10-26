import 'package:cafeteria_oea/features/orders/domain/order_status.dart';
import 'package:intl/intl.dart';

import 'order_line_item.dart';

class OrderItem {
  const OrderItem({
    required this.id,
    required this.userId,
    required this.total,
    required this.pickupCode,
    required this.notes,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    required this.orderItems,
  });

  final String id;
  final String userId;
  final int total;
  final String pickupCode;
  final String notes;
  final OrderStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<OrderLineItem> orderItems;

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    final rawOrderItems = json['order_items'];
    final parsedOrderItems = rawOrderItems is List
        ? rawOrderItems
              .whereType<Map>()
              .map(
                (item) =>
                    OrderLineItem.fromJson(Map<String, dynamic>.from(item)),
              )
              .toList(growable: false)
        : const <OrderLineItem>[];

    return OrderItem(
      id: '${json['id'] ?? ''}',
      userId: '${json['user_id'] ?? ''}',
      total: _parseTotal(json['total']),
      pickupCode: '${json['pickup_code'] ?? ''}',
      notes: '${json['notes'] ?? ''}',
      status: OrderStatus.fromString(json['status'] as String?),
      createdAt: _parseDateTime(json['created_at']),
      updatedAt: _parseDateTime(json['updated_at']),
      orderItems: parsedOrderItems,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'user_id': userId,
    'total': total,
    'pickup_code': pickupCode,
    'notes': notes,
    'status': status.value, // <- manda el string de la API
    'created_at': createdAt.toIso8601String(),
    'updated_at': updatedAt.toIso8601String(),
    'order_items': orderItems
        .map(
          (item) => {
            'id': item.id,
            'order_id': item.orderId,
            'product_id': item.productId,
            'product_name': item.productName,
            'price': item.price,
            'quantity': item.quantity,
            'subtotal': item.subtotal,
          },
        )
        .toList(),
  };

  static int _parseTotal(Object? value) {
    if (value is num) return value.toInt();
    if (value is String) {
      final doubleValue = double.tryParse(value) ?? 0.0;
      return doubleValue.toInt();
    }
    return 0;
  }

  static DateTime _parseDateTime(Object? value) {
    if (value is String) {
      try {
        return DateTime.parse(value);
      } catch (_) {
        return DateTime.fromMillisecondsSinceEpoch(0);
      }
    }
    return DateTime.fromMillisecondsSinceEpoch(0);
  }

  static final _dateFormat = DateFormat('dd/MM/yyyy hh:mm a');

  String get createdAtLabel => _dateFormat.format(createdAt.toLocal());
  String get updatedAtLabel => _dateFormat.format(updatedAt.toLocal());

  OrderItem copyWith({OrderStatus? status}) {
    return OrderItem(
      id: id,
      userId: userId,
      total: total,
      pickupCode: pickupCode,
      notes: notes,
      status: status ?? this.status,
      createdAt: createdAt,
      updatedAt: updatedAt,
      orderItems: orderItems,
    );
  }
}
