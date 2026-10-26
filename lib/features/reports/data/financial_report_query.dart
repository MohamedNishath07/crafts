/// Query parameters for financial reports
class FinancialReportQuery {
  final DateTime? startDate;
  final DateTime? endDate;
  final String? statusFilter; // 'Overdue', 'Settled', 'All'
  final String? officerFilter;

  FinancialReportQuery({
    this.startDate,
    this.endDate,
    this.statusFilter,
    this.officerFilter,
  });

  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{};
    if (startDate != null) {
      map['start_date'] = startDate!.toIso8601String();
    }
    if (endDate != null) {
      map['end_date'] = endDate!.toIso8601String();
    }
    if (statusFilter != null && statusFilter != 'All') {
      map['status'] = statusFilter;
    }
    if (officerFilter != null) {
      map['officer_id'] = officerFilter;
    }
    return map;
  }
}

/// Financial report row data model
class FinancialReportRow {
  final String customerName;
  final String customerId;
  final String debtId;
  final double originalAmount;
  final double collectedAmount;
  final double outstandingAmount;
  final String status;
  final DateTime dueDate;
  final DateTime? paymentDate;
  final String? officerName;

  FinancialReportRow({
    required this.customerName,
    required this.customerId,
    required this.debtId,
    required this.originalAmount,
    required this.collectedAmount,
    required this.outstandingAmount,
    required this.status,
    required this.dueDate,
    this.paymentDate,
    this.officerName,
  });

  Map<String, dynamic> toMap() {
    return {
      'customer_name': customerName,
      'customer_id': customerId,
      'debt_id': debtId,
      'original_amount': originalAmount,
      'collected_amount': collectedAmount,
      'outstanding_amount': outstandingAmount,
      'status': status,
      'due_date': dueDate.toIso8601String(),
      'payment_date': paymentDate?.toIso8601String(),
      'officer_name': officerName,
    };
  }

  factory FinancialReportRow.fromMap(Map<String, dynamic> map) {
    return FinancialReportRow(
      customerName: map['customer_name'] as String,
      customerId: map['customer_id'] as String,
      debtId: map['debt_id'] as String,
      originalAmount: (map['original_amount'] as num).toDouble(),
      collectedAmount: (map['collected_amount'] as num).toDouble(),
      outstandingAmount: (map['outstanding_amount'] as num).toDouble(),
      status: map['status'] as String,
      dueDate: DateTime.parse(map['due_date'] as String),
      paymentDate: map['payment_date'] != null
          ? DateTime.parse(map['payment_date'] as String)
          : null,
      officerName: map['officer_name'] as String?,
    );
  }
}

/// Summary totals for financial reports
class FinancialReportSummary {
  final double totalBilled;
  final double totalCollected;
  final double totalOutstanding;
  final int totalRecords;

  FinancialReportSummary({
    required this.totalBilled,
    required this.totalCollected,
    required this.totalOutstanding,
    required this.totalRecords,
  });

  Map<String, dynamic> toMap() {
    return {
      'total_billed': totalBilled,
      'total_collected': totalCollected,
      'total_outstanding': totalOutstanding,
      'total_records': totalRecords,
    };
  }
}