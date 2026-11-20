import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/services.dart' show SystemChrome, SystemUiOverlayStyle;

import '../../../core/constants/app_colors.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
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
    // Simulate a 3 second delay for splash screen
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Timer(const Duration(seconds: 3), () {
        // Navigate to login after splash completes
        if (mounted) {
          context.go('/login');
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
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
