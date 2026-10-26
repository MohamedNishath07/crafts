class Customer {
  final String id;
  final String tenantId;
  final String fullName;
  final String phoneNumber;
  final String? secondaryPhone;
  final String? email;
  final String? nationalId;
  final String? address;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Customer({
    required this.id,
    required this.tenantId,
    required this.fullName,
    required this.phoneNumber,
    this.secondaryPhone,
    this.email,
    this.nationalId,
    this.address,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Customer.fromJson(Map<String, dynamic> json) {
    return Customer(
      id: json['id'] as String,
      tenantId: json['tenant_id'] as String,
      fullName: json['full_name'] as String,
      phoneNumber: json['phone_number'] as String,
      secondaryPhone: json['secondary_phone'] as String?,
      email: json['email'] as String?,
      nationalId: json['national_id'] as String?,
      address: json['address'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'tenant_id': tenantId,
      'full_name': fullName,
      'phone_number': phoneNumber,
      'secondary_phone': secondaryPhone,
      'email': email,
      'national_id': nationalId,
      'address': address,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  Customer copyWith({
    String? id,
    String? tenantId,
    String? fullName,
    String? phoneNumber,
    String? secondaryPhone,
    String? email,
    String? nationalId,
    String? address,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Customer(
      id: id ?? this.id,
      tenantId: tenantId ?? this.tenantId,
      fullName: fullName ?? this.fullName,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      secondaryPhone: secondaryPhone ?? this.secondaryPhone,
      email: email ?? this.email,
      nationalId: nationalId ?? this.nationalId,
      address: address ?? this.address,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
