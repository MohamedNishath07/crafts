import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Provider for current user authentication state
final currentUserProvider = StateProvider<User?>((ref) {
  // Listen to auth changes
  final supabase = Supabase.instance.client;
  
  // Initialize with current session
  ref.onDispose(() {
    // Cleanup if needed
  });
  
  // Listen to auth changes and update state
  supabase.auth.onAuthStateChange.listen((data) {
    final session = data.session;
    ref.read(currentUserProvider.notifier).state = session?.user;
  });
  
  // Return initial user
  return supabase.auth.currentUser;
});

/// Extension to add Riverpod listener support
extension CurrentUserExtension on Ref {
  User? get currentUser => read(currentUserProvider);
  User? getMaybeCurrentUser => watch(currentUserProvider);
}