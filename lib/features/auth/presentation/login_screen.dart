import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:http/http.dart' as http;
import '../../../api_config.dart';

import '../../../core/constants/app_colors.dart';
import '../domain/user_profile.dart';
import 'auth_controller.dart';
import '../data/php_auth_session.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoggingIn = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    debugPrint('Login submit started');
    setState(() => _isLoggingIn = true);
    try {
      final response = await http.post(
        Uri.parse(ApiConfig.loginUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'identifier': _emailController.text.trim(),
          'password': _passwordController.text,
        }),
      );
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      debugPrint('Login response status: ${response.statusCode}');
      debugPrint('Login response body: ${response.body}');
      if (response.statusCode >= 200 && response.statusCode < 300 && data['success'] == true) {
        final userData = data['user'] as Map<String, dynamic>?;
        if (userData != null && mounted) {
          final user = UserProfile(
            id: userData['id']?.toString() ?? '',
            tenantId: '',
            email: userData['email']?.toString() ?? '',
            fullName: userData['full_name']?.toString() ?? '',
            role: UserRole.recoveryOfficer,
            isActive: true,
          );
          ref.read(phpAuthSessionProvider.notifier).setUser(user);
          debugPrint('Login success: user stored in session');
        }
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(data['message']?.toString() ?? 'Login successful'),
              backgroundColor: AppColors.accentSuccess,
            ),
          );
          context.go('/dashboard');
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(data['message']?.toString() ?? 'Login failed'), backgroundColor: AppColors.accentDanger),
          );
        }
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Network error. Please try again.'), backgroundColor: AppColors.accentDanger),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoggingIn = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isLoading = authState.isLoading;
    final base = isDark ? AppColors.surfaceDark : AppColors.surfaceBase;
    final card = isDark ? AppColors.surfaceDarkCard : AppColors.surfaceCard;

    return Scaffold(
      backgroundColor: base,
      body: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 400),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: _neumorphicDecoration(isDark, card, radius: 20),
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(14),
                            decoration: _neumorphicDecoration(isDark, card, radius: 16, inset: true),
                            child: Icon(
                              Icons.account_balance_wallet,
                              color: AppColors.brandPrimary,
                              size: 36,
                            ),
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'Debit Recovery',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                              color: AppColors.inkPrimary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Operations & Collections',
                            style: TextStyle(
                              fontSize: 13,
                              color: AppColors.inkSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),


                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: _neumorphicDecoration(isDark, card, radius: 24),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _neumorphicField(
                              isDark: isDark,
                              card: card,
                              child: TextFormField(
                                controller: _emailController,
                                keyboardType: TextInputType.emailAddress,
                                decoration: const InputDecoration(
                                  border: InputBorder.none,
                                  hintText: 'Email address',
                                  prefixIcon: Icon(Icons.email_outlined),
                                ),
                                validator: (v) {
                                  if (v == null || v.trim().isEmpty) return 'Email is required';
                                  if (!v.contains('@')) return 'Enter a valid email';
                                  return null;
                                },
                              ),
                            ),
                            const SizedBox(height: 16),
                            _neumorphicField(
                              isDark: isDark,
                              card: card,
                              child: TextFormField(
                                controller: _passwordController,
                                obscureText: _obscurePassword,
                                decoration: InputDecoration(
                                  border: InputBorder.none,
                                  hintText: 'Password',
                                  prefixIcon: const Icon(Icons.lock_outline),
                                  suffixIcon: IconButton(
                                    icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility),
                                    onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                                  ),
                                ),
                                validator: (v) {
                                  if (v == null || v.isEmpty) return 'Password is required';
                                  if (v.length < 6) return 'Minimum 6 characters';
                                  return null;
                                },
                              ),
                            ),
                            const SizedBox(height: 24),
                            SizedBox(
                              height: 52,
                              child: ElevatedButton(
                                onPressed: _isLoggingIn ? null : _submit,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.brandPrimary,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                  elevation: 0,
                                ),
                                child: _isLoggingIn
                                    ? const SizedBox(
                                        width: 22,
                                        height: 22,
                                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                      )
                                    : const Text('Sign In', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                              ),
                            ),
                            const SizedBox(height: 12),
                            TextButton(
                              onPressed: isLoading ? null : () => context.push('/create-account'),
                              child: const Text('Create Account'),
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (kDebugMode) ...[
                      const SizedBox(height: 24),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: _neumorphicDecoration(isDark, card, radius: 16),
                        child: Column(
                          children: [
                            const Text('Demo Persona Access (dev only)',
                                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.inkSecondary)),
                            const SizedBox(height: 8),
                            Wrap(
                              alignment: WrapAlignment.center,
                              spacing: 8,
                              children: [
                                _demoChip(context, ref, 'Admin', UserRole.admin),
                                _demoChip(context, ref, 'Recovery', UserRole.recoveryOfficer),
                                _demoChip(context, ref, 'Finance', UserRole.financeOfficer),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _demoChip(BuildContext context, WidgetRef ref, String label, UserRole role) {
    return ActionChip(
      label: Text(label, style: const TextStyle(fontSize: 12)),
      avatar: const Icon(Icons.person, size: 16),
      onPressed: () {
        ref.read(authControllerProvider.notifier).switchDemoRole(role);
        context.go('/dashboard');
      },
    );
  }

  BoxDecoration _neumorphicDecoration(bool isDark, Color card, {double radius = 16, bool inset = false}) {
    if (isDark) {
      return BoxDecoration(
        color: card,
        borderRadius: BorderRadius.circular(radius),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.4), offset: const Offset(4, 4), blurRadius: 8),
          BoxShadow(color: Colors.white.withValues(alpha: 0.05), offset: const Offset(-4, -4), blurRadius: 8),
        ],
      );
    }
    return BoxDecoration(
      color: card,
      borderRadius: BorderRadius.circular(radius),
      boxShadow: inset
          ? [
              BoxShadow(color: Colors.black.withValues(alpha: 0.08), offset: const Offset(2, 2), blurRadius: 4, spreadRadius: -2),
              BoxShadow(color: Colors.white.withValues(alpha: 0.9), offset: const Offset(-2, -2), blurRadius: 4, spreadRadius: -2),
            ]
          : [
              BoxShadow(color: Colors.black.withValues(alpha: 0.12), offset: const Offset(6, 6), blurRadius: 12),
              BoxShadow(color: Colors.white.withValues(alpha: 0.9), offset: const Offset(-6, -6), blurRadius: 12),
            ],
    );
  }

  Widget _neumorphicField({required bool isDark, required Color card, required Widget child}) {
    return Container(
      decoration: _neumorphicDecoration(isDark, card, radius: 14, inset: true),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: child,
    );
  }
}
