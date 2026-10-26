enum UserRole {
  admin,
  recoveryOfficer,
  financeOfficer;

  String get displayName {
    switch (this) {
      case UserRole.admin:
        return 'Administrator';
      case UserRole.recoveryOfficer:
        return 'Recovery Officer';
      case UserRole.financeOfficer:
        return 'Finance Officer';
    }
  }

  static UserRole fromString(String role) {
    switch (role.toLowerCase()) {
      case 'admin':
        return UserRole.admin;
      case 'finance_officer':
      case 'finance':
        return UserRole.financeOfficer;
      case 'recovery_officer':
      case 'recovery':
      default:
        return UserRole.recoveryOfficer;
    }
  }

  String toDbValue() {
    switch (this) {
      case UserRole.admin:
        return 'admin';
      case UserRole.recoveryOfficer:
        return 'recovery_officer';
      case UserRole.financeOfficer:
        return 'finance_officer';
    }
  }
}

class UserProfile {
  final String id;
  final String tenantId;
  final String email;
  final String fullName;
  final UserRole role;
  final bool isActive;

  const UserProfile({
    required this.id,
    required this.tenantId,
    required this.email,
    required this.fullName,
    required this.role,
    this.isActive = true,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'] as String,
      tenantId: json['tenant_id'] as String,
      email: json['email'] as String,
      fullName: json['full_name'] as String? ?? 'Staff Member',
      role: UserRole.fromString(json['role'] as String? ?? 'recovery_officer'),
      isActive: json['is_active'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'tenant_id': tenantId,
      'email': email,
      'full_name': fullName,
      'role': role.toDbValue(),
      'is_active': isActive,
    };
  }
}
