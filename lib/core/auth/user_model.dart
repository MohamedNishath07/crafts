class User {
  final String id;
  final String email;
  final String? name;
  final bool isActive;

  User({
    required this.id,
    required this.email,
    this.name,
    this.isActive = true,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as String,
      email: json['email'] as String,
      name: json['name'] as String?,
      isActive: json['is_active'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'name': name,
      'is_active': isActive,
    };
  }

  @override
  String toString() => 'User(id: $id, email: $email, name: $name, isActive: $isActive)';
}