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
    final themeMode = ref.watch(themeModeProvider);
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
      themeMode: themeMode.toThemeMode(),
    );
  }
}
