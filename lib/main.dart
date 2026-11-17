import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'core/sqlitedatabase.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/router/app_router.dart';
import 'core/theming/glassmorphism_theme.dart';

/// State provider for dark/light mode toggle
final darkModeProvider = StateProvider<bool>((ref) => false);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize SQLite database
  final sqliteDatabase = SQLiteDatabase();
  await sqliteDatabase.database;

  // ══════════════════════════════════════════════════════════════════════
// SUPABASE CONFIGURATION — REPLACE THESE WITH YOUR OWN PROJECT CREDENTIALS
// ══════════════════════════════════════════════════════════════════════
//
// 1. Create a free project at https://supabase.com
// 2. Go to Project Settings → API to get your Project URL and anon public key
// 3. Enable Email/Password auth: Authentication → Providers → Email → Enable
//
// Then either:
//   a) Set environment variables before running:
//      $env:SUPABASE_URL = "https://your-project-ref.supabase.co"
//      $env:SUPABASE_ANON_KEY = "your-anon-public-key"
//   b) Or replace the defaultValue strings below with your real credentials.
// ══════════════════════════════════════════════════════════════════════
  final supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://YOUR_PROJECT_REF.supabase.co', // <-- REPLACE ME
  );
  final supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: 'YOUR_ANON_PUBLIC_KEY', // <-- REPLACE ME
  );

  final isDemoCredentials = supabaseUrl.contains('YOUR_PROJECT_REF') ||
      supabaseAnonKey == 'YOUR_ANON_PUBLIC_KEY';

  try {
    await Supabase.initialize(
      url: supabaseUrl,
      publishableKey: supabaseAnonKey,
      debug: false,
    );
    if (isDemoCredentials) {
      debugPrint(
        '⚠️  Supabase is running with demo placeholder credentials. '
        'Sign in / sign up will not work until you add real Supabase API keys.',
      );
    } else {
      debugPrint('✅ Supabase initialized successfully');
    }
  } catch (e) {
    debugPrint('❌ Supabase initialization failed: $e');
    debugPrint('   The app will continue with SQLite (offline mode) only.');
  }

  runApp(
    const ProviderScope(
      child: DebitRecoveryApp(),
    ),
  );
}

class DebitRecoveryApp extends ConsumerWidget {
  const DebitRecoveryApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = ref.watch(darkModeProvider);
    final router = ref.watch(appRouterProvider);

    return MaterialApp.router(
      title: 'Debit Recovery System',
      debugShowCheckedModeBanner: false,
      routerConfig: router,
      theme: GlassmorphismTheme.light.copyWith(
        extensions: [GlassmorphismTheme.extension],
      ),
      darkTheme: GlassmorphismTheme.dark.copyWith(
        extensions: [GlassmorphismTheme.extension],
      ),
      themeMode: isDark ? ThemeMode.dark : ThemeMode.light,
    );
  }
}
