import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../domain/user_profile.dart';
import 'auth_controller.dart';
import '../theming/glassmorphism_widgets.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController(text: 'admin@acme.com');
  final _passwordController = TextEditingController(text: 'Password123!');
  final bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }


  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.surfaceDark : AppColors.surfaceBase,
      body: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
        ),
        child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: GlassmorphismContainer(
              isDark: isDark,
              border: Border.all(color: AppColors.borderGlassLight, width: 1),
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Header
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: AppColors.brandPrimary.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.account_balance_wallet,
                              color: AppColors.brandPrimary,
                              size: 32,
                            ),
                          ),
                          const SizedBox(width: 16),
                          const Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Debit Recovery',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.inkPrimary,
                                ),
                              ),
                              Text(
                                'Operations & Collections',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.inkSecondary,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 28),

                      const Text(
                        'Sign in to your account',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppColors.inkPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Enter your staff credentials to access your workspace',
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.inkSecondary,
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Error Banner
                      if (authState.hasError) ...[
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.accentDanger.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: AppColors.accentDanger.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.error_outline,
                                color: AppColors.accentDanger,
                                size: 20,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  '${authState.error}',
                                  style: const TextStyle(
                                    color: AppColors.accentDanger,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],

                      // Email Field
                      GlassTextField(
                        controller: _emailController,
                        hintText: 'Email address',
                        labelText: 'Email',
                        prefixIcon: const Icon(Icons.email_outlined,
                            color: AppColors.inkMuted, size: 20),
                        keyboardType: TextInputType.emailAddress,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your email';
                          }
                          return null;
                        },
                        isDark: isDark,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                      ),
                      const SizedBox(height: 16),

                      // Password Field
                      GlassTextField(
                        controller: _passwordController,
                        hintText: 'Password',
                        labelText: 'Password',
                        prefixIcon: const Icon(Icons.lock_outlined,
                            color: AppColors.inkMuted, size: 20),
                        obscureText: _obscurePassword,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your password';
                          }
                          return null;
                        },
                        isDark: isDark,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                      ),
                      const SizedBox(height: 24),

                      // Submit Button
                      GlassmorphismContainer(
                        isDark: isDark,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        child: ElevatedButton(
                          onPressed: authState.isLoading
                              ? null
                              : () async {
                                  if (!_formKey.currentState!.validate()) return;
                                  await ref
                                      .read(authControllerProvider.notifier)
                                      .signIn(
                                        email: _emailController.text,
                                        password: _passwordController.text,
                                      );

                                  final state = ref.read(authControllerProvider);
                                  if (!state.hasError && context.mounted) {
                                    context.go('/dashboard');
                                  }
                                },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.brandPrimary,
                            foregroundColor: AppColors.inkWhite,
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            elevation: 2,
                          ),
                          child: authState.isLoading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: AppColors.inkWhite,
                                  ),
                                )
                              : const Text(
                                  'Sign In',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Quick Demo Role Switcher
                      const Divider(color: AppColors.borderSubtle),
                      const SizedBox(height: 12),
                      const Text(
                        'Demo Persona Access:',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.inkSecondary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        alignment: WrapAlignment.center,
                        spacing: 8,
                        children: [
                          ActionChip(
                            label: const Text('Admin', style: TextStyle(fontSize: 12)),
                            avatar: const Icon(Icons.admin_panel_settings, size: 16),
                            onPressed: () {
                              ref
                                  .read(authControllerProvider.notifier)
                                  .switchDemoRole(UserRole.admin);
                              context.go('/dashboard');
                            },
                          ),
                          ActionChip(
                            label: const Text('Recovery', style: TextStyle(fontSize: 12)),
                            avatar: const Icon(Icons.phone_forwarded, size: 16),
                            onPressed: () {
                              ref
                                  .read(authControllerProvider.notifier)
                                  .switchDemoRole(UserRole.recoveryOfficer);
                              context.go('/dashboard');
                            },
                          ),
                          ActionChip(
                            label: const Text('Finance', style: TextStyle(fontSize: 12)),
                            avatar: const Icon(Icons.payments_outlined, size: 16),
                            onPressed: () {
                              ref
                                  .read(authControllerProvider.notifier)
                                  .switchDemoRole(UserRole.financeOfficer);
                              context.go('/dashboard');
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
      ),
    );
  }
}
