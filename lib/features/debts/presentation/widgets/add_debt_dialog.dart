import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../customers/domain/customer.dart';
import '../../../customers/data/customer_repository.dart';
import '../../../auth/presentation/auth_controller.dart';
import '../debt_controller.dart';

class AddDebtDialog extends ConsumerStatefulWidget {
  const AddDebtDialog({super.key});

  @override
  ConsumerState<AddDebtDialog> createState() => _AddDebtDialogState();
}

class _AddDebtDialogState extends ConsumerState<AddDebtDialog> {
  final _formKey = GlobalKey<FormState>();

  final _referenceNumberController = TextEditingController();
  final _principalAmountController = TextEditingController();
  final _selectedCustomerIdController = TextEditingController();
  final _selectedCustomerNameController = TextEditingController();

  DateTime? _originDate;
  DateTime? _dueDate;

  List<Customer> _customers = [];
  bool _isLoadingCustomers = true;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _loadCustomers();
  }

  Future<void> _loadCustomers() async {
    final repo = ref.read(customerRepositoryProvider);
    try {
      final authProfile = ref.read(authControllerProvider).value;
      final tenantId = authProfile?.tenantId ?? 'a0000000-0000-0000-0000-000000000001';
      final customers = await repo.fetchCustomers(tenantId);
      if (mounted) {
        setState(() {
          _customers = customers;
          _isLoadingCustomers = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isLoadingCustomers = false);
      }
    }
  }

  @override
  void dispose() {
    _referenceNumberController.dispose();
    _principalAmountController.dispose();
    _selectedCustomerIdController.dispose();
    _selectedCustomerNameController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCustomerIdController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a customer'),
          backgroundColor: AppColors.accentDanger,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    if (_originDate == null || _dueDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select origin date and due date'),
          backgroundColor: AppColors.accentDanger,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final principal = int.tryParse(_principalAmountController.text.replaceAll(RegExp(r'[^\d]'), '')) ?? 0;

      await ref.read(debtControllerProvider.notifier).createDebt(
            customerId: _selectedCustomerIdController.text,
            referenceNumber: _referenceNumberController.text,
            principalAmountCents: principal,
            originDate: _originDate!,
            dueDate: _dueDate!,
          );

      if (mounted) {
        Navigator.of(context).pop(true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Debt record "${_referenceNumberController.text}" created successfully'),
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
            content: Text('Failed to create debt record: $e'),
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
          Icon(Icons.add_circle_outline, color: AppColors.brandPrimary),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Create Debt Record',
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
        constraints: const BoxConstraints(maxWidth: 520),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_isLoadingCustomers)
                  const SizedBox(
                    height: 200,
                    child: Center(child: CircularProgressIndicator()),
                  )
                else ...[
                  DropdownButtonFormField<String>(
                    initialValue: _selectedCustomerIdController.text.isNotEmpty
                        ? _selectedCustomerIdController.text
                        : null,
                    items: _customers.map((c) {
                      return DropdownMenuItem<String>(
                        value: c.id,
                        child: Text(
                          '${c.fullName} (${c.phoneNumber})',
                          overflow: TextOverflow.ellipsis,
                        ),
                      );
                    }).toList(),
                    isExpanded: true,
                    onChanged: (value) {
                      if (value == null) return;
                      final selectedId = value;
                      final customer = _customers.firstWhere((c) => c.id == selectedId);
                      setState(() {
                        _selectedCustomerIdController.text = selectedId;
                        _selectedCustomerNameController.text = customer.fullName;
                      });
                    },
                    decoration: InputDecoration(
                      labelText: 'Customer *',
                      hintText: 'Select a customer from the directory',
                      prefixIcon: const Icon(Icons.person_outlined, size: 20),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: AppColors.borderSubtle),
                      ),
                    ),
                    validator: (val) {
                      if (val == null || val.isEmpty) {
                        return 'Please select a customer';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                ],
                TextFormField(
                  controller: _referenceNumberController,
                  decoration: InputDecoration(
                    labelText: 'Reference Number *',
                    hintText: 'e.g. DR-2001',
                    prefixIcon: const Icon(Icons.label_outlined, size: 20),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: AppColors.borderSubtle),
                    ),
                  ),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) {
                      return 'Please enter a reference number';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                TextFormField(
                  controller: _principalAmountController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Principal Amount *',
                    hintText: 'e.g. 1,500.00',
                    prefixIcon: const Icon(Icons.attach_money, size: 20),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: AppColors.borderSubtle),
                    ),
                  ),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) {
                      return 'Please enter principal amount';
                    }
                    final cleaned = val.replaceAll(RegExp(r'[^\d.]'), '');
                    final amount = double.tryParse(cleaned);
                    if (amount == null || amount <= 0) {
                      return 'Please enter a valid positive amount';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                ListTile(
                  leading: const Icon(Icons.calendar_today_outlined, size: 20),
                  title: const Text('Origin Date *'),
                  subtitle: Text(
                    _originDate != null
                        ? '${_originDate!.year}-${_originDate!.month.toString().padLeft(2, '0')}-${_originDate!.day.toString().padLeft(2, '0')}'
                        : 'Select origin date',
                    style: TextStyle(
                      color: _originDate == null ? AppColors.inkSecondary : AppColors.inkPrimary,
                    ),
                  ),
                  trailing: const Icon(Icons.chevron_right, size: 18),
                  onTap: () => _pickDate(context, isOrigin: true),
                ),
                const Divider(height: 1),

                ListTile(
                  leading: const Icon(Icons.event_outlined, size: 20),
                  title: const Text('Due Date *'),
                  subtitle: Text(
                    _dueDate != null
                        ? '${_dueDate!.year}-${_dueDate!.month.toString().padLeft(2, '0')}-${_dueDate!.day.toString().padLeft(2, '0')}'
                        : 'Select due date',
                    style: TextStyle(
                      color: _dueDate == null ? AppColors.inkSecondary : AppColors.inkPrimary,
                    ),
                  ),
                  trailing: const Icon(Icons.chevron_right, size: 18),
                  onTap: () => _pickDate(context, isOrigin: false),
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
              : const Text('Create Debt Record'),
        ),
      ],
    );
  }

  Future<void> _pickDate(BuildContext context, {required bool isOrigin}) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _originDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
    );
    if (picked != null) {
      setState(() {
        if (isOrigin) {
          _originDate = picked;
        } else {
          _dueDate = picked;
        }
      });
    }
  }
}