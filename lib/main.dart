import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/sqlitedatabase.dart';
import 'core/router/app_router.dart';
import 'core/theming/glassmorphism_theme.dart';
import 'core/theming/theme_settings_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final sqliteDatabase = SQLiteDatabase();
  await sqliteDatabase.database;

  runApp(const ProviderScope(child: DebitRecoveryApp()));
}

class DebitRecoveryApp extends ConsumerWidget {
  const DebitRecoveryApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    final themeMode = ref.watch(themeModeProvider);
    return MaterialApp.router(
      title: 'Debit Recovery System',
      debugShowCheckedModeBanner: false,
      routerConfig: router,
      theme: GlassmorphismTheme.light,
      darkTheme: GlassmorphismTheme.dark,
      themeMode: themeMode.toThemeMode(),
    );
  }
}