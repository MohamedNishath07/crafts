import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:crafts/features/audit/audit_model.dart';
import 'package:crafts/core/auth/current_user_provider.dart';

/// Notifier for audit log state management
class AuditNotifier extends StateNotifier<List<AuditLogEntry>> {
  final Ref _ref;
  AuditNotifier(this._ref) : super(const []);

  /// Log an action to the audit trail
  Future<void> logAction({
    required String actionType,
    required String description,
    Map<String, dynamic>? metadata,
    required bool success,
    String? errorMessage,
  }) async {
    // Generate a unique ID for this audit entry
    final id = DateTime.now().millisecondsSinceEpoch.toString();

    final userId = _ref.read(currentUserProvider)?.id ?? 'anonymous';

    final entry = AuditLogEntry(
      id: id,
      userId: userId,
      actionType: actionType,
      description: description,
      metadata: metadata,
      success: success,
      errorMessage: errorMessage,
    );

    // Add to the beginning of the list (most recent first)
    state = [entry, ...state];

    // TODO: Persist to Supabase or other backend
    // For now, we keep in memory with a maximum of 1000 entries
    if (state.length > 1000) {
      state = state.sublist(0, 1000);
    }
  }

  /// Get audit logs filtered by action type
  List<AuditLogEntry> getByActionType(String actionType) {
    return state.where((entry) => entry.actionType == actionType).toList();
  }

  /// Get audit logs filtered by date range
  List<AuditLogEntry> getByDateRange(DateTime start, DateTime end) {
    return state.where((entry) {
      final timestamp = entry.timestamp;
      return timestamp.isAfter(start) && timestamp.isBefore(end);
    }).toList();
  }

  /// Clear all audit logs (admin only)
  void clearAll() => state = [];
}

/// Provider for audit log state
final auditProvider =
    StateNotifierProvider<AuditNotifier, List<AuditLogEntry>>((ref) {
  return AuditNotifier(ref);
});