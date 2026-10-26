import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/constants/app_colors.dart';
import 'core/router/app_router.dart';

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
    final router = ref.watch(appRouterProvider);

    return MaterialApp.router(
      title: 'Debit Recovery System',
      debugShowCheckedModeBanner: false,
      routerConfig: router,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: AppColors.surfaceBase,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.brandPrimary,
          primary: AppColors.brandPrimary,
          surface: AppColors.surfaceRaised,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.surfaceSidebar,
          foregroundColor: AppColors.inkWhite,
          elevation: 0,
        ),
        cardTheme: CardThemeData(
          color: AppColors.surfaceRaised,
          elevation: 1,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
            side: const BorderSide(color: AppColors.borderSubtle),
          ),
        ),
        dividerTheme: const DividerThemeData(
          color: AppColors.borderSubtle,
          thickness: 1,
        ),
      ),
    );
  }
}
