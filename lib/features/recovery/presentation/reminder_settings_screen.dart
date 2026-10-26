import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../domain/reminder_settings.dart';
import 'reminder_controller.dart';

class ReminderSettingsScreen extends ConsumerWidget {
  const ReminderSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsAsync = ref.watch(reminderSettingsProvider);

    return Scaffold(
      backgroundColor: AppColors.surfaceBase,
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Reminder Settings', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.inkPrimary)),
            const SizedBox(height: 4),
            Text('Configure email and SMS payment reminders for overdue accounts',
                style: TextStyle(fontSize: 13, color: AppColors.inkSecondary)),
            const SizedBox(height: 24),
            Expanded(
              child: settingsAsync.when(
                data: (settings) => _SettingsForm(settings: settings, ref: ref),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(child: Text('Error: $e')),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
class _SettingsFormState extends State<_SettingsForm> {
  late final _emailOffsetController = TextEditingController(text: widget.settings.emailOffsetDays.join(', '));
  late final _smsOffsetController = TextEditingController(text: widget.settings.smsOffsetDays.join(', '));
  late final _messageTemplateController = TextEditingController(text: widget.settings.messageTemplate);
  late bool _emailEnabled = widget.settings.emailEnabled;
  late bool _smsEnabled = widget.settings.smsEnabled;
  bool _isSaving = false;

  List<int> _parseOffsets(String text) {
    return text
        .split(',')
        .where((e) => e.trim().isNotEmpty)
        .map((e) => int.tryParse(e.trim()) ?? 0)
        .where((e) => e > 0)
        .toList();
  }

  @override
  void dispose() {
    _emailOffsetController.dispose();
    _smsOffsetController.dispose();
    _messageTemplateController.dispose();
    super.dispose();
  }

  Future<void> _saveSettings() async {
    setState(() => _isSaving = true);
    try {
      await widget.ref.read(reminderSettingsNotifierProvider.notifier).saveSettings(
            emailEnabled: _emailEnabled,
            smsEnabled: _smsEnabled,
            emailOffsetDays: _parseOffsets(_emailOffsetController.text),
            smsOffsetDays: _parseOffsets(_smsOffsetController.text),
            messageTemplate: _messageTemplateController.text,
          );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Reminder settings saved'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save settings: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        SwitchListTile(
          title: const Text('Email Reminders'),
          subtitle: const Text('Send payment reminders by email'),
          value: _emailEnabled,
          onChanged: (v) => setState(() => _emailEnabled = v),
        ),
        const Divider(height: 1),
        SwitchListTile(
          title: const Text('SMS Reminders'),
          subtitle: const Text('Send payment reminders by SMS'),
          value: _smsEnabled,
          onChanged: (v) => setState(() => _smsEnabled = v),
        ),
        const Divider(height: 1),
        const SizedBox(height: 16),
        const Text('Email cadence (days before due date)',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.inkPrimary)),
        const SizedBox(height: 8),
        TextField(
          controller: _emailOffsetController,
          decoration: const InputDecoration(
            labelText: 'Offset days (comma-separated)',
            hintText: 'e.g. 3, 1, 0',
          ),
          keyboardType: TextInputType.number,
        ),
        const SizedBox(height: 16),
        const Text('SMS cadence (days before due date)',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.inkPrimary)),
        const SizedBox(height: 8),
        TextField(
          controller: _smsOffsetController,
          decoration: const InputDecoration(
            labelText: 'Offset days (comma-separated)',
            hintText: 'e.g. 3, 0',
          ),
          keyboardType: TextInputType.number,
        ),
        const SizedBox(height: 24),
        const Text('Message template',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.inkPrimary)),
        const SizedBox(height: 8),
        TextField(
          controller: _messageTemplateController,
          decoration: const InputDecoration(
            labelText: 'Template',
            hintText: 'Dear {{customer_name}}, ...',
          ),
          maxLines: 4,
        ),
        const SizedBox(height: 32),
        SizedBox(
          width: double.infinity,
          height: 48,
          child: FilledButton(
            onPressed: _isSaving ? null : _saveSettings,
            child: _isSaving
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                : const Text('Save Reminder Settings'),
          ),
        ),
      ],
    );
  }
}

class _SettingsForm extends StatefulWidget {
  final ReminderSettings settings;
  final WidgetRef ref;

  const _SettingsForm({required this.settings, required this.ref});

  @override
  State<_SettingsForm> createState() => _SettingsFormState();
}