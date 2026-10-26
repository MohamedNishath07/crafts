/// Configuration for tenant-level payment reminder preferences.
class ReminderSettings {
  final String id;
  final String tenantId;
  final bool emailEnabled;
  final bool smsEnabled;
  final List<int> emailOffsetDays;
  final List<int> smsOffsetDays;
  final String messageTemplate;
  final DateTime createdAt;
  final DateTime updatedAt;

  const ReminderSettings({
    required this.id,
    required this.tenantId,
    required this.emailEnabled,
    required this.smsEnabled,
    required this.emailOffsetDays,
    required this.smsOffsetDays,
    required this.messageTemplate,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ReminderSettings.fromJson(Map<String, dynamic> json) {
    return ReminderSettings(
      id: json['id'] as String,
      tenantId: json['tenant_id'] as String,
      emailEnabled: json['email_enabled'] as bool? ?? true,
      smsEnabled: json['sms_enabled'] as bool? ?? false,
      emailOffsetDays: (json['email_offset_days'] as List<dynamic>?)
          ?.map((e) => (e as num).toInt())
          .toList() ??
          const [3, 1, 0],
      smsOffsetDays: (json['sms_offset_days'] as List<dynamic>?)
          ?.map((e) => (e as num).toInt())
          .toList() ??
          const [3, 0],
      messageTemplate: json['message_template'] as String? ??
          'Dear {{customer_name}}, a payment of {{amount}} on account {{reference_number}} is due on {{due_date}}. Please make your payment to avoid further collection action.',
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
      'email_enabled': emailEnabled,
      'sms_enabled': smsEnabled,
      'email_offset_days': emailOffsetDays,
      'sms_offset_days': smsOffsetDays,
      'message_template': messageTemplate,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  ReminderSettings copyWith({
    String? id,
    String? tenantId,
    bool? emailEnabled,
    bool? smsEnabled,
    List<int>? emailOffsetDays,
    List<int>? smsOffsetDays,
    String? messageTemplate,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ReminderSettings(
      id: id ?? this.id,
      tenantId: tenantId ?? this.tenantId,
      emailEnabled: emailEnabled ?? this.emailEnabled,
      smsEnabled: smsEnabled ?? this.smsEnabled,
      emailOffsetDays: emailOffsetDays ?? this.emailOffsetDays,
      smsOffsetDays: smsOffsetDays ?? this.smsOffsetDays,
      messageTemplate: messageTemplate ?? this.messageTemplate,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

/// A record of a reminder that was (or will be) dispatched to a customer.
class ReminderDispatch {
  final String id;
  final String tenantId;
  final String debtId;
  final String customerId;
  final String channel; // 'email' or 'sms'
  final String recipient;
  final String message;
  final String status; // 'pending', 'sent', 'failed'
  final DateTime? scheduledFor;
  final DateTime? sentAt;
  final DateTime createdAt;

  const ReminderDispatch({
    required this.id,
    required this.tenantId,
    required this.debtId,
    required this.customerId,
    required this.channel,
    required this.recipient,
    required this.message,
    required this.status,
    this.scheduledFor,
    this.sentAt,
    required this.createdAt,
  });

  factory ReminderDispatch.fromJson(Map<String, dynamic> json) {
    return ReminderDispatch(
      id: json['id'] as String,
      tenantId: json['tenant_id'] as String,
      debtId: json['debt_id'] as String,
      customerId: json['customer_id'] as String,
      channel: json['channel'] as String,
      recipient: json['recipient'] as String,
      message: json['message'] as String,
      status: json['status'] as String? ?? 'pending',
      scheduledFor: json['scheduled_for'] != null
          ? DateTime.parse(json['scheduled_for'] as String)
          : null,
      sentAt: json['sent_at'] != null
          ? DateTime.parse(json['sent_at'] as String)
          : null,
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
      'channel': channel,
      'recipient': recipient,
      'message': message,
      'status': status,
      'scheduled_for': scheduledFor?.toIso8601String(),
      'sent_at': sentAt?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
    };
  }

  bool get isEmail => channel == 'email';
  bool get isSms => channel == 'sms';
}
