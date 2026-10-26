import 'package:flutter_test/flutter_test.dart';
import 'package:crafts/features/auth/domain/user_profile.dart';

void main() {
  group('UserRole', () {
    test('fromString parses known roles correctly', () {
      expect(UserRole.fromString('admin'), UserRole.admin);
      expect(UserRole.fromString('finance_officer'), UserRole.financeOfficer);
      expect(UserRole.fromString('finance'), UserRole.financeOfficer);
      expect(UserRole.fromString('recovery_officer'), UserRole.recoveryOfficer);
      expect(UserRole.fromString('recovery'), UserRole.recoveryOfficer);
    });

    test('fromString defaults unknown roles to recoveryOfficer', () {
      expect(UserRole.fromString('unknown_role'), UserRole.recoveryOfficer);
    });

    test('toDbValue returns expected database representation', () {
      expect(UserRole.admin.toDbValue(), 'admin');
      expect(UserRole.financeOfficer.toDbValue(), 'finance_officer');
      expect(UserRole.recoveryOfficer.toDbValue(), 'recovery_officer');
    });

    test('displayName returns human-readable label', () {
      expect(UserRole.admin.displayName, 'Administrator');
      expect(UserRole.financeOfficer.displayName, 'Finance Officer');
      expect(UserRole.recoveryOfficer.displayName, 'Recovery Officer');
    });
  });

  group('UserProfile', () {
    test('fromJson and toJson round-trip preserves fields', () {
      final json = {
        'id': 'usr-123',
        'tenant_id': 'tenant-456',
        'email': 'officer@crafts.local',
        'full_name': 'Jane Doe',
        'role': 'finance_officer',
        'is_active': true,
      };

      final profile = UserProfile.fromJson(json);

      expect(profile.id, 'usr-123');
      expect(profile.tenantId, 'tenant-456');
      expect(profile.email, 'officer@crafts.local');
      expect(profile.fullName, 'Jane Doe');
      expect(profile.role, UserRole.financeOfficer);
      expect(profile.isActive, isTrue);

      final serialized = profile.toJson();
      expect(serialized, json);
    });
  });
}
