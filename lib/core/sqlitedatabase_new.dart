import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

/// Singleton SQLite Database helper class
/// Provides local database access for all project features
class SQLiteDatabase {
  static final SQLiteDatabase _instance = SQLiteDatabase._internal();
  factory SQLiteDatabase() => _instance;
  SQLiteDatabase._internal();

  Database? _database;

  /// Get or create the database
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  /// Initialize the database with all tables
  Future<Database> _initDatabase() async {
    final documentsDirectory = await getApplicationDocumentsDirectory();
    final path = join(documentsDirectory.path, 'crafts.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  /// Create all tables
  Future<void> _onCreate(Database db, int version) async {
    // Customers table
    await db.execute('''
      CREATE TABLE customers (
        id TEXT PRIMARY KEY,
        tenant_id TEXT NOT NULL,
        full_name TEXT NOT NULL,
        phone_number TEXT NOT NULL,
        secondary_phone TEXT,
        email TEXT,
        national_id TEXT,
        address TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    // Payments table
    await db.execute('''
      CREATE TABLE payments (
        id TEXT PRIMARY KEY,
        tenant_id TEXT NOT NULL,
        debt_id TEXT,
        recorded_by_id TEXT,
        amount_cents INTEGER NOT NULL,
        payment_method TEXT NOT NULL,
        transaction_reference TEXT,
        receipt_number TEXT NOT NULL,
        notes TEXT,
        created_at TEXT NOT NULL
      )
    ''');

    // Debts table
    await db.execute('''
      CREATE TABLE debts (
        id TEXT PRIMARY KEY,
        tenant_id TEXT NOT NULL,
        customer_id TEXT,
        assigned_officer_id TEXT,
        reference_number TEXT NOT NULL,
        principal_amount_cents INTEGER NOT NULL,
        remaining_balance_cents INTEGER NOT NULL,
        origin_date TEXT NOT NULL,
        due_date TEXT NOT NULL,
        status TEXT NOT NULL DEFAULT 'active',
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    // Profiles table (for staff/admins)
    await db.execute('''
      CREATE TABLE profiles (
        id TEXT PRIMARY KEY,
        tenant_id TEXT NOT NULL,
        email TEXT NOT NULL,
        full_name TEXT NOT NULL,
        role TEXT NOT NULL DEFAULT 'staff',
        is_active INTEGER NOT NULL DEFAULT 1,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    // Interaction logs table
    await db.execute('''
      CREATE TABLE interaction_logs (
        id TEXT PRIMARY KEY,
        tenant_id TEXT NOT NULL,
        debt_id TEXT,
        customer_id TEXT,
        officer_id TEXT,
        action_type TEXT NOT NULL,
        outcome TEXT,
        follow_up_date TEXT,
        promised_amount_cents INTEGER,
        notes TEXT,
        created_at TEXT NOT NULL
      )
    ''');

    // Reminder settings table
    await db.execute('''
      CREATE TABLE reminder_settings (
        id TEXT PRIMARY KEY,
        tenant_id TEXT NOT NULL,
        email_enabled INTEGER NOT NULL DEFAULT 1,
        sms_enabled INTEGER NOT NULL DEFAULT 0,
        email_offset_days TEXT NOT NULL DEFAULT '3,1,0',
        sms_offset_days TEXT NOT NULL DEFAULT '3,0',
        message_template TEXT NOT NULL,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    // Reminder dispatches table
    await db.execute('''
      CREATE TABLE reminder_dispatches (
        id TEXT PRIMARY KEY,
        tenant_id TEXT NOT NULL,
        debt_id TEXT NOT NULL,
        customer_id TEXT NOT NULL,
        channel TEXT NOT NULL,
        recipient TEXT NOT NULL,
        message TEXT NOT NULL,
        status TEXT NOT NULL DEFAULT 'pending',
        scheduled_for TEXT,
        sent_at TEXT,
        created_at TEXT NOT NULL
      )
    ''');
  }

  /// Database upgrade handler
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // Handle schema migrations if needed
  }

  /// Close the database connection
  Future close() async {
    final db = await database;
    await db.close();
  }

  /// Get the raw database instance for complex queries
  Database getRawDatabase() => _database!;

  // -------------------------------------------------------------------------
  // Tenant-scoped query helpers used by the feature repositories
  // -------------------------------------------------------------------------

  /// Fetch all customers for a tenant.
  Future<List<Map<String, dynamic>>> fetchCustomers(String tenantId) async {
    final db = await database;
    return await db.query(
      'customers',
      where: 'tenant_id = ?',
      whereArgs: [tenantId],
    );
  }

  /// Fetch a single customer by id, tenant-scoped.
  Future<Map<String, dynamic>?> fetchCustomerById(
      String id, String tenantId) async {
    final db = await database;
    final result = await db.query(
      'customers',
      where: 'id = ? AND tenant_id = ?',
      whereArgs: [id, tenantId],
    );
    return result.isNotEmpty ? result.first : null;
  }

  /// Fetch all debts for a tenant.
  Future<List<Map<String, dynamic>>> fetchDebts(String tenantId) async {
    final db = await database;
    return await db.query(
      'debts',
      where: 'tenant_id = ?',
      whereArgs: [tenantId],
    );
  }

  /// Fetch a single debt by id, tenant-scoped.
  Future<Map<String, dynamic>?> fetchDebtById(String id, String tenantId) async {
    final db = await database;
    final result = await db.query(
      'debts',
      where: 'id = ? AND tenant_id = ?',
      whereArgs: [id, tenantId],
    );
    return result.isNotEmpty ? result.first : null;
  }

  /// Insert a new debt record.
  Future<int> insertDebt(Map<String, dynamic> data) async {
    final db = await database;
    return await db.insert('debts', data);
  }

  /// Update an existing debt record (matched by `id`).
  Future<void> updateDebt(Map<String, dynamic> data) async {
    final db = await database;
    final id = data['id'] as String;
    await db.update(
      'debts',
      data,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Fetch all payments for a tenant.
  Future<List<Map<String, dynamic>>> fetchPayments(String tenantId) async {
    final db = await database;
    return await db.query(
      'payments',
      where: 'tenant_id = ?',
      whereArgs: [tenantId],
    );
  }

  /// Insert a new payment record.
  Future<int> insertPayment(Map<String, dynamic> data) async {
    final db = await database;
    return await db.insert('payments', data);
  }

  /// Fetch reminder settings for a tenant (at most one row).
  Future<Map<String, dynamic>?> fetchReminderSettings(String tenantId) async {
    final db = await database;
    final result = await db.query(
      'reminder_settings',
      where: 'tenant_id = ?',
      whereArgs: [tenantId],
      limit: 1,
    );
    return result.isNotEmpty ? result.first : null;
  }

  /// Insert or update reminder settings for a tenant.
  Future<Map<String, dynamic>> upsertReminderSettings(
      Map<String, dynamic> data) async {
    final db = await database;
    final tenantId = data['tenant_id'] as String;
    final existing = await fetchReminderSettings(tenantId);
    if (existing != null) {
      await db.update(
        'reminder_settings',
        data,
        where: 'tenant_id = ?',
        whereArgs: [tenantId],
      );
      return data;
    }
    final id = await db.insert('reminder_settings', data);
    return {...data, 'id': id};
  }

  /// Fetch all reminder dispatches for a tenant.
  Future<List<Map<String, dynamic>>> fetchReminderDispatches(
      String tenantId) async {
    final db = await database;
    return await db.query(
      'reminder_dispatches',
      where: 'tenant_id = ?',
      whereArgs: [tenantId],
    );
  }

  /// Insert a reminder dispatch and return the row with its generated id.
  Future<Map<String, dynamic>> insertReminderDispatch(
      Map<String, dynamic> data) async {
    final db = await database;
    final id = await db.insert('reminder_dispatches', data);
    return {...data, 'id': id};
  }

  /// Fetch all interaction logs for a tenant.
  Future<List<Map<String, dynamic>>> fetchInteractions(String tenantId) async {
    final db = await database;
    return await db.query(
      'interaction_logs',
      where: 'tenant_id = ?',
      whereArgs: [tenantId],
    );
  }

  /// Insert an interaction log and return the row with its generated id.
  Future<Map<String, dynamic>> insertInteractionLog(
      Map<String, dynamic> data) async {
    final db = await database;
    final id = await db.insert('interaction_logs', data);
    return {...data, 'id': id};
  }

  /// Fetch profiles filtered by tenant_id
  Future<List<Map<String, dynamic>>> fetchProfiles(String tenantId) async {
    final db = await database;
    final result = await db.query(
      'profiles',
      where: 'tenant_id = ?',
      whereArgs: [tenantId],
    );
    return result;
  }

  /// Insert a new record into the specified table
  Future<int> insert(String table, Map<String, dynamic> data) async {
    final db = await database;
    return await db.insert(table, data);
  }

  /// Update a profile by ID
  Future<void> updateProfile(Map<String, dynamic> data) async {
    final db = await database;
    final id = data['id'] as String;
    await db.update(
      'profiles',
      data,
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
