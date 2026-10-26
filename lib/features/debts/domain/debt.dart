class Debt {
  final String id;
  final String tenantId;
  final String customerId;
  final String? assignedOfficerId;
  final String referenceNumber;
  final int principalAmountCents;
  final int remainingBalanceCents;
  final DateTime originDate;
  final DateTime dueDate;
  final String status;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Debt({
    required this.id,
    required this.tenantId,
    required this.customerId,
    this.assignedOfficerId,
    required this.referenceNumber,
    required this.principalAmountCents,
    required this.remainingBalanceCents,
    required this.originDate,
    required this.dueDate,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Returns the principal amount in display currency units (e.g. dollars).
  double get principalAmount => principalAmountCents / 100;

  /// Returns the remaining balance in display currency units.
  double get remainingBalance => remainingBalanceCents / 100;

  /// Days past due: positive when due_date is in the past and not settled, else 0.
  int get daysPastDue {
    if (status == 'settled') return 0;
    final today = DateTime.now();
    final due = DateTime(dueDate.year, dueDate.month, dueDate.day);
    final diff = today.difference(due).inDays;
    return diff > 0 ? diff : 0;
  }

  /// Aging bracket label matching the v_debt_aging view.
  String get agingBracket {
    if (status == 'settled') return 'Settled';
    final dpd = daysPastDue;
    if (dpd == 0) return 'Current';
    if (dpd <= 30) return '1-30 DPD';
    if (dpd <= 60) return '31-60 DPD';
    if (dpd <= 90) return '61-90 DPD';
    return '90+ DPD';
  }

  bool get isOverdue => daysPastDue > 0 && status != 'settled';

  factory Debt.fromJson(Map<String, dynamic> json) {
    return Debt(
      id: json['id'] as String,
      tenantId: json['tenant_id'] as String,
      customerId: json['customer_id'] as String,
      assignedOfficerId: json['assigned_officer_id'] as String?,
      referenceNumber: json['reference_number'] as String,
      principalAmountCents: json['principal_amount_cents'] as int,
      remainingBalanceCents: json['remaining_balance_cents'] as int,
      originDate: DateTime.parse(json['origin_date'] as String),
      dueDate: DateTime.parse(json['due_date'] as String),
      status: json['status'] as String,
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
      'customer_id': customerId,
      'assigned_officer_id': assignedOfficerId,
      'reference_number': referenceNumber,
      'principal_amount_cents': principalAmountCents,
      'remaining_balance_cents': remainingBalanceCents,
      'origin_date': originDate.toIso8601String(),
      'due_date': dueDate.toIso8601String(),
      'status': status,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  Debt copyWith({
    String? id,
    String? tenantId,
    String? customerId,
    String? assignedOfficerId,
    String? referenceNumber,
    int? principalAmountCents,
    int? remainingBalanceCents,
    DateTime? originDate,
    DateTime? dueDate,
    String? status,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Debt(
      id: id ?? this.id,
      tenantId: tenantId ?? this.tenantId,
      customerId: customerId ?? this.customerId,
      assignedOfficerId: assignedOfficerId ?? this.assignedOfficerId,
      referenceNumber: referenceNumber ?? this.referenceNumber,
      principalAmountCents: principalAmountCents ?? this.principalAmountCents,
      remainingBalanceCents: remainingBalanceCents ?? this.remainingBalanceCents,
      originDate: originDate ?? this.originDate,
      dueDate: dueDate ?? this.dueDate,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}