/// Canonical contact channels for a recovery interaction.
/// These map 1:1 onto the `action_type` enum in PostgreSQL.
class InteractionChannel {
  InteractionChannel._();

  static const String call = 'call';
  static const String fieldVisit = 'field_visit';
  static const String email = 'email';
  static const String sms = 'sms';

  /// Supported by the `action_type` enum but not offered in the log dialog.
  static const String officeVisit = 'office_visit';

  static const List<String> all = <String>[call, fieldVisit, email, sms];

  /// Human readable label for a channel key.
  static String label(String value) {
    switch (value) {
      case call:
        return 'Call';
      case fieldVisit:
        return 'Visit';
      case email:
        return 'Email';
      case sms:
        return 'SMS';
      case officeVisit:
        return 'Office Visit';
      default:
        return value;
    }
  }
}

/// Standard recovery outcomes recorded by collection officers.
class InteractionOutcome {
  InteractionOutcome._();

  static const String noResponse = 'No Response';
  static const String promisedToPay = 'Promised to Pay';
  static const String paymentReceived = 'Payment Received';
  static const String leftMessage = 'Left Message';
  static const String callbackRequested = 'Callback Requested';
  static const String escalated = 'Escalated to Supervisor';
  static const String disputed = 'Disputed Balance';

  static const List<String> all = <String>[
    noResponse,
    promisedToPay,
    paymentReceived,
    leftMessage,
    callbackRequested,
    escalated,
    disputed,
  ];
}

class Interaction {
  final String id;
  final String tenantId;
  final String debtId;
  final String customerId;

  /// The staff member who logged the interaction. Null for entries written by
  /// scheduled jobs or imported from external systems.
  final String? officerId;
  final String actionType;
  final String outcome;

  /// The calendar day the customer was actually contacted.
  final DateTime? contactDate;

  /// The agreed promise-to-pay follow up date (FR-09).
  final DateTime? followUpDate;

  /// The amount the customer promised to pay on [followUpDate].
  final int? promisedAmountCents;

  final String? notes;
  final DateTime createdAt;

  const Interaction({
    required this.id,
    required this.tenantId,
    required this.debtId,
    required this.customerId,
    this.officerId,
    required this.actionType,
    required this.outcome,
    this.contactDate,
    this.followUpDate,
    this.promisedAmountCents,
    this.notes,
    required this.createdAt,
  });

  factory Interaction.fromJson(Map<String, dynamic> json) {
    return Interaction(
      id: json['id'] as String,
      tenantId: json['tenant_id'] as String,
      debtId: json['debt_id'] as String,
      customerId: json['customer_id'] as String,
      officerId: json['officer_id'] as String?,
      actionType: json['action_type'] as String,
      outcome: json['outcome'] as String,
      contactDate: json['contact_date'] != null
          ? DateTime.parse(json['contact_date'] as String)
          : null,
      followUpDate: json['follow_up_date'] != null
          ? DateTime.parse(json['follow_up_date'] as String)
          : null,
      promisedAmountCents: json['promised_amount_cents'] != null
          ? (json['promised_amount_cents'] as num).toInt()
          : null,
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
      'customer_id': customerId,
      'officer_id': officerId,
      'action_type': actionType,
      'outcome': outcome,
      'contact_date': contactDate?.toIso8601String(),
      'follow_up_date': followUpDate?.toIso8601String(),
      'promised_amount_cents': promisedAmountCents,
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
    };
  }

  Interaction copyWith({
    String? id,
    String? tenantId,
    String? debtId,
    String? customerId,
    String? officerId,
    String? actionType,
    String? outcome,
    DateTime? contactDate,
    DateTime? followUpDate,
    int? promisedAmountCents,
    String? notes,
    DateTime? createdAt,
  }) {
    return Interaction(
      id: id ?? this.id,
      tenantId: tenantId ?? this.tenantId,
      debtId: debtId ?? this.debtId,
      customerId: customerId ?? this.customerId,
      officerId: officerId ?? this.officerId,
      actionType: actionType ?? this.actionType,
      outcome: outcome ?? this.outcome,
      contactDate: contactDate ?? this.contactDate,
      followUpDate: followUpDate ?? this.followUpDate,
      promisedAmountCents: promisedAmountCents ?? this.promisedAmountCents,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  /// Display label for the contact channel.
  String get channelLabel => InteractionChannel.label(actionType);

  /// The promised amount in display currency units.
  double get promisedAmount => (promisedAmountCents ?? 0) / 100;

  /// True when the interaction carries an agreed promise-to-pay commitment.
  bool get isFollowUpScheduled => followUpDate != null;

  /// The day the contact happened, falling back to the creation timestamp.
  DateTime get effectiveContactDate => contactDate ?? createdAt;

  /// True when the follow up commitment falls on the supplied day.
  bool isFollowUpDueOn(DateTime day) {
    final followUp = followUpDate;
    if (followUp == null) return false;
    final local = followUp.toLocal();
    return local.year == day.year &&
        local.month == day.month &&
        local.day == day.day;
  }
}

/// Status of a recorded promise-to-pay commitment.
class PromiseStatus {
  PromiseStatus._();

  static const String scheduled = 'Scheduled';
  static const String dueToday = 'Due Today';
  static const String overdue = 'Overdue';
  static const String fulfilled = 'Fulfilled';
  static const String broken = 'Broken';

  static const List<String> all = <String>[
    scheduled,
    dueToday,
    overdue,
    fulfilled,
    broken,
  ];
}

/// A promise-to-pay commitment projected onto the debt it belongs to.
///
/// This is a read model: it joins an [Interaction] carrying the commitment
/// with the debt and customer it refers to so the recovery screen can render
/// follow-up work without additional round trips.
class PromiseToPay {
  final Interaction interaction;
  final String debtReference;
  final String customerName;
  final String? customerPhone;
  final String? customerEmail;
  final int? remainingBalanceCents;
  final String debtStatus;

  const PromiseToPay({
    required this.interaction,
    required this.debtReference,
    required this.customerName,
    this.customerPhone,
    this.customerEmail,
    this.remainingBalanceCents,
    this.debtStatus = 'active',
  });

  factory PromiseToPay.fromJson(Map<String, dynamic> json) {
    return PromiseToPay(
      interaction: Interaction.fromJson(json),
      debtReference: (json['debt_reference'] as String?) ?? '',
      customerName: (json['customer_name'] as String?) ?? 'Unknown Customer',
      customerPhone: json['customer_phone'] as String?,
      customerEmail: json['customer_email'] as String?,
      remainingBalanceCents: json['remaining_balance_cents'] != null
          ? (json['remaining_balance_cents'] as num).toInt()
          : null,
      debtStatus: (json['debt_status'] as String?) ?? 'active',
    );
  }

  /// The agreed follow up date.
  DateTime get followUpDate => interaction.followUpDate!;

  /// The promised amount in display currency units.
  double get promisedAmount => interaction.promisedAmount;

  /// Outstanding balance in display currency units.
  double get remainingBalance => (remainingBalanceCents ?? 0) / 100;

  /// Days remaining until the commitment is due. Negative when overdue.
  int get daysUntilDue {
    final now = DateTime.now();
    final due = DateTime(followUpDate.year, followUpDate.month, followUpDate.day);
    final today = DateTime(now.year, now.month, now.day);
    return due.difference(today).inDays;
  }

  /// Resolves the commitment status relative to today and the debt state.
  String get status {
    if (debtStatus == 'settled') return PromiseStatus.fulfilled;
    final days = daysUntilDue;
    if (days < 0) return PromiseStatus.overdue;
    if (days == 0) return PromiseStatus.dueToday;
    return PromiseStatus.scheduled;
  }

  /// True when the commitment falls on the supplied calendar day.
  bool isDueOn(DateTime day) => interaction.isFollowUpDueOn(day);
}