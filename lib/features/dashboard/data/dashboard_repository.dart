import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../core/sqlitedatabase.dart';
import '../../auth/domain/user_profile.dart';
import '../domain/dashboard_models.dart';

final dashboardRepositoryProvider = Provider<DashboardRepository>((ref) {
  return DashboardRepository(SQLiteDatabase());
});

class DashboardRepository {
  final SQLiteDatabase _sqlite;
  static const _uuid = Uuid();

  DashboardRepository(this._sqlite);

  Future<dynamic> _getDb() async {
    try {
      return await _sqlite.database.timeout(const Duration(milliseconds: 1200));
    } catch (_) {
      return null;
    }
  }

  /// Fetch overall and role-tailored financial statistics from SQLite
  Future<DashboardOverviewMetrics> fetchOverviewMetrics(
    String tenantId, {
    UserRole? role,
    String? officerId,
  }) async {
    final db = await _getDb();
    if (db == null) {
      return DashboardOverviewMetrics.zero();
    }

    // 1. Total Customers
    final customerCountResult = await db.rawQuery(
      'SELECT COUNT(*) as count FROM customers WHERE tenant_id = ?',
      [tenantId],
    );
    final totalCustomers = (customerCountResult.first['count'] as num?)?.toInt() ?? 0;

    // 2. Debts Statistics (Credit, Outstanding, Overdue)
    final debtStatsResult = await db.rawQuery(
      '''
      SELECT 
        COUNT(*) as total_count,
        COALESCE(SUM(principal_amount_cents), 0) as total_credit_cents,
        COALESCE(SUM(remaining_balance_cents), 0) as total_remaining_cents
      FROM debts
      WHERE tenant_id = ?
      ''',
      [tenantId],
    );
    final totalDebtRow = debtStatsResult.first;
    final totalCreditCents = (totalDebtRow['total_credit_cents'] as num?)?.toDouble() ?? 0.0;
    final totalCreditAmount = totalCreditCents / 100.0;

    // Outstanding Balance (only active/unsettled debts)
    final outstandingResult = await db.rawQuery(
      '''
      SELECT COALESCE(SUM(remaining_balance_cents), 0) as outstanding_cents
      FROM debts
      WHERE tenant_id = ? AND status != 'settled'
      ''',
      [tenantId],
    );
    final outstandingCents = (outstandingResult.first['outstanding_cents'] as num?)?.toDouble() ?? 0.0;
    final outstandingBalance = outstandingCents / 100.0;

    // Status counts
    final statusCountsResult = await db.rawQuery(
      '''
      SELECT status, COUNT(*) as count 
      FROM debts 
      WHERE tenant_id = ? 
      GROUP BY status
      ''',
      [tenantId],
    );
    int activeBillsCount = 0;
    int settledBillsCount = 0;
    for (final row in statusCountsResult) {
      final status = row['status'] as String?;
      final count = (row['count'] as num?)?.toInt() ?? 0;
      if (status == 'active') activeBillsCount = count;
      if (status == 'settled') settledBillsCount = count;
    }

    // Overdue Calculations based on due_date < today
    final now = DateTime.now();
    final todayIso = DateTime(now.year, now.month, now.day).toIso8601String();
    final overdueResult = await db.rawQuery(
      '''
      SELECT 
        COUNT(*) as overdue_count,
        COALESCE(SUM(remaining_balance_cents), 0) as overdue_cents
      FROM debts
      WHERE tenant_id = ? AND status != 'settled' AND due_date < ?
      ''',
      [tenantId, todayIso],
    );
    final overdueRow = overdueResult.first;
    final overdueCount = (overdueRow['overdue_count'] as num?)?.toInt() ?? 0;
    final overdueCents = (overdueRow['overdue_cents'] as num?)?.toDouble() ?? 0.0;
    final overdueBalance = overdueCents / 100.0;

    // 3. Payment Statistics (Collected, Today's Collections, Month-to-date)
    final paymentStatsResult = await db.rawQuery(
      '''
      SELECT 
        COUNT(*) as total_payments,
        COALESCE(SUM(amount_cents), 0) as total_collected_cents
      FROM payments
      WHERE tenant_id = ?
      ''',
      [tenantId],
    );
    final paymentRow = paymentStatsResult.first;
    final totalPaymentsCount = (paymentRow['total_payments'] as num?)?.toInt() ?? 0;
    final totalCollectedCents = (paymentRow['total_collected_cents'] as num?)?.toDouble() ?? 0.0;
    final totalCollectedAmount = totalCollectedCents / 100.0;

    // Today's collections
    final todayStart = DateTime(now.year, now.month, now.day).toIso8601String();
    final todayEnd = DateTime(now.year, now.month, now.day, 23, 59, 59).toIso8601String();
    final todayPaymentsResult = await db.rawQuery(
      '''
      SELECT COALESCE(SUM(amount_cents), 0) as today_cents
      FROM payments
      WHERE tenant_id = ? AND created_at >= ? AND created_at <= ?
      ''',
      [tenantId, todayStart, todayEnd],
    );
    final todayCents = (todayPaymentsResult.first['today_cents'] as num?)?.toDouble() ?? 0.0;
    final todayCollections = todayCents / 100.0;

    // Month-to-date collections
    final monthStart = DateTime(now.year, now.month, 1).toIso8601String();
    final monthPaymentsResult = await db.rawQuery(
      '''
      SELECT COALESCE(SUM(amount_cents), 0) as month_cents
      FROM payments
      WHERE tenant_id = ? AND created_at >= ?
      ''',
      [tenantId, monthStart],
    );
    final monthCents = (monthPaymentsResult.first['month_cents'] as num?)?.toDouble() ?? 0.0;
    final monthToDateCollections = monthCents / 100.0;

    // Recovery Rate %
    final recoveryRate = totalCreditAmount > 0
        ? ((totalCollectedAmount / totalCreditAmount) * 100.0).clamp(0.0, 100.0)
        : 0.0;

    // 4. Recovery Officer specific queries
    int assignedCustomersCount = totalCustomers;
    double assignedOutstandingBalance = outstandingBalance;
    if (officerId != null && officerId.isNotEmpty) {
      final assignedCustResult = await db.rawQuery(
        '''
        SELECT COUNT(DISTINCT customer_id) as count
        FROM debts
        WHERE tenant_id = ? AND (assigned_officer_id = ? OR assigned_officer_id IS NULL)
        ''',
        [tenantId, officerId],
      );
      assignedCustomersCount = (assignedCustResult.first['count'] as num?)?.toInt() ?? 0;

      final assignedDebtResult = await db.rawQuery(
        '''
        SELECT COALESCE(SUM(remaining_balance_cents), 0) as cents
        FROM debts
        WHERE tenant_id = ? AND status != 'settled' AND (assigned_officer_id = ? OR assigned_officer_id IS NULL)
        ''',
        [tenantId, officerId],
      );
      final assignedCents = (assignedDebtResult.first['cents'] as num?)?.toDouble() ?? 0.0;
      assignedOutstandingBalance = assignedCents / 100.0;
    }

    // Today's Follow-ups and Promised commitments
    final followUpsResult = await db.rawQuery(
      '''
      SELECT 
        COUNT(*) as count,
        COALESCE(SUM(promised_amount_cents), 0) as promised_cents
      FROM interaction_logs
      WHERE tenant_id = ? AND follow_up_date >= ? AND follow_up_date <= ?
      ''',
      [tenantId, todayStart, todayEnd],
    );
    final followUpRow = followUpsResult.first;
    final todayFollowUpsCount = (followUpRow['count'] as num?)?.toInt() ?? 0;
    final promisedCents = (followUpRow['promised_cents'] as num?)?.toDouble() ?? 0.0;
    final todayPromisedAmount = promisedCents / 100.0;

    // Today's Interactions logged
    final todayInteractionsResult = await db.rawQuery(
      '''
      SELECT COUNT(*) as count
      FROM interaction_logs
      WHERE tenant_id = ? AND created_at >= ? AND created_at <= ?
      ''',
      [tenantId, todayStart, todayEnd],
    );
    final todayInteractionsCount = (todayInteractionsResult.first['count'] as num?)?.toInt() ?? 0;

    // 5. Admin specifics (Profiles and Audit Logs)
    int staffCount = 0;
    try {
      final staffResult = await db.rawQuery(
        'SELECT COUNT(*) as count FROM profiles WHERE tenant_id = ?',
        [tenantId],
      );
      staffCount = (staffResult.first['count'] as num?)?.toInt() ?? 0;
    } catch (_) {}

    int auditLogCount = 0;
    try {
      final auditResult = await db.rawQuery(
        'SELECT COUNT(*) as count FROM audit_logs WHERE tenant_id = ?',
        [tenantId],
      );
      auditLogCount = (auditResult.first['count'] as num?)?.toInt() ?? 0;
    } catch (_) {}

    return DashboardOverviewMetrics(
      totalCustomers: totalCustomers,
      totalCreditAmount: totalCreditAmount,
      totalCollectedAmount: totalCollectedAmount,
      outstandingBalance: outstandingBalance,
      todayCollections: todayCollections,
      overdueBalance: overdueBalance,
      overdueCount: overdueCount,
      recoveryRate: recoveryRate,
      assignedCustomersCount: assignedCustomersCount,
      assignedOutstandingBalance: assignedOutstandingBalance,
      todayFollowUpsCount: todayFollowUpsCount,
      todayPromisedAmount: todayPromisedAmount,
      todayInteractionsCount: todayInteractionsCount,
      totalPaymentsCount: totalPaymentsCount,
      monthToDateCollections: monthToDateCollections,
      activeBillsCount: activeBillsCount,
      settledBillsCount: settledBillsCount,
      staffCount: staffCount,
      auditLogCount: auditLogCount,
    );
  }

  /// Fetch financial analytics data for interactive charts based on selected filter
  Future<ChartAnalyticsData> fetchChartAnalytics(
    String tenantId,
    DashboardDateFilter filter,
  ) async {
    final db = await _getDb();
    if (db == null) {
      return ChartAnalyticsData.empty(filter);
    }
    final now = DateTime.now();

    List<TimeSeriesDataPoint> points = [];
    double totalBilled = 0.0;
    double totalCollected = 0.0;

    if (filter == DashboardDateFilter.thisWeek) {
      // Current week: Monday to Sunday
      final weekday = now.weekday; // 1 = Monday, 7 = Sunday
      final monday = DateTime(now.year, now.month, now.day).subtract(Duration(days: weekday - 1));
      
      final weekDays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
      for (int i = 0; i < 7; i++) {
        final dayDate = monday.add(Duration(days: i));
        final dayStart = DateTime(dayDate.year, dayDate.month, dayDate.day).toIso8601String();
        final dayEnd = DateTime(dayDate.year, dayDate.month, dayDate.day, 23, 59, 59).toIso8601String();

        // Query payment collections on this day
        final pResult = await db.rawQuery(
          '''
          SELECT COALESCE(SUM(amount_cents), 0) as cents
          FROM payments
          WHERE tenant_id = ? AND created_at >= ? AND created_at <= ?
          ''',
          [tenantId, dayStart, dayEnd],
        );
        final collected = ((pResult.first['cents'] as num?)?.toDouble() ?? 0.0) / 100.0;

        // Query debt credit billed on this day
        final dResult = await db.rawQuery(
          '''
          SELECT COALESCE(SUM(principal_amount_cents), 0) as cents
          FROM debts
          WHERE tenant_id = ? AND created_at >= ? AND created_at <= ?
          ''',
          [tenantId, dayStart, dayEnd],
        );
        final billed = ((dResult.first['cents'] as num?)?.toDouble() ?? 0.0) / 100.0;

        totalCollected += collected;
        totalBilled += billed;
        points.add(TimeSeriesDataPoint(
          label: weekDays[i],
          collectionAmount: collected,
          creditAmount: billed,
        ));
      }
    } else if (filter == DashboardDateFilter.thisMonth) {
      // 4 or 5 week buckets for current month
      final daysInMonth = DateTime(now.year, now.month + 1, 0).day;
      const intervalDays = 7;
      final totalBuckets = (daysInMonth / intervalDays).ceil();

      for (int b = 0; b < totalBuckets; b++) {
        final startDay = b * intervalDays + 1;
        final endDay = min((b + 1) * intervalDays, daysInMonth);
        final bucketStart = DateTime(now.year, now.month, startDay).toIso8601String();
        final bucketEnd = DateTime(now.year, now.month, endDay, 23, 59, 59).toIso8601String();

        final pResult = await db.rawQuery(
          '''
          SELECT COALESCE(SUM(amount_cents), 0) as cents
          FROM payments
          WHERE tenant_id = ? AND created_at >= ? AND created_at <= ?
          ''',
          [tenantId, bucketStart, bucketEnd],
        );
        final collected = ((pResult.first['cents'] as num?)?.toDouble() ?? 0.0) / 100.0;

        final dResult = await db.rawQuery(
          '''
          SELECT COALESCE(SUM(principal_amount_cents), 0) as cents
          FROM debts
          WHERE tenant_id = ? AND created_at >= ? AND created_at <= ?
          ''',
          [tenantId, bucketStart, bucketEnd],
        );
        final billed = ((dResult.first['cents'] as num?)?.toDouble() ?? 0.0) / 100.0;

        totalCollected += collected;
        totalBilled += billed;
        points.add(TimeSeriesDataPoint(
          label: 'W${b + 1} ($startDay-$endDay)',
          collectionAmount: collected,
          creditAmount: billed,
        ));
      }
    } else {
      // This Year: 12 months (Jan - Dec)
      final monthNames = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      for (int m = 1; m <= 12; m++) {
        final daysInM = DateTime(now.year, m + 1, 0).day;
        final mStart = DateTime(now.year, m, 1).toIso8601String();
        final mEnd = DateTime(now.year, m, daysInM, 23, 59, 59).toIso8601String();

        final pResult = await db.rawQuery(
          '''
          SELECT COALESCE(SUM(amount_cents), 0) as cents
          FROM payments
          WHERE tenant_id = ? AND created_at >= ? AND created_at <= ?
          ''',
          [tenantId, mStart, mEnd],
        );
        final collected = ((pResult.first['cents'] as num?)?.toDouble() ?? 0.0) / 100.0;

        final dResult = await db.rawQuery(
          '''
          SELECT COALESCE(SUM(principal_amount_cents), 0) as cents
          FROM debts
          WHERE tenant_id = ? AND created_at >= ? AND created_at <= ?
          ''',
          [tenantId, mStart, mEnd],
        );
        final billed = ((dResult.first['cents'] as num?)?.toDouble() ?? 0.0) / 100.0;

        totalCollected += collected;
        totalBilled += billed;
        points.add(TimeSeriesDataPoint(
          label: monthNames[m - 1],
          collectionAmount: collected,
          creditAmount: billed,
        ));
      }
    }

    // Status Breakdown (Current vs Overdue vs Settled)
    final allDebts = await db.rawQuery(
      '''
      SELECT status, remaining_balance_cents, principal_amount_cents, due_date
      FROM debts
      WHERE tenant_id = ?
      ''',
      [tenantId],
    );

    double currentSum = 0.0;
    double overdueSum = 0.0;
    double settledSum = 0.0;
    final todayMidnight = DateTime(now.year, now.month, now.day);

    // Aging breakdown
    double agingCurrent = 0.0;
    double aging1to30 = 0.0;
    double aging31to60 = 0.0;
    double aging61to90 = 0.0;
    double aging90Plus = 0.0;

    for (final row in allDebts) {
      final status = row['status'] as String? ?? 'active';
      final remCents = (row['remaining_balance_cents'] as num?)?.toDouble() ?? 0.0;
      final princCents = (row['principal_amount_cents'] as num?)?.toDouble() ?? 0.0;
      final dueStr = row['due_date'] as String?;
      final dueDate = dueStr != null ? DateTime.tryParse(dueStr) ?? now : now;
      final balance = remCents / 100.0;

      if (status == 'settled' || balance == 0) {
        settledSum += princCents / 100.0;
      } else {
        final isOverdue = dueDate.isBefore(todayMidnight);
        if (isOverdue) {
          overdueSum += balance;
          final dpd = todayMidnight.difference(DateTime(dueDate.year, dueDate.month, dueDate.day)).inDays;
          if (dpd <= 30) {
            aging1to30 += balance;
          } else if (dpd <= 60) {
            aging31to60 += balance;
          } else if (dpd <= 90) {
            aging61to90 += balance;
          } else {
            aging90Plus += balance;
          }
        } else {
          currentSum += balance;
          agingCurrent += balance;
        }
      }
    }

    // Determine max value for chart scaling
    double maxVal = 100.0;
    for (final p in points) {
      if (p.collectionAmount > maxVal) maxVal = p.collectionAmount;
      if (p.creditAmount > maxVal) maxVal = p.creditAmount;
    }
    maxVal = (maxVal * 1.2).ceilToDouble();

    return ChartAnalyticsData(
      filter: filter,
      points: points,
      statusBreakdown: {
        'Current': currentSum,
        'Overdue': overdueSum,
        'Settled': settledSum,
      },
      agingBreakdown: {
        'Current': agingCurrent,
        '1-30 DPD': aging1to30,
        '31-60 DPD': aging31to60,
        '61-90 DPD': aging61to90,
        '90+ DPD': aging90Plus,
      },
      totalBilledInPeriod: totalBilled,
      totalCollectedInPeriod: totalCollected,
      maxChartValue: maxVal,
    );
  }

  /// Fetch combined recent activities chronologically from SQLite
  Future<List<RecentActivity>> fetchRecentActivities(
    String tenantId, {
    int limit = 15,
    String filterType = 'all',
  }) async {
    final db = await _getDb();
    if (db == null) return [];
    final List<RecentActivity> activities = [];

    // 1. Recent Payments
    if (filterType == 'all' || filterType == 'payment') {
      final paymentsRaw = await db.rawQuery(
        '''
        SELECT 
          p.id, 
          p.amount_cents, 
          p.payment_method, 
          p.receipt_number, 
          p.created_at,
          c.full_name AS customer_name,
          d.reference_number AS debt_ref
        FROM payments p
        LEFT JOIN debts d ON p.debt_id = d.id
        LEFT JOIN customers c ON d.customer_id = c.id
        WHERE p.tenant_id = ?
        ORDER BY p.created_at DESC
        LIMIT ?
        ''',
        [tenantId, limit],
      );

      for (final row in paymentsRaw) {
        final amount = ((row['amount_cents'] as num?)?.toDouble() ?? 0.0) / 100.0;
        final custName = row['customer_name'] as String? ?? 'Valued Customer';
        final method = (row['payment_method'] as String? ?? 'Cash').toUpperCase();
        final ref = row['receipt_number'] as String? ?? row['debt_ref'] as String? ?? '';
        final dateStr = row['created_at'] as String?;
        final date = dateStr != null ? DateTime.tryParse(dateStr) ?? DateTime.now() : DateTime.now();

        activities.add(RecentActivity(
          id: row['id'] as String,
          type: ActivityType.payment,
          title: 'Payment Received ($method)',
          subtitle: 'From $custName • Ref: $ref',
          timestamp: date,
          amount: amount,
          status: 'Recorded',
          reference: ref,
          customerName: custName,
        ));
      }
    }

    // 2. Recent Credit Transactions (Debts)
    if (filterType == 'all' || filterType == 'credit') {
      final debtsRaw = await db.rawQuery(
        '''
        SELECT 
          d.id, 
          d.reference_number, 
          d.principal_amount_cents, 
          d.remaining_balance_cents, 
          d.status, 
          d.due_date, 
          d.created_at,
          c.full_name AS customer_name
        FROM debts d
        LEFT JOIN customers c ON d.customer_id = c.id
        WHERE d.tenant_id = ?
        ORDER BY d.created_at DESC
        LIMIT ?
        ''',
        [tenantId, limit],
      );

      for (final row in debtsRaw) {
        final amount = ((row['principal_amount_cents'] as num?)?.toDouble() ?? 0.0) / 100.0;
        final custName = row['customer_name'] as String? ?? 'Customer';
        final ref = row['reference_number'] as String? ?? '';
        final status = row['status'] as String? ?? 'active';
        final dateStr = row['created_at'] as String?;
        final date = dateStr != null ? DateTime.tryParse(dateStr) ?? DateTime.now() : DateTime.now();

        activities.add(RecentActivity(
          id: row['id'] as String,
          type: ActivityType.credit,
          title: 'Credit Bill Issued',
          subtitle: '$custName • Ref: $ref',
          timestamp: date,
          amount: amount,
          status: status.toUpperCase(),
          reference: ref,
          customerName: custName,
        ));
      }
    }

    // 3. Recent Customers
    if (filterType == 'all' || filterType == 'customer') {
      final customersRaw = await db.rawQuery(
        '''
        SELECT id, full_name, phone_number, created_at
        FROM customers
        WHERE tenant_id = ?
        ORDER BY created_at DESC
        LIMIT ?
        ''',
        [tenantId, limit],
      );

      for (final row in customersRaw) {
        final name = row['full_name'] as String? ?? 'New Customer';
        final phone = row['phone_number'] as String? ?? '';
        final dateStr = row['created_at'] as String?;
        final date = dateStr != null ? DateTime.tryParse(dateStr) ?? DateTime.now() : DateTime.now();

        activities.add(RecentActivity(
          id: row['id'] as String,
          type: ActivityType.customer,
          title: 'Customer Registered',
          subtitle: '$name • $phone',
          timestamp: date,
          status: 'Active',
          customerName: name,
        ));
      }
    }

    // 4. Recent Recovery Activities (Interaction Logs)
    if (filterType == 'all' || filterType == 'recovery') {
      final recoveryRaw = await db.rawQuery(
        '''
        SELECT 
          i.id, 
          i.action_type, 
          i.outcome, 
          i.promised_amount_cents, 
          i.follow_up_date, 
          i.created_at,
          c.full_name AS customer_name
        FROM interaction_logs i
        LEFT JOIN customers c ON i.customer_id = c.id
        WHERE i.tenant_id = ?
        ORDER BY i.created_at DESC
        LIMIT ?
        ''',
        [tenantId, limit],
      );

      for (final row in recoveryRaw) {
        final channel = (row['action_type'] as String? ?? 'Contact').toUpperCase();
        final outcome = row['outcome'] as String? ?? 'Follow-up logged';
        final custName = row['customer_name'] as String? ?? 'Customer';
        final promisedCents = (row['promised_amount_cents'] as num?)?.toDouble();
        final promised = promisedCents != null ? promisedCents / 100.0 : null;
        final dateStr = row['created_at'] as String?;
        final date = dateStr != null ? DateTime.tryParse(dateStr) ?? DateTime.now() : DateTime.now();

        activities.add(RecentActivity(
          id: row['id'] as String,
          type: ActivityType.recovery,
          title: 'Recovery: $channel',
          subtitle: '$custName • $outcome',
          timestamp: date,
          amount: promised,
          status: outcome,
          customerName: custName,
        ));
      }
    }

    // Sort all activities newest first
    activities.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    if (activities.length > limit) {
      return activities.sublist(0, limit);
    }
    return activities;
  }

  /// Check if the database has any operational records for the tenant
  Future<bool> isDatabaseEmpty(String tenantId) async {
    final db = await _getDb();
    if (db == null) return true;
    final res = await db.rawQuery(
      'SELECT COUNT(*) as count FROM customers WHERE tenant_id = ?',
      [tenantId],
    );
    final count = (res.first['count'] as num?)?.toInt() ?? 0;
    return count == 0;
  }

  /// Seed realistic fintech sample data for testing and immediate dashboard presentation
  Future<void> seedDemoDataIfEmpty(String tenantId, {String? officerId}) async {
    final isEmpty = await isDatabaseEmpty(tenantId);
    if (!isEmpty) return;
    await seedDemoData(tenantId, officerId: officerId);
  }

  /// Forces seeding of rich sample records into SQLite
  Future<void> seedDemoData(String tenantId, {String? officerId}) async {
    final db = await _sqlite.database;
    final now = DateTime.now();

    // 1. Create sample customers
    final customerData = [
      {'name': 'Apex Global Trading', 'phone': '+1 (555) 234-5678', 'email': 'billing@apexglobal.com'},
      {'name': 'Starlight Retailers Ltd', 'phone': '+1 (555) 876-5432', 'email': 'accounts@starlight.co'},
      {'name': 'Nova Logistics Corp', 'phone': '+1 (555) 345-6789', 'email': 'finance@novalogistics.io'},
      {'name': 'Horizon Health Supplies', 'phone': '+1 (555) 901-2345', 'email': 'pay@horizonhealth.org'},
      {'name': 'Vanguard Engineering', 'phone': '+1 (555) 678-9012', 'email': 'contact@vanguard.tech'},
    ];

    final List<String> customerIds = [];
    for (final c in customerData) {
      final cId = _uuid.v4();
      customerIds.add(cId);
      final createdDate = now.subtract(Duration(days: 30 + Random().nextInt(40)));
      await db.insert('customers', {
        'id': cId,
        'tenant_id': tenantId,
        'full_name': c['name']!,
        'phone_number': c['phone']!,
        'email': c['email']!,
        'address': 'Commercial Plaza, Suite 100',
        'created_at': createdDate.toIso8601String(),
        'updated_at': createdDate.toIso8601String(),
      });
    }

    // 2. Create sample debts (credit bills)
    // Variety: Active current, Overdue, Settled
    final debtPlans = [
      {
        'custIdx': 0,
        'ref': 'INV-2026-001',
        'principal': 500000, // $5,000.00
        'remaining': 200000, // $2,000.00
        'status': 'active',
        'daysAgo': 20,
        'dueInDays': 10, // Current
      },
      {
        'custIdx': 1,
        'ref': 'INV-2026-002',
        'principal': 350000, // $3,500.00
        'remaining': 350000, // $3,500.00
        'status': 'active',
        'daysAgo': 45,
        'dueInDays': -15, // Overdue 15 days
      },
      {
        'custIdx': 2,
        'ref': 'INV-2026-003',
        'principal': 820000, // $8,200.00
        'remaining': 0, // $0.00
        'status': 'settled',
        'daysAgo': 60,
        'dueInDays': -20, // Settled
      },
      {
        'custIdx': 3,
        'ref': 'INV-2026-004',
        'principal': 240000, // $2,400.00
        'remaining': 240000,
        'status': 'active',
        'daysAgo': 50,
        'dueInDays': -35, // Overdue 35 days (31-60 DPD)
      },
      {
        'custIdx': 4,
        'ref': 'INV-2026-005',
        'principal': 600000, // $6,000.00
        'remaining': 150000, // $1,500.00
        'status': 'active',
        'daysAgo': 10,
        'dueInDays': 20, // Current
      },
      {
        'custIdx': 0,
        'ref': 'INV-2026-006',
        'principal': 180000, // $1,800.00
        'remaining': 0,
        'status': 'settled',
        'daysAgo': 15,
        'dueInDays': 5,
      },
    ];

    final List<String> debtIds = [];
    for (final dp in debtPlans) {
      final dId = _uuid.v4();
      debtIds.add(dId);
      final origin = now.subtract(Duration(days: dp['daysAgo'] as int));
      final due = now.add(Duration(days: dp['dueInDays'] as int));

      await db.insert('debts', {
        'id': dId,
        'tenant_id': tenantId,
        'customer_id': customerIds[dp['custIdx'] as int],
        'assigned_officer_id': officerId,
        'reference_number': dp['ref'] as String,
        'principal_amount_cents': dp['principal'] as int,
        'remaining_balance_cents': dp['remaining'] as int,
        'origin_date': origin.toIso8601String(),
        'due_date': due.toIso8601String(),
        'status': dp['status'] as String,
        'created_at': origin.toIso8601String(),
        'updated_at': now.toIso8601String(),
      });
    }

    // 3. Create sample payments
    final paymentPlans = [
      {'debtIdx': 0, 'amount': 300000, 'method': 'bank_transfer', 'daysAgo': 2}, // $3,000.00 (today/recent)
      {'debtIdx': 2, 'amount': 400000, 'method': 'check', 'daysAgo': 18},
      {'debtIdx': 2, 'amount': 420000, 'method': 'bank_transfer', 'daysAgo': 8},
      {'debtIdx': 4, 'amount': 450000, 'method': 'card', 'daysAgo': 1},
      {'debtIdx': 5, 'amount': 180000, 'method': 'cash', 'daysAgo': 0}, // Today $1,800.00
    ];

    for (final pp in paymentPlans) {
      final pId = _uuid.v4();
      final pDate = now.subtract(Duration(days: pp['daysAgo'] as int));
      await db.insert('payments', {
        'id': pId,
        'tenant_id': tenantId,
        'debt_id': debtIds[pp['debtIdx'] as int],
        'recorded_by_id': officerId ?? 'admin-user',
        'amount_cents': pp['amount'] as int,
        'payment_method': pp['method'] as String,
        'transaction_reference': 'TXN-${DateTime.now().millisecondsSinceEpoch % 100000}',
        'receipt_number': 'RCP-${Random().nextInt(90000) + 10000}',
        'notes': 'Recorded via fintech gateway',
        'created_at': pDate.toIso8601String(),
      });
    }

    // 4. Create sample recovery interactions
    final interactionPlans = [
      {
        'custIdx': 1,
        'debtIdx': 1,
        'type': 'call',
        'outcome': 'Promised to Pay',
        'promisedCents': 150000,
        'followUpInDays': 0, // Due today!
        'daysAgo': 1,
      },
      {
        'custIdx': 3,
        'debtIdx': 3,
        'type': 'email',
        'outcome': 'Left Message',
        'promisedCents': null,
        'followUpInDays': 3,
        'daysAgo': 2,
      },
      {
        'custIdx': 4,
        'debtIdx': 4,
        'type': 'field_visit',
        'outcome': 'Payment Received',
        'promisedCents': null,
        'followUpInDays': null,
        'daysAgo': 1,
      },
      {
        'custIdx': 0,
        'debtIdx': 0,
        'type': 'call',
        'outcome': 'Callback Requested',
        'promisedCents': null,
        'followUpInDays': 2,
        'daysAgo': 0,
      },
    ];

    for (final ip in interactionPlans) {
      final iId = _uuid.v4();
      final iDate = now.subtract(Duration(days: ip['daysAgo'] as int));
      final followUp = ip['followUpInDays'] != null
          ? now.add(Duration(days: ip['followUpInDays'] as int))
          : null;

      await db.insert('interaction_logs', {
        'id': iId,
        'tenant_id': tenantId,
        'debt_id': debtIds[ip['debtIdx'] as int],
        'customer_id': customerIds[ip['custIdx'] as int],
        'officer_id': officerId,
        'action_type': ip['type'] as String,
        'outcome': ip['outcome'] as String,
        'follow_up_date': followUp?.toIso8601String(),
        'promised_amount_cents': ip['promisedCents'],
        'notes': 'Logged during recovery cycle.',
        'created_at': iDate.toIso8601String(),
      });
    }
  }
}
