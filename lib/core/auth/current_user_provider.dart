import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Notifier that manages the current user authentication state using Supabase
class CurrentUserNotifier extends StateNotifier<User?> {
  CurrentUserNotifier() : super(null) {
    // Listen to auth changes from Supabase
    _supabase.auth.onAuthStateChange.listen((data) {
      state = data.session?.user;
    });
    state = _supabase.auth.currentUser;
  }

  // Supabase client instance
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Returns the current user or null if not authenticated
  User? get currentUser => state;

  /// Forces a re-fetch of the current user session
  Future<void> refreshSession() async {
    await _supabase.auth.getSession();
    state = _supabase.auth.currentUser;
  }

  /// Signs out the current user
  Future<void> signOut() async {
    await _supabase.auth.signOut();
    state = null;
  }
}

/// Provider for current user authentication state
final currentUserProvider = StateNotifierProvider<CurrentUserNotifier, User?>((ref) {
  return CurrentUserNotifier();
});

/// Extension to add Riverpod listener support
extension CurrentUserExtension on Ref {
  User? get currentUser => read(currentUserProvider);
  User? get getMaybeCurrentUser => watch(currentUserProvider);
}
