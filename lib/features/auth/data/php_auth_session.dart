import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/user_profile.dart';

/// Holds the authenticated user session obtained from the PHP/MySQL backend.
/// This is separate from the Supabase-based auth controller and is used
/// exclusively for PHP API authentication.
class PhpAuthSession extends Notifier<UserProfile?> {
  @override
  UserProfile? build() => null;

  /// Returns the current authenticated user, or null if not logged in.
  UserProfile? get currentUser => state;

  /// Set the authenticated user after login or registration.
  void setUser(UserProfile user) {
    state = user;
  }

  /// Clear the session on logout.
  void clear() {
    state = null;
  }
}

/// Provider for the PHP auth session.
final phpAuthSessionProvider =
    NotifierProvider<PhpAuthSession, UserProfile?>(PhpAuthSession.new);