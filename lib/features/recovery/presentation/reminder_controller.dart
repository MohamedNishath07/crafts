import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/presentation/auth_controller.dart';
import '../data/reminder_repository.dart';
import '../domain/reminder_settings.dart';

final reminderSettingsProvider =
    FutureProvider.autoDispose<ReminderSettings>((ref) async {
  final repo = ref.read(reminderRepositoryProvider);
  final authProfile = ref.watch(authControllerProvider);
  final tenantId = authProfile.value?.tenantId ??
      'a0000000-0000-0000-0000-000000000001';
  return await repo.fetchReminderSettings(tenantId);
});

final reminderDispatchesProvider =
    FutureProvider.autoDispose<List<ReminderDispatch>>((ref) async {
  final repo = ref.read(reminderRepositoryProvider);
  final authProfile = ref.watch(authControllerProvider);
  final tenantId = authProfile.value?.tenantId ??
      'a0000000-0000-0000-0000-000000000001';
  return await repo.fetchReminderDispatches(tenantId);
});

/// Notifier for saving reminder settings.
class ReminderSettingsNotifier extends Notifier<ReminderSettings?> {
  @override
  ReminderSettings? build() {
    return null;
  }

  Future<void> saveSettings({
    required bool emailEnabled,
    required bool smsEnabled,
    required List<int> emailOffsetDays,
    required List<int> smsOffsetDays,
    required String messageTemplate,
  }) async {
    final repo = ref.read(reminderRepositoryProvider);
    final authProfile = ref.read(authControllerProvider);
    final tenantId = authProfile.value?.tenantId ??
        'a0000000-0000-0000-0000-000000000001';

    state = null;
    try {
      final settings = await repo.saveReminderSettings(
        tenantId: tenantId,
        emailEnabled: emailEnabled,
        smsEnabled: smsEnabled,
        emailOffsetDays: emailOffsetDays,
        smsOffsetDays: smsOffsetDays,
        messageTemplate: messageTemplate,
      );
      state = settings;
    } catch (e) {
      rethrow;
    }
  }
}

final reminderSettingsNotifierProvider =
    NotifierProvider<ReminderSettingsNotifier, ReminderSettings?>(
  () => ReminderSettingsNotifier(),
);
