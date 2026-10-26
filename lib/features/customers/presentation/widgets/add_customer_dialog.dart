import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../customer_controller.dart';

class AddCustomerDialog extends ConsumerStatefulWidget {
  const AddCustomerDialog({super.key});

  @override
  ConsumerState<AddCustomerDialog> createState() => _AddCustomerDialogState();
}

class _AddCustomerDialogState extends ConsumerState<AddCustomerDialog> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _secondaryPhoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _nationalIdController = TextEditingController();
  final _addressController = TextEditingController();

  bool _isSubmitting = false;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _secondaryPhoneController.dispose();
    _emailController.dispose();
    _nationalIdController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    try {
      await ref.read(customerControllerProvider.notifier).createCustomer(
            fullName: _nameController.text,
            phoneNumber: _phoneController.text,
            secondaryPhone: _secondaryPhoneController.text,
            email: _emailController.text,
            nationalId: _nationalIdController.text,
            address: _addressController.text,
          );

      if (mounted) {
        Navigator.of(context).pop(true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Customer "${_nameController.text}" registered successfully'),
            backgroundColor: AppColors.accentSuccess,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to register customer: $e'),
            backgroundColor: AppColors.accentDanger,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.surfaceRaised,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppColors.borderSubtle),
      ),
      title: const Row(
        children: [
          Icon(Icons.person_add_alt_1_outlined, color: AppColors.brandPrimary),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Register New Customer',
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.inkPrimary,
              ),
            ),
          ),
        ],
      ),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Full Name
                TextFormField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    labelText: 'Full Name *',
                    hintText: 'e.g. Marcus Vance',
                    prefixIcon: const Icon(Icons.person_outline, size: 20),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: AppColors.borderSubtle),
                    ),
                  ),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) {
                      return 'Please enter customer full name';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Primary Phone
                TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: InputDecoration(
                    labelText: 'Primary Phone Number *',
                    hintText: 'e.g. +1-555-0101',
                    prefixIcon: const Icon(Icons.phone_outlined, size: 20),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: AppColors.borderSubtle),
                    ),
                  ),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) {
                      return 'Please enter primary phone number';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Secondary Phone
                TextFormField(
                  controller: _secondaryPhoneController,
                  keyboardType: TextInputType.phone,
                  decoration: InputDecoration(
                    labelText: 'Secondary Phone (Optional)',
                    hintText: 'e.g. +1-555-0102',
                    prefixIcon: const Icon(Icons.phone_iphone_outlined, size: 20),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: AppColors.borderSubtle),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Email
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    labelText: 'Email Address (Optional)',
                    hintText: 'e.g. customer@example.com',
                    prefixIcon: const Icon(Icons.email_outlined, size: 20),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: AppColors.borderSubtle),
                    ),
                  ),
                  validator: (val) {
                    if (val != null && val.trim().isNotEmpty && !val.contains('@')) {
                      return 'Please enter a valid email address';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // National ID / Tax ID
                TextFormField(
                  controller: _nationalIdController,
                  decoration: InputDecoration(
                    labelText: 'National / Tax ID (Optional)',
                    hintText: 'e.g. NAT-99881',
                    prefixIcon: const Icon(Icons.badge_outlined, size: 20),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: AppColors.borderSubtle),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Physical Address
                TextFormField(
                  controller: _addressController,
                  maxLines: 2,
                  decoration: InputDecoration(
                    labelText: 'Physical Address (Optional)',
                    hintText: 'e.g. 742 Evergreen Terrace, Springfield',
                    prefixIcon: const Icon(Icons.location_on_outlined, size: 20),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: AppColors.borderSubtle),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSubmitting ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel', style: TextStyle(color: AppColors.inkSecondary)),
        ),
        ElevatedButton(
          onPressed: _isSubmitting ? null : _submit,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.brandPrimary,
            foregroundColor: AppColors.inkWhite,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: _isSubmitting
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.inkWhite),
                )
              : const Text('Register Customer'),
        ),
      ],
    );
  }
}
