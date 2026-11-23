class User {
  final String id;
  final String email;
  final String? name;
  final String? tenantId;
  final bool isActive;

  User({
    required this.id,
    required this.email,
    this.name,
    this.tenantId,
    this.isActive = true,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as String,
      email: json['email'] as String,
      name: json['name'] as String?,
      tenantId: json['tenant_id'] as String?,
      isActive: json['is_active'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'name': name,
      'tenant_id': tenantId,
      'is_active': isActive,
    };
  }

  @override
  String toString() => 'User(id: $id, email: $email, name: $name, isActive: $isActive)';
}
