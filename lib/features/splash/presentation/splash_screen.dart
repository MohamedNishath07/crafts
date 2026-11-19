import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:crafts/features/auth/presentation/auth_controller.dart';

class SplashScreen extends ConsumerWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authControllerProvider);
    final isLoading = authState.isLoading;

    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.remove_circle_outlined,
                color: Color(0xFF0F8D65), size: 40),
            SizedBox(height: 32),
            Text('DEBIT RECOVERY',
                style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold,
                    color: Colors.white)),
            Text('Smart Credit & Financial Management',
                style: TextStyle(fontSize: 14, color: Colors.white70)),
            SizedBox(height: 24),
            Text('Loading your experience...',
                style: TextStyle(fontSize: 12, color: Colors.white60)),
            SizedBox(height: 24),
            Icon(Icons.remove_circle_outlined,
                color: Color(0xFF0F8D65), size: 40),
          ],
        ),
      ),
      bottomSheet: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ElevatedButton(
          onPressed: isLoading
              ? null
              : () {
                  final hasSession = authState.value != null;
                  if (hasSession) {
                    context.go('/dashboard');
                  } else {
                    context.go('/login');
                  }
                },
          child: const Text('Get Started'),
        ),
      ),
    );
  }
}