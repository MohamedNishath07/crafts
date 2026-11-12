import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/router/app_router.dart';
import 'core/theming/glassmorphism_theme.dart';

/// State provider for dark/light mode toggle
final darkModeProvider = StateProvider<bool>((ref) => false);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Supabase client
  // Uses environment variables or local development fallback
  const supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://demo-debit-recovery.supabase.co',
  );
  const supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.demo-anon-key',
  );

  try {
    await Supabase.initialize(
      url: supabaseUrl,
      publishableKey: supabaseAnonKey,
      debug: false,
    );
  } catch (e) {
    debugPrint('Supabase initialization notice: $e');
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
