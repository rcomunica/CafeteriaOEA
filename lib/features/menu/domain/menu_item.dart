class MenuItem {
  const MenuItem({
    required this.id,
    required this.name,
    required this.description,
    required this.category,
    required this.price,
    required this.isAvailable,
  });

  final String id;
  final String name;
  final String description;
  final String category;
  final int price;
  final bool isAvailable;

  factory MenuItem.fromJson(Map<String, dynamic> json) {
    return MenuItem(
      id: '${json['id'] ?? ''}',
      name: '${json['name'] ?? json['nombre'] ?? ''}',
      description: '${json['description'] ?? json['descripcion'] ?? ''}',
      category: '${json['category'] ?? json['categoria'] ?? ''}',
      price: _parsePrice(json['price'] ?? json['precio']),
      isAvailable: json['is_available'] == 0 ? false : true,
    );
  }

  static int _parsePrice(Object? value) {
    if (value is num) return value.toInt();
    if (value is String) {
      final doubleValue = double.tryParse(value) ?? 0.0;
      return doubleValue.toInt();
    }
    return 0;
  }
}
