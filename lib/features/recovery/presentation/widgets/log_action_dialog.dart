import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_colors.dart';

class LogActionDialog extends ConsumerStatefulWidget {
  final String debtId;
  final String debtCustomerId;
  final String? customerName;

  const LogActionDialog({
    super.key,
    required this.debtId,
    required this.debtCustomerId,
    this.customerName,
  });

  @override
  ConsumerState<LogActionDialog> createState() => _LogActionDialogState();
}
class _LogActionDialogState extends ConsumerState<LogActionDialog> {
  final _formKey = GlobalKey<FormState>();
  final _notesController = TextEditingController();
  DateTime? _followUpDate;
  int? _promisedAmountCents;
  String _selectedChannel = 'call';
  String _selectedOutcome = 'No Response';

  static const _channelLabels = {
    'call': 'Call',
    'field_visit': 'Visit',
    'email': 'Email',
    'sms': 'SMS',
  };

  static const _outcomeOptions = <String>[
    'No Response',
    'Promised to Pay',
    'Payment Received',
    'Left Message',
    'Callback Requested',
    'Escalated to Supervisor',
    'Disputed Balance',
  ];

  // _isSubmitting was removed as it was unused

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }
@override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.surfaceRaised,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppColors.borderSubtle),
      ),
      title: Row(
        children: [
          const Icon(Icons.phone_callback_outlined, color: AppColors.accentSuccess),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              widget.customerName != null ? 'Log Action – ${widget.customerName}' : 'Log Action',
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.inkPrimary),
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
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text('Contact Channel', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.inkPrimary)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: _channelKeys().map((key) => _buildChannelChip(key, _channelLabels[key]!)).toList(),
                ),
                const SizedBox(height: 16),
                _buildOutcomeDropdown(),
                const SizedBox(height: 16),
                _buildFollowUpDateField(),
                const SizedBox(height: 16),
                _buildPromisedAmountField(),
                const SizedBox(height: 16),
                _buildNotesField(),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => _logActionAndPop(),
          child: const Text('Log Action'),
        ),
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Close')),
      ],
    );
  }
List<String> _channelKeys() => ['call', 'field_visit', 'email', 'sms'];

  Widget _buildChannelChip(String value, String label) {
    final isSelected = _selectedChannel == value;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) => setState(() => _selectedChannel = value),
      selectedColor: isSelected ? AppColors.brandPrimary : AppColors.surfaceRaised,
      checkmarkColor: AppColors.inkWhite,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      side: BorderSide(color: isSelected ? AppColors.brandPrimary : AppColors.borderSubtle),
    );
  }

  Widget _buildOutcomeDropdown() {
    return InputDecorator(
      decoration: const InputDecoration(
        labelText: 'Outcome',
        labelStyle: TextStyle(fontSize: 12),
        border: OutlineInputBorder(),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedOutcome,
          isDense: true,
          onChanged: (String? newValue) {
            setState(() => _selectedOutcome = newValue!);
          },
          items: _outcomeOptions.map<DropdownMenuItem<String>>((String value) {
            return DropdownMenuItem<String>(
              value: value,
              child: Text(value),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildFollowUpDateField() {
    return InputDecorator(
      decoration: const InputDecoration(
        labelText: 'Follow-Up Date',
        labelStyle: TextStyle(fontSize: 12),
        border: OutlineInputBorder(),
        hintText: 'Select a date',
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Expanded(
            child: TextButton(
              onPressed: _pickFollowUpDate,
              child: Text(
                _followUpDate == null
                  ? 'Select Date'
                  : '${_followUpDate!.day}/${_followUpDate!.month}/${_followUpDate!.year}',
                style: TextStyle(
                  color: _followUpDate == null ? AppColors.inkSecondary : AppColors.inkPrimary,
                  fontSize: 14,
                ),
              ),
            ),
          ),
          const SizedBox(width: 4),
          Text(
            _followUpDate != null ? '📅' : '',
            style: const TextStyle(fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildPromisedAmountField() {
    return InputDecorator(
      decoration: const InputDecoration(
        labelText: 'Promised Amount (cents)',
        labelStyle: TextStyle(fontSize: 12),
        border: OutlineInputBorder(),
        hintText: 'e.g. 25000',
      ),
      child: TextFormField(
        decoration: const InputDecoration(
          isDense: true,
          hintText: '0',
          border: InputBorder.none,
        ),
        onChanged: (value) {
          final n = int.tryParse(value.replaceAll(RegExp(r'[^\d]'), ''));
          setState(() => _promisedAmountCents = n);
        },
        keyboardType: TextInputType.numberWithOptions(decimal: false),
      ),
    );
  }

  Widget _buildNotesField() {
    return InputDecorator(
      decoration: const InputDecoration(
        labelText: 'Notes',
        labelStyle: TextStyle(fontSize: 12),
        border: OutlineInputBorder(),
      ),
      child: TextFormField(
        controller: _notesController,
        decoration: const InputDecoration(
          border: InputBorder.none,
          isDense: true,
        ),
        maxLines: 3,
      ),
    );
  }

  Future<void> _pickFollowUpDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _followUpDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null && picked != _followUpDate) {
      setState(() => _followUpDate = picked);
    }
  }

  Map<String, dynamic> _logActionAndPop() {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      return {
        'channel': _selectedChannel,
        'outcome': _selectedOutcome,
        'followUpDate': _followUpDate,
        'promisedAmountCents': _promisedAmountCents,
        'notes': _notesController.text.trim(),
      };
    }
    return {};
  }
}