import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:credit_recovery_system/core/auth/user_model.dart';

/// Notifier that manages the current user authentication state using SQLite
class CurrentUserNotifier extends StateNotifier<User?> {
  CurrentUserNotifier() : super(null) {
    // Initialize SQLite and load current user state
    _loadUserState();
  }

  /// Load user state from SQLite database
  Future<void> _loadUserState() async {
    // In a full implementation, we'd query the users table for the current user
    // For now, state starts as null (not authenticated)
  }

  /// Returns the current user or null if not authenticated
  User? get currentUser => state;

  /// Forces a re-fetch of the current user session
  Future<void> refreshSession() async {
    // In offline SQLite mode, we reload from local storage
    await _loadUserState();
  }

  /// Signs out the current user
  Future<void> signOut() async {
    state = null;
  }
}

/// Extension to add Riverpod listener support
extension CurrentUserExtension on Ref {
  User? get currentUser => read(currentUserProvider);
  User? get getMaybeCurrentUser => watch(currentUserProvider);
}

/// Provider for current user authentication state
final currentUserProvider = StateNotifierProvider<CurrentUserNotifier, User?>((ref) {
  return CurrentUserNotifier();
});

