import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.go('/dashboard');
    });
  }
  @override
  void dispose() {
    super.dispose();
  }
  @override
  Widget build(BuildContext context) {
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
    );
  }
}