import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../domain/user_profile.dart';
import 'auth_controller.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final _profileFormKey = GlobalKey<FormState>();
  final _passwordFormKey = GlobalKey<FormState>();

  late final TextEditingController _nameController;
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isSavingProfile = false;
  bool _isSavingPassword = false;
  bool _obscureNewPassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void initState() {
    super.initState();
    final user = ref.read(authControllerProvider).value;
    _nameController = TextEditingController(text: user?.fullName ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Color _getRoleColor(UserRole role) {
    switch (role) {
      case UserRole.admin:
        return AppColors.accentDanger;
      case UserRole.financeOfficer:
        return AppColors.accentSuccess;
      case UserRole.recoveryOfficer:
        return AppColors.accentWarning;
    }
  }

  Future<void> _saveProfile() async {
    if (!_profileFormKey.currentState!.validate()) return;

    setState(() => _isSavingProfile = true);
    try {
      await ref.read(authControllerProvider.notifier).updateProfile(
            fullName: _nameController.text.trim(),
          );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile details updated successfully'),
            backgroundColor: AppColors.accentSuccess,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update profile: $e'),
            backgroundColor: AppColors.accentDanger,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSavingProfile = false);
      }
    }
  }

  Future<void> _changePassword() async {
    if (!_passwordFormKey.currentState!.validate()) return;

    setState(() => _isSavingPassword = true);
    try {
      await ref.read(authControllerProvider.notifier).changePassword(
            newPassword: _newPasswordController.text,
          );

      if (mounted) {
        _newPasswordController.clear();
        _confirmPasswordController.clear();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Password changed successfully'),
            backgroundColor: AppColors.accentSuccess,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to change password: $e'),
            backgroundColor: AppColors.accentDanger,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSavingPassword = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authControllerProvider).value;

    return Scaffold(
      backgroundColor: AppColors.surfaceBase,
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header
                const Text(
                  'Profile & Security Settings',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppColors.inkPrimary,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Manage your account display identity and authentication credentials.',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.inkSecondary,
                  ),
                ),
                const SizedBox(height: 24),

                // Card 1: Profile Information
                _buildProfileCard(user),
                const SizedBox(height: 24),

                // Card 2: Security & Password
                _buildPasswordCard(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProfileCard(UserProfile? user) {
    final role = user?.role ?? UserRole.recoveryOfficer;
    final roleColor = _getRoleColor(role);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _profileFormKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.person_outline, color: AppColors.brandPrimary, size: 22),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Profile Information',
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: AppColors.inkPrimary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: roleColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: roleColor.withValues(alpha: 0.4)),
                    ),
                    child: Text(
                      role.displayName,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: roleColor,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Email Field (Read-only)
              TextFormField(
                initialValue: user?.email ?? '',
                readOnly: true,
                decoration: InputDecoration(
                  labelText: 'Email Address',
                  prefixIcon: const Icon(Icons.email_outlined, size: 20),
                  helperText: 'Email address cannot be modified',
                  filled: true,
                  fillColor: const Color(0xFFF1F5F9),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: AppColors.borderSubtle),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Full Name Field (Editable)
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'Full Name',
                  hintText: 'e.g. John Doe',
                  prefixIcon: const Icon(Icons.badge_outlined, size: 20),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: AppColors.borderSubtle),
                  ),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Please enter your full name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),

              Align(
                alignment: Alignment.centerRight,
                child: ElevatedButton.icon(
                  onPressed: _isSavingProfile ? null : _saveProfile,
                  icon: _isSavingProfile
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.inkWhite),
                        )
                      : const Icon(Icons.check, size: 18),
                  label: const Text('Save Changes'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.brandPrimary,
                    foregroundColor: AppColors.inkWhite,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPasswordCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _passwordFormKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.lock_outline, color: AppColors.brandPrimary, size: 22),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Security & Password',
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: AppColors.inkPrimary,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              const Text(
                'Ensure your account uses a secure password with at least 8 characters, numbers, and mixed case letters.',
                style: TextStyle(fontSize: 13, color: AppColors.inkSecondary),
              ),
              const SizedBox(height: 20),

              // New Password Field
              TextFormField(
                controller: _newPasswordController,
                obscureText: _obscureNewPassword,
                decoration: InputDecoration(
                  labelText: 'New Password',
                  prefixIcon: const Icon(Icons.key_outlined, size: 20),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureNewPassword ? Icons.visibility_off : Icons.visibility,
                      size: 20,
                    ),
                    onPressed: () => setState(() => _obscureNewPassword = !_obscureNewPassword),
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: AppColors.borderSubtle),
                  ),
                ),
                validator: (val) {
                  if (val == null || val.isEmpty) {
                    return 'Please enter a new password';
                  }
                  if (val.length < 8) {
                    return 'Password must be at least 8 characters long';
                  }
                  if (!val.contains(RegExp(r'[0-9]'))) {
                    return 'Password must contain at least one number';
                  }
                  if (!val.contains(RegExp(r'[A-Za-z]'))) {
                    return 'Password must contain letters';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Confirm Password Field
              TextFormField(
                controller: _confirmPasswordController,
                obscureText: _obscureConfirmPassword,
                decoration: InputDecoration(
                  labelText: 'Confirm New Password',
                  prefixIcon: const Icon(Icons.check_circle_outline, size: 20),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureConfirmPassword ? Icons.visibility_off : Icons.visibility,
                      size: 20,
                    ),
                    onPressed: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: AppColors.borderSubtle),
                  ),
                ),
                validator: (val) {
                  if (val == null || val.isEmpty) {
                    return 'Please confirm your new password';
                  }
                  if (val != _newPasswordController.text) {
                    return 'Passwords do not match';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),

              Align(
                alignment: Alignment.centerRight,
                child: ElevatedButton.icon(
                  onPressed: _isSavingPassword ? null : _changePassword,
                  icon: _isSavingPassword
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.inkWhite),
                        )
                      : const Icon(Icons.security, size: 18),
                  label: const Text('Change Password'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.brandPrimary,
                    foregroundColor: AppColors.inkWhite,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
