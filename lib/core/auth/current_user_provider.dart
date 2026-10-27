import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Provider for current user authentication state
final currentUserProvider = StateNotifierProvider<CurrentUserNotifier, User?>((ref) {
  // Listen to auth changes
  /// Notifier that manages the current user authentication state using Supabase
class CurrentUserNotifier extends StateNotifier<User?> {
  CurrentUserNotifier() : super(null) {
    // Listen to auth changes from Supabase
    supabase.auth.onAuthStateChange.listen((data) {
      state = data.session?.user;
    });
  }

  // Supabase client instance
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Returns the current user or null if not authenticated
  User? get currentUser => state;

  /// Forces a re-fetch of the current user session
  Future<void> refreshSession() async {
    await _supabase.auth.getSession();
  }

  /// Signs out the current user
  Future<void> signOut() async {
    await _supabase.auth.signOut();
  }
}
  
  
  
  

  
  supabase.auth.onAuthStateChange.listen((data) {
    
    
  });
  
  
  
});

/// Extension to add Riverpod listener support
extension CurrentUserExtension on Ref {
  User? get currentUser => read(currentUserProvider);
  User? getMaybeCurrentUser => watch(currentUserProvider);
}