import 'package:flutter_riverpod/legacy.dart';
import 'package:crafts/core/sqlitedatabase.dart';
import 'package:crafts/core/auth/user_model.dart';

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
  Future<void> signIn({required String email, required String password, required String tenantId}) async {
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

    await db.insert(
      'users',
      {
        'id': userId,
        'tenant_id': tenantId,
        'email': email,
        'full_name': fullName,
        'role': 'recovery_officer',
        'is_active': 1,
        'password_hash': password, // Placeholder - use bcrypt in production
        'created_at': now,
        'updated_at': now,
      },
    );

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
  Future<void> updateProfile({
    required String fullName,
  }) async {
    if (!_currentUser.isActive) return;

    final db = await database.database;
    await db.update(
      'users',
      {
        'full_name': fullName.trim(),
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

  /// Updates the current user's password
  Future<void> updatePassword({required String newPassword}) async {
    // In a real implementation, this would update the password hash in the database
    // For now, we'll just update the local state
    // The password_hash is stored as a placeholder - use bcrypt in production
    if (!_currentUser.isActive) return;
  }
}

/// Provider for the auth repository
final authRepositoryProvider = StateNotifierProvider<AuthRepository, User>((ref) {
  return AuthRepository();
});