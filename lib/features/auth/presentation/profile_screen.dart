import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/theming/theme_settings_provider.dart';
import '../data/php_auth_session.dart';
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
  late final TextEditingController _phoneController;
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  String _phone = '';
  String? _photoPath;
  File? _pickedImage;

  bool _isLoading = true;
  bool _isSavingProfile = false;
  bool _isChangingPassword = false;
  bool _obscureCurrent = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;

  @override
  void initState() {
    super.initState();
    _loadAccount();
  }

  Future<void> _loadAccount() async {
    final user = ref.read(authControllerProvider).value;
    if (user == null) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
      return;
    }
    _nameController = TextEditingController(text: user.fullName);
    final repo = ref.read(authControllerProvider.notifier);
    final phone = await repo.getCurrentPhone() ?? '';
    final photo = await repo.getCurrentProfilePhoto();
    if (mounted) {
      setState(() {
        _phone = phone;
        _photoPath = photo;
        _phoneController = TextEditingController(text: phone);
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final picked = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
      if (picked == null) {
        return; // user cancelled
      }
      final file = File(picked.path);
      final repo = ref.read(authControllerProvider.notifier);
      await repo.updateProfilePhoto(photoPath: picked.path);
      if (mounted) {
        setState(() {
          _photoPath = picked.path;
          _pickedImage = file;
        });
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile photo updated'),
            backgroundColor: AppColors.accentSuccess,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update photo: $e'),
            backgroundColor: AppColors.accentDanger,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _saveProfile() async {
    if (!_profileFormKey.currentState!.validate()) {
      return;
    }
    setState(() => _isSavingProfile = true);
    try {
      await ref
          .read(authControllerProvider.notifier)
          .updateProfile(
            fullName: _nameController.text.trim(),
            phone: _phoneController.text.trim(),
          );
      _phone = _phoneController.text.trim();
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
    if (!_passwordFormKey.currentState!.validate()) {
      return;
    }
    setState(() => _isChangingPassword = true);
    try {
      await ref
          .read(authControllerProvider.notifier)
          .changePassword(
            currentPassword: _currentPasswordController.text,
            newPassword: _newPasswordController.text,
          );
      _currentPasswordController.clear();
      _newPasswordController.clear();
      _confirmPasswordController.clear();
      if (mounted) {
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
        setState(() => _isChangingPassword = false);
      }
    }
  }

  Future<void> _signOut() async {
    await ref.read(authControllerProvider.notifier).signOut();
    ref.read(phpAuthSessionProvider.notifier).clear();
    if (!mounted) {
      return;
    }
    context.go('/login');
  }

  Widget _buildHeader(UserProfile user) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final imageProvider = _pickedImage != null
        ? FileImage(_pickedImage!)
        : (_photoPath != null ? FileImage(File(_photoPath!)) : null);

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(
          color: isDark
              ? AppColors.borderGlassDark
              : AppColors.borderGlassLight,
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: 110,
                  height: 110,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isDark
                        ? AppColors.surfaceDarkCard
                        : AppColors.cardBgColor(isDark),
                    border: Border.all(
                      color: AppColors.brandPrimary.withValues(alpha: 0.35),
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.brandPrimary.withValues(alpha: 0.18),
                        blurRadius: 24,
                        offset: const Offset(0, 8),
                      ),
                    ],
                    image: imageProvider != null
                        ? DecorationImage(
                            image: imageProvider,
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
                  child: imageProvider == null
                      ? const Icon(
                          Icons.person_outline,
                          size: 48,
                          color: AppColors.brandPrimary,
                        )
                      : null,
                ),
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: const BoxDecoration(
                      color: AppColors.brandPrimary,
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: const Icon(
                        Icons.camera_alt_outlined,
                        color: Colors.white,
                        size: 20,
                      ),
                      onPressed: _isLoading ? null : _pickImage,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      splashRadius: 20,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              user.fullName.isNotEmpty ? user.fullName : 'Staff Member',
              style: const TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.4,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              user.email,
              style: TextStyle(
                fontSize: 14,
                color: isDark ? Colors.white70 : AppColors.inkSecondaryColor(isDark),
              ),
            ),
            const SizedBox(height: 14),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: _roleColor(user.role).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: _roleColor(user.role).withValues(alpha: 0.45),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    user.role.displayName,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: _roleColor(user.role),
                      letterSpacing: 0.4,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                _detailRow(
                  Icons.phone_outlined,
                  _phone.isNotEmpty ? _phone : 'No phone number',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _roleColor(UserRole role) {
    switch (role) {
      case UserRole.admin:
        return AppColors.accentDanger;
      case UserRole.financeOfficer:
        return AppColors.accentSuccess;
      case UserRole.recoveryOfficer:
        return AppColors.brandPrimary;
    }
  }

  Widget _detailRow(IconData icon, String text) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 16,
          color: isDark ? Colors.white60 : AppColors.inkMutedColor(isDark),
        ),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 13,
              color: isDark ? Colors.white70 : AppColors.inkSecondaryColor(isDark),
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _sectionTitle(BuildContext context, String text) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 10),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 18,
            decoration: BoxDecoration(
              color: AppColors.brandPrimary,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 10),
          Text(
            text,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEditProfileCard(UserProfile user) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(
          color: isDark
              ? AppColors.borderGlassDark
              : AppColors.borderGlassLight,
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _profileFormKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Edit Profile',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 16),
              TextFormField(
                key: const Key('profile_full_name_field'),
                controller: _nameController,
                textInputAction: TextInputAction.next,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) {
                    return 'Please enter your full name';
                  }
                  if (v.trim().length < 2) {
                    return 'Name must be at least 2 characters';
                  }
                  return null;
                },
                decoration: InputDecoration(
                  labelText: 'Full Name',
                  hintText: 'e.g. Sarah Officer',
                  prefixIcon: const Icon(Icons.person_outlined, size: 20),
                  filled: true,
                  fillColor: isDark
                      ? AppColors.surfaceDarkCard
                      : AppColors.cardBgColor(isDark),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                ),
              ),
              const SizedBox(height: 14),
              TextFormField(
                key: const Key('profile_phone_field'),
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                textInputAction: TextInputAction.done,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) {
                    return 'Please enter your phone number';
                  }
                  final digits = v.replaceAll(RegExp(r'\D'), '');
                  if (digits.length < 7) {
                    return 'Enter a valid phone number';
                  }
                  return null;
                },
                decoration: InputDecoration(
                  labelText: 'Phone Number',
                  hintText: 'e.g. +1 555 000 0000',
                  prefixIcon: const Icon(Icons.phone_outlined, size: 20),
                  filled: true,
                  fillColor: isDark
                      ? AppColors.surfaceDarkCard
                      : AppColors.cardBgColor(isDark),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: _isSavingProfile ? null : _saveProfile,
                  icon: _isSavingProfile
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.save_outlined, size: 18),
                  label: const Text(
                    'Save Changes',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.brandPrimary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
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

  Widget _buildAccountCard(UserProfile user) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(
          color: isDark
              ? AppColors.borderGlassDark
              : AppColors.borderGlassLight,
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Account Information',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 16),
            _accountRow(Icons.email_outlined, 'Email Address', user.email),
            const SizedBox(height: 12),
            _accountRow(
              Icons.person_outlined,
              'Username',
              user.email.split('@').first,
            ),
            const SizedBox(height: 12),
            _accountRow(
              Icons.phone_outlined,
              'Phone Number',
              _phone.isNotEmpty ? _phone : 'Not provided',
            ),
            const SizedBox(height: 12),
            _accountRow(
              Icons.security_outlined,
              'User Role',
              user.role.displayName,
            ),
            const SizedBox(height: 12),
            _accountRow(
              Icons.lock_outline,
              'Account Status',
              user.isActive ? 'Active' : 'Inactive',
            ),
          ],
        ),
      ),
    );
  }

  Widget _accountRow(IconData icon, String label, String value) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: AppColors.brandPrimary),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white70 : AppColors.inkSecondaryColor(isDark),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  fontSize: 14,
                  color: isDark ? Colors.white : AppColors.inkPrimaryColor(isDark),
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSecurityCard() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(
          color: isDark
              ? AppColors.borderGlassDark
              : AppColors.borderGlassLight,
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _passwordFormKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.lock_outline,
                    color: AppColors.accentDanger,
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    'Change Password',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                'Your current password is required to confirm your identity.',
                style: TextStyle(
                  fontSize: 12.5,
                  color: isDark ? Colors.white60 : AppColors.inkSecondaryColor(isDark),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                key: const Key('profile_current_password_field'),
                controller: _currentPasswordController,
                obscureText: _obscureCurrent,
                textInputAction: TextInputAction.next,
                validator: (v) {
                  if (v == null || v.isEmpty) {
                    return 'Please enter your current password';
                  }
                  return null;
                },
                decoration: InputDecoration(
                  labelText: 'Current Password',
                  prefixIcon: const Icon(Icons.lock_outlined, size: 20),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureCurrent ? Icons.visibility_off : Icons.visibility,
                      size: 20,
                    ),
                    onPressed: () =>
                        setState(() => _obscureCurrent = !_obscureCurrent),
                  ),
                  filled: true,
                  fillColor: isDark
                      ? AppColors.surfaceDarkCard
                      : AppColors.cardBgColor(isDark),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                ),
              ),
              const SizedBox(height: 14),
              TextFormField(
                key: const Key('profile_new_password_field'),
                controller: _newPasswordController,
                obscureText: _obscureNew,
                textInputAction: TextInputAction.next,
                validator: (v) {
                  if (v == null || v.isEmpty) {
                    return 'Please enter a new password';
                  }
                  if (v.length < 6) {
                    return 'Password must be at least 6 characters';
                  }
                  return null;
                },
                decoration: InputDecoration(
                  labelText: 'New Password',
                  prefixIcon: const Icon(Icons.key_outlined, size: 20),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureNew ? Icons.visibility_off : Icons.visibility,
                      size: 20,
                    ),
                    onPressed: () => setState(() => _obscureNew = !_obscureNew),
                  ),
                  filled: true,
                  fillColor: isDark
                      ? AppColors.surfaceDarkCard
                      : AppColors.cardBgColor(isDark),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                ),
              ),
              const SizedBox(height: 14),
              TextFormField(
                key: const Key('profile_confirm_password_field'),
                controller: _confirmPasswordController,
                obscureText: _obscureConfirm,
                textInputAction: TextInputAction.done,
                validator: (v) {
                  if (v == null || v.isEmpty) {
                    return 'Please confirm your new password';
                  }
                  if (v != _newPasswordController.text) {
                    return 'Passwords do not match';
                  }
                  return null;
                },
                decoration: InputDecoration(
                  labelText: 'Confirm New Password',
                  prefixIcon: const Icon(Icons.check_circle_outline, size: 20),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureConfirm ? Icons.visibility_off : Icons.visibility,
                      size: 20,
                    ),
                    onPressed: () =>
                        setState(() => _obscureConfirm = !_obscureConfirm),
                  ),
                  filled: true,
                  fillColor: isDark
                      ? AppColors.surfaceDarkCard
                      : AppColors.cardBgColor(isDark),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: _isChangingPassword ? null : _changePassword,
                  icon: _isChangingPassword
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.security, size: 18),
                  label: const Text(
                    'Change Password',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accentDanger,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
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

  Widget _buildNotificationsCard() {
    final settings = ref.watch(notificationSettingsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(
          color: isDark
              ? AppColors.borderGlassDark
              : AppColors.borderGlassLight,
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Notification Preferences',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 10),
            Text(
              'Choose which notifications you would like to receive.',
              style: TextStyle(
                fontSize: 12.5,
                color: isDark ? Colors.white60 : AppColors.inkSecondaryColor(isDark),
              ),
            ),
            const SizedBox(height: 16),
            _switchTile(
              icon: Icons.email_outlined,
              title: 'Email notifications',
              subtitle: 'Receive account and recovery updates by email.',
              value: settings.email,
              onChanged: (v) =>
                  ref.read(notificationSettingsProvider.notifier).setEmail(v),
            ),
            const SizedBox(height: 12),
            _switchTile(
              icon: Icons.sms_outlined,
              title: 'SMS notifications',
              subtitle: 'Receive payment reminders by text message.',
              value: settings.sms,
              onChanged: (v) =>
                  ref.read(notificationSettingsProvider.notifier).setSms(v),
            ),
            const SizedBox(height: 12),
            _switchTile(
              icon: Icons.notifications_outlined,
              title: 'Push notifications',
              subtitle: 'Receive real-time alerts on your device.',
              value: settings.push,
              onChanged: (v) =>
                  ref.read(notificationSettingsProvider.notifier).setPush(v),
            ),
          ],
        ),
      ),
    );
  }

  Widget _switchTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Card(
      color: isDark ? AppColors.surfaceDarkCard : AppColors.cardBgColor(isDark),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isDark
              ? AppColors.borderGlassDark
              : AppColors.borderGlassLight,
          width: 1,
        ),
      ),
      child: SwitchListTile(
        title: Text(
          title,
          style: TextStyle(
            fontSize: 14.5,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white : AppColors.inkPrimaryColor(isDark),
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            fontSize: 12.5,
            color: isDark ? Colors.white60 : AppColors.inkSecondaryColor(isDark),
          ),
        ),
        secondary: Icon(icon, color: AppColors.brandPrimary, size: 22),
        value: value,
        onChanged: onChanged,
        activeThumbColor: AppColors.brandPrimary,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        controlAffinity: ListTileControlAffinity.trailing,
      ),
    );
  }

  Widget _buildAppearanceCard() {
    final themeMode = ref.watch(themeModeProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(
          color: isDark
              ? AppColors.borderGlassDark
              : AppColors.borderGlassLight,
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Appearance & Theme',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 10),
            Text(
              'Choose how the app looks. Your choice is saved and applied across the app.',
              style: TextStyle(
                fontSize: 12.5,
                color: isDark ? Colors.white60 : AppColors.inkSecondaryColor(isDark),
              ),
            ),
            const SizedBox(height: 16),
            for (var i = 0; i < AppThemeMode.values.length; i++) ...[
              if (i > 0) const SizedBox(height: 10),
              Builder(
                builder: (context) {
                  final mode = AppThemeMode.values[i];
                  final selected = themeMode == mode;
                  return _themeTile(
                    icon: mode.icon,
                    title: mode.label,
                    selected: selected,
                    onTap: () =>
                        ref.read(themeModeProvider.notifier).setThemeMode(mode),
                  );
                },
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _themeTile({
    required IconData icon,
    required String title,
    required bool selected,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final Color tileFill = selected
        ? AppColors.brandPrimary
        : (isDark ? Colors.black : Colors.white);
    final Color tileBorder = selected
        ? AppColors.brandPrimary
        : (isDark ? AppColors.borderDark : Colors.black);
    final Color contentColor = selected
        ? Colors.black
        : (isDark ? Colors.white : AppColors.inkPrimaryColor(isDark));
    final Color chipFill = selected
        ? AppColors.brandPrimary
        : (isDark ? AppColors.surfaceDarkCard : Colors.white);
    final Color chipBorder = selected
        ? AppColors.brandPrimary
        : (isDark ? AppColors.borderDark : Colors.black);
    final Color chipIconColor = selected ? Colors.black : AppColors.brandPrimary;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: tileFill,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: tileBorder, width: 1.5),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: chipFill,
                  borderRadius: BorderRadius.circular(11),
                  border: Border.all(color: chipBorder, width: 1),
                ),
                child: Icon(icon, size: 20, color: chipIconColor),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 14.5,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                    color: contentColor,
                  ),
                ),
              ),
              if (selected)
                const Icon(
                  Icons.check_circle,
                  color: Colors.black,
                  size: 20,
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHelpCard() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(
          color: isDark
              ? AppColors.borderGlassDark
              : AppColors.borderGlassLight,
          width: 1,
        ),
      ),
      child: Column(
        children: [
          _menuTile(
            icon: Icons.help_center_outlined,
            title: 'Help & Support',
            subtitle: 'Get assistance with your account.',
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Opening Help & Support...')),
              );
            },
          ),
          const Divider(height: 1),
          _menuTile(
            icon: Icons.description_outlined,
            title: 'Terms of Service',
            subtitle: 'Review the terms of use.',
            onTap: () {
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text('Terms of Service')));
            },
          ),
        ],
      ),
    );
  }

  Widget _buildAboutCard() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(
          color: isDark
              ? AppColors.borderGlassDark
              : AppColors.borderGlassLight,
          width: 1,
        ),
      ),
      child: Column(
        children: [
          _menuTile(
            icon: Icons.info_outline,
            title: 'About Debit Recovery',
            subtitle: 'Version 1.0.0 &bull; Financial management',
            onTap: () {
              showAboutDialog(
                context: context,
                applicationName: 'Debit Recovery',
                applicationVersion: '1.0.0',
                applicationIcon: const Icon(
                  Icons.account_balance_wallet,
                  color: AppColors.brandPrimary,
                  size: 32,
                ),
              );
            },
          ),
          const Divider(height: 1),
          _menuTile(
            icon: Icons.privacy_tip_outlined,
            title: 'Privacy Policy',
            subtitle: 'How we handle your data.',
            onTap: () {
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text('Privacy Policy')));
            },
          ),
        ],
      ),
    );
  }

  Widget _menuTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      leading: Icon(icon, color: AppColors.brandPrimary, size: 22),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 14.5,
          fontWeight: FontWeight.w600,
          color: isDark ? Colors.white : AppColors.inkPrimaryColor(isDark),
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          fontSize: 12.5,
          color: isDark ? Colors.white60 : AppColors.inkSecondaryColor(isDark),
        ),
      ),
      trailing: Icon(
        Icons.chevron_right,
        size: 20,
        color: AppColors.inkMutedColor(isDark),
      ),
      onTap: onTap,
    );
  }

  Widget _buildLogoutButton() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
      child: SizedBox(
        width: double.infinity,
        height: 52,
        child: OutlinedButton.icon(
          onPressed: _signOut,
          icon: const Icon(Icons.logout, size: 20),
          label: const Text(
            'Logout',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
          ),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.accentDanger,
            side: BorderSide(
              color: AppColors.accentDanger.withValues(alpha: 0.5),
              width: 1.5,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final user = ref.watch(authControllerProvider).value;
    if (user == null) {
      return const Scaffold(body: Center(child: Text('Not authenticated')));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        centerTitle: false,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/dashboard');
            }
          },
        ),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 700),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildHeader(user),
                const SizedBox(height: 24),
                _sectionTitle(context, 'Account'),
                _buildEditProfileCard(user),
                const SizedBox(height: 20),
                _buildAccountCard(user),
                const SizedBox(height: 20),
                _sectionTitle(context, 'Security'),
                _buildSecurityCard(),
                const SizedBox(height: 20),
                _sectionTitle(context, 'Preferences'),
                _buildNotificationsCard(),
                const SizedBox(height: 20),
                _buildAppearanceCard(),
                const SizedBox(height: 20),
                _sectionTitle(context, 'Support'),
                _buildHelpCard(),
                const SizedBox(height: 16),
                _buildAboutCard(),
                const SizedBox(height: 26),
                _buildLogoutButton(),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
