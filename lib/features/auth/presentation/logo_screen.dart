import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/services.dart' show SystemChrome, SystemUiOverlayStyle;

import '../../../core/constants/app_colors.dart';
import 'auth_controller.dart';

class LogoScreen extends ConsumerStatefulWidget {
  const LogoScreen({super.key});

  @override
  ConsumerState<LogoScreen> createState() => _LogoScreenState();
}

class _LogoScreenState extends ConsumerState<LogoScreen> {
  bool _navigationScheduled = false;

  @override
  void initState() {
    super.initState();
    // Get platform brightness (available before context is built)
    final platformBrightness =
        WidgetsBinding.instance.platformDispatcher.platformBrightness;
    final isDark = platformBrightness == Brightness.dark;
    // Set system UI overlay style
    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);
    if (!authState.isLoading && !_navigationScheduled) {
      _navigationScheduled = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        context.go('/login');
      });
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final base = isDark ? AppColors.surfaceDark : AppColors.surfaceBase;

    return Scaffold(
      backgroundColor: base,
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Spacer(),
              // App logo/title
              SizedBox.square(
                dimension: (MediaQuery.of(context).size.width * 0.70).clamp(
                  240.0,
                  440.0,
                ),
                child: Image.asset(
                  'assets/images/app_logo.png',
                  fit: BoxFit.contain,
                ),
              ),
              const SizedBox(height: 5),
              const Text(
                'Version 1.0.0',
                style: TextStyle(fontSize: 14, color: AppColors.inkSecondary),
              ),
              const Spacer(),
              const SizedBox(height: 48),
            ],
          ),
        ),
      ),
    );
  }
}
