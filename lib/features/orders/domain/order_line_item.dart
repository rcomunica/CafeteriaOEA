class OrderLineItem {
  const OrderLineItem({
    required this.id,
    required this.orderId,
    required this.productId,
    required this.productName,
    required this.price,
    required this.quantity,
    required this.subtotal,
  });

  final String id;
  final String orderId;
  final String productId;
  final String productName;
  final int price;
  final int quantity;
  final int subtotal;

  factory OrderLineItem.fromJson(Map<String, dynamic> json) {
    return OrderLineItem(
      id: '${json['id'] ?? ''}',
      orderId: '${json['order_id'] ?? ''}',
      productId: '${json['product_id'] ?? ''}',
      productName: '${json['product_name'] ?? 'Producto'}',
      price: _parseMoney(json['price']),
      quantity: _parseQuantity(json['quantity']),
      subtotal: _parseMoney(json['subtotal']),
    );
  }

  static int _parseMoney(Object? value) {
    if (value is num) return value.round();
    return double.tryParse('$value')?.round() ?? 0;
  }

  static int _parseQuantity(Object? value) {
    if (value is num) return value.toInt();
    return int.tryParse('$value') ?? 0;
  }
}
