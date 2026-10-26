class Payment {
  final String id;
  final String tenantId;
  final String debtId;
  final String recordedById;
  final int amountCents;
  final String paymentMethod;
  final String transactionReference;
  final String receiptNumber;
  final String? notes;
  final DateTime createdAt;

  const Payment({
    required this.id,
    required this.tenantId,
    required this.debtId,
    required this.recordedById,
    required this.amountCents,
    required this.paymentMethod,
    required this.transactionReference,
    required this.receiptNumber,
    this.notes,
    required this.createdAt,
  });

  /// Returns the payment amount in display currency units (e.g. dollars).
  double get amount => amountCents / 100;

  factory Payment.fromJson(Map<String, dynamic> json) {
    return Payment(
      id: json['id'] as String,
      tenantId: json['tenant_id'] as String,
      debtId: json['debt_id'] as String,
      recordedById: json['recorded_by_id'] as String,
      amountCents: json['amount_cents'] as int,
      paymentMethod: json['payment_method'] as String,
      transactionReference: json['transaction_reference'] as String,
      receiptNumber: json['receipt_number'] as String,
      notes: json['notes'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'tenant_id': tenantId,
      'debt_id': debtId,
      'recorded_by_id': recordedById,
      'amount_cents': amountCents,
      'payment_method': paymentMethod,
      'transaction_reference': transactionReference,
      'receipt_number': receiptNumber,
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
    };
  }

  Payment copyWith({
    String? id,
    String? tenantId,
    String? debtId,
    String? recordedById,
    int? amountCents,
    String? paymentMethod,
    String? transactionReference,
    String? receiptNumber,
    String? notes,
    DateTime? createdAt,
  }) {
    return Payment(
      id: id ?? this.id,
      tenantId: tenantId ?? this.tenantId,
      debtId: debtId ?? this.debtId,
      recordedById: recordedById ?? this.recordedById,
      amountCents: amountCents ?? this.amountCents,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      transactionReference: transactionReference ?? this.transactionReference,
      receiptNumber: receiptNumber ?? this.receiptNumber,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}