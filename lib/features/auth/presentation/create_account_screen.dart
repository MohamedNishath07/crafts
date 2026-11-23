import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import 'auth_controller.dart';

class ValidationHelpers {
  static String? validateName(String? value) {
    if (value == null || value.trim().isEmpty) return 'Please enter a name';
    if (!RegExp(r'^[a-zA-Z\s]+$').hasMatch(value.trim())) return 'Name must contain only letters and spaces';
    if (value.trim().length < 2) return 'Name must be at least 2 characters';
    return null;
  }

  static String? validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) return 'Please enter an email';
    return null;
  }

  static String? validatePassword(String? value) {
    if (value == null || value.trim().isEmpty) return 'Please enter a password';
    if (value.length < 6) return 'Password must be at least 6 characters';
    return null;
  }

  static String? validatePasswordMatch({required String password, required String confirmPassword}) {
    if (confirmPassword.isEmpty) return 'Please confirm your password';
    if (password != confirmPassword) return 'Passwords do not match';
    return null;
  }
}

class CreateAccountScreen extends ConsumerStatefulWidget {
  const CreateAccountScreen({super.key});
  @override
  ConsumerState<CreateAccountScreen> createState() => _CreateAccountScreenState();
}

class _CreateAccountScreenState extends ConsumerState<CreateAccountScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _idNumberController = TextEditingController();
  final _phoneController = TextEditingController();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _idNumberController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _phoneController.dispose();
    _usernameController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSubmitting = true);
    try {
      await ref.read(authControllerProvider.notifier).createAccount(
            email: _emailController.text.trim(),
            password: _passwordController.text,
            firstName: _firstNameController.text.trim(),
            lastName: _lastNameController.text.trim(),
          );
      final authState = ref.read(authControllerProvider);
      if (authState.hasError) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Registration failed: ${authState.error}'), backgroundColor: AppColors.accentDanger),
          );
        }
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Account created successfully'), backgroundColor: AppColors.accentSuccess),
        );
        context.go('/dashboard');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Network error. Please try again.'), backgroundColor: AppColors.accentDanger),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  InputDecoration _deco(String label, IconData icon, {Widget? suffix}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textSecondary = AppColors.textSecondaryColor(isDark);
    final fieldFill = isDark
        ? AppColors.surfaceDarkSecondary
        : AppColors.surfaceSecondary;
    final fieldBorder = AppColors.borderColor(isDark);
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(color: textSecondary),
      prefixIcon: Icon(icon, color: textSecondary),
      suffixIcon: suffix,
      filled: true,
      fillColor: fieldFill,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: fieldBorder)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: fieldBorder)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppColors.accent, width: 1.5)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = AppColors.textPrimaryColor(isDark);
    final textSecondary = AppColors.textSecondaryColor(isDark);
    return Scaffold(
      backgroundColor: AppColors.bg(isDark),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: textPrimary),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Create Account', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: textPrimary)),
                    const SizedBox(height: 6),
                    Text('Create your account to get started.', style: TextStyle(fontSize: 14, color: textSecondary)),
                    const SizedBox(height: 24),
                    TextFormField(controller: _firstNameController, style: TextStyle(color: textPrimary), decoration: _deco('Full Name', Icons.person), validator: (v) => (v == null || v.trim().isEmpty) ? 'Full Name is required' : null),
                    const SizedBox(height: 12),
                    TextFormField(controller: _emailController, style: TextStyle(color: textPrimary), decoration: _deco('Email Address', Icons.email), validator: (v) {
                      if (v == null || v.trim().isEmpty) return 'Email is required';
                      if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(v.trim())) return 'Enter a valid email';
                      return null;
                    }),
                    const SizedBox(height: 12),
                    TextFormField(controller: _phoneController, keyboardType: TextInputType.phone, style: TextStyle(color: textPrimary), decoration: _deco('Phone Number', Icons.phone), validator: (v) {
                      if (v == null || v.trim().isEmpty) return 'Phone number is required';
                      final d = v.replaceAll(RegExp(r'\D'), '');
                      if (d.length < 9) return 'Enter a valid phone number';
                      return null;
                    }),
                    const SizedBox(height: 12),
                    TextFormField(controller: _usernameController, style: TextStyle(color: textPrimary), decoration: _deco('Username', Icons.account_circle), validator: (v) => (v == null || v.trim().isEmpty) ? 'Username is required' : null),
                    const SizedBox(height: 12),
                    TextFormField(controller: _passwordController, obscureText: _obscurePassword, style: TextStyle(color: textPrimary), decoration: _deco('Password', Icons.lock, suffix: IconButton(icon: Icon(_obscurePassword ? Icons.visibility : Icons.visibility_off, color: textSecondary), onPressed: () => setState(() => _obscurePassword = !_obscurePassword))), validator: (v) {
                      if (v == null || v.isEmpty) return 'Password is required';
                      if (v.length < 6) return 'At least 6 characters';
                      return null;
                    }),
                    const SizedBox(height: 12),
                    TextFormField(controller: _confirmPasswordController, obscureText: _obscureConfirm, style: TextStyle(color: textPrimary), decoration: _deco('Confirm Password', Icons.lock_outline, suffix: IconButton(icon: Icon(_obscureConfirm ? Icons.visibility : Icons.visibility_off, color: textSecondary), onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm))), validator: (v) {
                      if (v == null || v.isEmpty) return 'Confirm Password is required';
                      if (v != _passwordController.text) return 'Passwords do not match';
                      return null;
                    }),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: _isSubmitting ? null : _register,
                        style: ElevatedButton.styleFrom(backgroundColor: AppColors.accent, foregroundColor: Colors.black, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)), elevation: 0),
                        child: _isSubmitting ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black)) : const Text('Create Account', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('Already have an account? ', style: TextStyle(color: textSecondary)),
                        TextButton(onPressed: () => context.go('/login'), child: const Text('Sign In', style: TextStyle(color: AppColors.accent))),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}