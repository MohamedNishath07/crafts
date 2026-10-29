import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:crafts/features/audit/audit_log_model.dart';
import 'package:crafts/features/audit/audit_log_notifier.dart';
import 'package:crafts/features/audit/audit_log_repository.dart';

/// Provider for the audit log repository
final auditLogRepositoryProvider = Provider<AuditLogRepository>((ref) => AuditLogRepository());

/// Provider for the current tenant ID
final tenantIdProvider = StateProvider<String>((ref) => 'default_tenant');

/// Riverpod provider for the audit log notifier
final auditLogNotifierProvider =
    StateNotifierProvider<AuditLogNotifier, AuditLogFilterState>((ref) {
  return AuditLogNotifier(ref.read(auditLogRepositoryProvider));
});