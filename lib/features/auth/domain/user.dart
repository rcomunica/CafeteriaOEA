class User {
  const User({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.role,
    required this.status,
  });

  final int id;
  final String name;
  final String email;
  final String phone;
  final String role;
  final String status;

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'email': email,
    'phone': phone,
    'role': role,
    'status': status,
  };

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] is num
          ? (json['id'] as num).toInt()
          : int.tryParse('${json['id']}') ?? 0,
      name: '${json['name'] ?? ''}',
      email: '${json['email'] ?? ''}',
      phone: '${json['phone'] ?? ''}',
      role: '${json['role'] ?? ''}',
      status: '${json['status'] ?? ''}',
    );
  }
}
