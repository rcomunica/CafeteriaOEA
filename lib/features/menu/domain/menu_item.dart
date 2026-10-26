class MenuItem {
  const MenuItem({
    required this.id,
    required this.name,
    required this.description,
    required this.category,
    required this.price,
    required this.isAvailable,
    this.image,
  });

  final String id;
  final String name;
  final String description;
  final String category;
  final int price;
  final bool isAvailable;
  final String? image;

  factory MenuItem.fromJson(Map<String, dynamic> json) {
    return MenuItem(
      id: '${json['id'] ?? ''}',
      name: '${json['name'] ?? json['nombre'] ?? ''}',
      description: '${json['description'] ?? json['descripcion'] ?? ''}',
      category: '${json['category'] ?? json['categoria'] ?? ''}',
      price: _parsePrice(json['price'] ?? json['precio']),
      isAvailable: json['is_available'] == 0 ? false : true,
      image: _parseImage(json),
    );
  }

  static String? _parseImage(Map<String, dynamic> json) {
    final value =
        json['image_url'] ?? json['image'] ?? json['image_path'] ?? json['imagen'];
    if (value == null || '$value'.trim().isEmpty) return null;
    return '$value'.trim();
  }

  String? get imageUrl {
    if (image == null) return null;
    if (image!.startsWith('http://') || image!.startsWith('https://')) {
      return image;
    }
    return '$_baseUrl/${image!.replaceFirst(RegExp(r'^/+'), '')}';
  }

  static const _baseUrl = 'http://10.0.2.2/api.cafeteria.test';

  static int _parsePrice(Object? value) {
    if (value is num) return value.toInt();
    if (value is String) {
      final doubleValue = double.tryParse(value) ?? 0.0;
      return doubleValue.toInt();
    }
    return 0;
  }
}
