import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/presentation/auth_controller.dart';
import '../data/interaction_repository.dart';
import '../domain/interaction.dart';

final interactionControllerProvider = AsyncNotifierProvider<InteractionController, List<Interaction>>(() {
  return InteractionController();
});

/// Filter categories for the recovery log. Values: 'all', 'follow_ups',
/// 'promises', 'escalated'.
final interactionFilterProvider =
    NotifierProvider<InteractionFilterNotifier, String>(
        InteractionFilterNotifier.new);

/// Provider returning interactions filtered by the current filter selection.
final filteredInteractionsProvider = Provider<List<Interaction>>((ref) {
  final interactionsAsync = ref.watch(interactionControllerProvider);
  final filter = ref.watch(interactionFilterProvider);

  final interactions = interactionsAsync.value ?? [];
  if (filter == 'all') return interactions;

  return interactions.where((i) {
    switch (filter) {
      case 'follow_ups':
        return i.isFollowUpScheduled;
      case 'promises':
        return (i.promisedAmountCents ?? 0) > 0;
      case 'escalated':
        return i.outcome == InteractionOutcome.escalated;
      default:
        return true;
    }
  }).toList();
});

class InteractionFilterNotifier extends Notifier<String> {
  @override
  String build() => 'all';
  void setFilter(String filter) => state = filter;
}

class InteractionController extends AsyncNotifier<List<Interaction>> {
  late final InteractionRepository _repository;

  @override
  FutureOr<List<Interaction>> build() async {
    _repository = ref.watch(interactionRepositoryProvider);
    final authProfile = ref.watch(authControllerProvider);
    final tenantId = authProfile.value?.tenantId ?? 'a0000000-0000-0000-0000-000000000001';

    try {
      return await _repository.fetchInteractions(tenantId);
    } catch (_) {
      return [];
    }
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final authProfile = ref.read(authControllerProvider);
      return await _repository.fetchInteractions(authProfile.value?.tenantId ?? 'a0000000-0000-0000-0000-000000000001');
    });
  }

  Future<Interaction> saveInteraction({
    required String debtId,
    required String debtCustomerId,
    required String officerId,
    required String actionType,
    required String outcome,
    DateTime? followUpDate,
    int? promisedAmountCents,
    String? notes,
  }) async {
    try {
      final newInteraction = await _repository.saveInteraction(
        debtId: debtId,
        debtCustomerId: debtCustomerId,
        officerId: officerId,
        actionType: actionType,
        outcome: outcome,
        followUpDate: followUpDate,
        promisedAmountCents: promisedAmountCents,
        notes: notes,
      );

      state = AsyncValue.data([newInteraction, ...?state.value]);
      return newInteraction;
    } catch (e) {
      state = AsyncValue.data([...?state.value]);
      rethrow;
    }
  }
}