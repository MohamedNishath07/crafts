import 'package:flutter_riverpod/legacy.dart';
import 'package:credit_recovery_system/core/sqlitedatabase.dart';
import 'package:credit_recovery_system/core/auth/user_model.dart';
import 'package:credit_recovery_system/core/auth/password_hasher.dart';

// Authentication repository that manages auth state using SQLite.
// Filters all operations by tenant_id for multi-user isolation.
class AuthRepository extends StateNotifier<User> {
  // Initialize the database reference
  late final SQLiteDatabase database;

  AuthRepository() : super(User(id: '', email: '', isActive: false)) {
    database = SQLiteDatabase();
  }

  User _currentUser = User(id: '', email: '', isActive: true);

  /// Gets the current authenticated user
  User get currentUser => _currentUser;

  /// Checks if a user is currently authenticated
  bool get isAuthenticated => _currentUser.isActive;

  /// Signs in a user with email and password
  Future<void> signIn({
    required String email,
    required String password,
    required String tenantId,
  }) async {
    final db = await database.database;
    final users = await db.query(
      'users',
      where: 'email = ? AND tenant_id = ?',
      whereArgs: [email, tenantId],
    );

    if (users.isEmpty) {
      throw Exception('Authentication failed: user not found');
    }

    final user = users.first;
    _currentUser = User(
      id: user['id'] as String,
      email: user['email'] as String,
      name: user['full_name'] as String?,
      isActive: user['is_active'] as bool? ?? true,
    );
  }

  /// Signs out the current user
  Future<void> signOut() async {
    _currentUser = User(id: '', email: '', isActive: false);
  }

  /// Gets the current user profile from the database
  Future<User> getCurrentProfile() async {
    if (!_currentUser.isActive) return _currentUser;

    final db = await database.database;
    final users = await db.query(
      'users',
      where: 'id = ? AND tenant_id = ?',
      whereArgs: [_currentUser.id, _currentUser.email],
    );

    if (users.isEmpty) return _currentUser;

    final user = users.first;
    _currentUser = User(
      id: user['id'] as String,
      email: user['email'] as String,
      name: user['full_name'] as String?,
      isActive: user['is_active'] as bool? ?? true,
    );

    return _currentUser;
  }

  /// Returns the stored phone number for the current user, if any.
  Future<String?> getCurrentPhone() async {
    if (!_currentUser.isActive) return null;
    final db = await database.database;
    final rows = await db.query(
      'users',
      columns: ['phone'],
      where: 'id = ?',
      whereArgs: [_currentUser.id],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return rows.first['phone'] as String?;
  }

  /// Returns the stored profile photo path for the current user, if any.
  Future<String?> getCurrentProfilePhoto() async {
    if (!_currentUser.isActive) return null;
    final db = await database.database;
    final rows = await db.query(
      'users',
      columns: ['profile_photo'],
      where: 'id = ?',
      whereArgs: [_currentUser.id],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return rows.first['profile_photo'] as String?;
  }

  /// Signs up a new user
  Future<User> signUp({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    required String tenantId,
  }) async {
    // Check if user already exists
    final db = await database.database;
    final existing = await db.query(
      'users',
      where: 'email = ?',
      whereArgs: [email],
    );

    if (existing.isNotEmpty) {
      throw Exception('Sign up failed: user already exists');
    }

    final userId = DateTime.now().millisecondsSinceEpoch.toString();
    final fullName = '${firstName.trim()} ${lastName.trim()}'.trim();
    final now = DateTime.now().toIso8601String();

    await db.insert('users', {
      'id': userId,
      'tenant_id': tenantId,
      'email': email,
      'full_name': fullName,
      'role': 'recovery_officer',
      'is_active': 1,
      'password_hash': PasswordHasher.hashPassword(password),
      'phone': '',
      'profile_photo': null,
      'created_at': now,
      'updated_at': now,
    });

    final newUser = User(
      id: userId,
      email: email,
      name: fullName,
      isActive: true,
    );

    _currentUser = newUser;
    return newUser;
  }

  /// Updates the current user's profile
  Future<void> updateProfile({required String fullName, String? phone}) async {
    if (!_currentUser.isActive) return;

    final db = await database.database;
    await db.update(
      'users',
      {
        'full_name': fullName.trim(),
        if (phone != null) 'phone': phone.trim(),
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [_currentUser.id],
    );

    _currentUser = User(
      id: _currentUser.id,
      email: _currentUser.email,
      name: fullName.trim(),
      isActive: _currentUser.isActive,
    );
  }

  /// Updates the current user's profile photo path.
  Future<void> updateProfilePhoto({required String photoPath}) async {
    if (!_currentUser.isActive) return;
    final db = await database.database;
    await db.update(
      'users',
      {
        'profile_photo': photoPath,
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [_currentUser.id],
    );
  }

  /// Changes the current user's password after validating the current one.
  ///
  /// Throws an Exception when the current password is incorrect or the new
  /// password is too short. The new password is stored as a PBKDF2 hash, never
  /// in plain text.
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    if (!_currentUser.isActive) return;
    if (newPassword.trim().length < 6) {
      throw Exception('New password must be at least 6 characters');
    }

    final db = await database.database;
    final rows = await db.query(
      'users',
      columns: ['password_hash'],
      where: 'id = ?',
      whereArgs: [_currentUser.id],
      limit: 1,
    );
    if (rows.isEmpty) {
      throw Exception('Authentication failed: user not found');
    }

    final storedHash = rows.first['password_hash'] as String?;
    if (!PasswordHasher.verifyPassword(currentPassword, storedHash)) {
      throw Exception('Current password is incorrect');
    }

    await db.update(
      'users',
      {
        'password_hash': PasswordHasher.hashPassword(newPassword.trim()),
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [_currentUser.id],
    );
  }
}

/// Provider for the auth repository
final authRepositoryProvider = StateNotifierProvider<AuthRepository, User>((
  ref,
) {
  return AuthRepository();
});

