class ProfileItem {
  const ProfileItem({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.role,
    required this.isActive,
  });
  final String id;
  final String name;
  final String email;
  final String phone;
  final String role;
  final bool isActive;

  factory ProfileItem.fromJson(Map<String, dynamic> json) {
    return ProfileItem(
      id: '${json['id'] ?? ''}',
      name: '${json['name'] ?? json['nombre'] ?? ''}',
      email: '${json['email'] ?? json['correo'] ?? ''}',
      phone: '${json['phone'] ?? json['telefono'] ?? ''}',
      role: '${json['role'] ?? json['rol'] ?? ''}',
      isActive: json['status'] == 'active',
    );
  }
}
