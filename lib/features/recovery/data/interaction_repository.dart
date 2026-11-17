import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../domain/interaction.dart';

import '../../../core/sqlitedatabase.dart';

final interactionRepositoryProvider = Provider<InteractionRepository>((ref) {
  try {
    return InteractionRepository(SQLiteDatabase());
  } catch (_) {
    return InteractionRepository(null);
  }
});

class InteractionRepository {
  final SQLiteDatabase? _db;
  static const _uuid = Uuid();

  InteractionRepository(this._db);

  /// Fetch all interactions for the tenant, newest first
  Future<List<Interaction>> fetchInteractions(String tenantId) async {
    if (_db == null) {
      throw Exception('SQLite database not initialized');
    }

    final response = await _db.fetchInteractions(tenantId);
    return response.map((row) => Interaction.fromJson(row)).toList();
  }

  /// Fetch interactions filtered by follow-up date
  Future<List<Interaction>> fetchFollowUpInteractions(
      String tenantId, DateTime followUpDate) async {
    if (_db == null) {
      throw Exception('SQLite database not initialized');
    }

    final start = DateTime(followUpDate.year, followUpDate.month, followUpDate.day).toIso8601String();
    final end = DateTime(followUpDate.year, followUpDate.month, followUpDate.day + 1).toIso8601String();

    final response = await _db.fetchInteractions(tenantId);
    return response
        .where((row) {
          final followUp = row['follow_up_date'] as String?;
          if (followUp == null) return false;
          return followUp.compareTo(start) >= 0 && followUp.compareTo(end) <= 0;
        })
        .map((row) => Interaction.fromJson(row))
        .toList();
  }

  /// Save a new recovery interaction
  Future<Interaction> saveInteraction({
    required String debtId,
    required String debtCustomerId,
    required String officerId,
    required String actionType,
    required String outcome,
    DateTime? followUpDate,
    int? promisedAmountCents,
    String? notes,
  }) async {
    if (_db == null) {
      throw Exception('SQLite database not initialized');
    }

    final newId = _uuid.v4();
    final now = DateTime.now().toIso8601String();

    final response = await _db.insertInteractionLog({
      'id': newId,
      'tenant_id': debtId,
      'debt_id': debtId,
      'customer_id': debtCustomerId,
      'officer_id': officerId,
      'action_type': actionType,
      'outcome': outcome,
      'follow_up_date': followUpDate?.toIso8601String(),
      'promised_amount_cents': promisedAmountCents,
      'notes': notes?.trim(),
      'created_at': now,
    });

    return Interaction.fromJson(response);
  }
}
