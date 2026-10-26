import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/presentation/auth_controller.dart';
import '../data/debt_repository.dart';
import '../domain/debt.dart';

final debtControllerProvider = AsyncNotifierProvider<DebtController, List<Debt>>(() {
  return DebtController();
});

final debtSearchQueryProvider = NotifierProvider<DebtSearchQueryNotifier, String>(DebtSearchQueryNotifier.new);

class DebtSearchQueryNotifier extends Notifier<String> {
  @override
  String build() => '';
  void setQuery(String query) => state = query;
}

final debtPageSizeProvider = NotifierProvider<DebtPageSizeNotifier, int>(DebtPageSizeNotifier.new);

class DebtPageSizeNotifier extends Notifier<int> {
  @override
  int build() => 25;
  void setPageSize(int size) => state = size;
}

final debtPageIndexProvider = NotifierProvider<DebtPageIndexNotifier, int>(DebtPageIndexNotifier.new);

class DebtPageIndexNotifier extends Notifier<int> {
  @override
  int build() => 0;
  void setPage(int page) => state = page;
  void nextPage() => state++;
  void previousPage() {
    if (state > 0) state--;
  }
}

/// Aging filter selection. Values: 'all', 'overdue', 'current', '1-30', '31-60', '61-90', '90+', 'settled'
final debtAgingFilterProvider = NotifierProvider<DebtAgingFilterNotifier, String>(DebtAgingFilterNotifier.new);

class DebtAgingFilterNotifier extends Notifier<String> {
  @override
  String build() => 'all';
  void setFilter(String filter) => state = filter;
}

/// Provider returning all debts matching the current search query and aging filter
final filteredDebtsProvider = Provider<List<Debt>>((ref) {
  final debtsAsync = ref.watch(debtControllerProvider);
  final searchQuery = ref.watch(debtSearchQueryProvider).trim().toLowerCase();
  final agingFilter = ref.watch(debtAgingFilterProvider);

  final debts = debtsAsync.value ?? [];
  if (searchQuery.isEmpty && agingFilter == 'all') return debts;

  return debts.where((d) {
    final refMatches = d.referenceNumber.toLowerCase().contains(searchQuery);
    final customerMatches = d.customerId.toLowerCase().contains(searchQuery);
    final matchesSearch = searchQuery.isEmpty || refMatches || customerMatches;

    final matchesAging = switch (agingFilter) {
      'all' => true,
      'overdue' => d.isOverdue,
      'current' => d.agingBracket == 'Current',
      '1-30' => d.agingBracket == '1-30 DPD',
      '31-60' => d.agingBracket == '31-60 DPD',
      '61-90' => d.agingBracket == '61-90 DPD',
      '90+' => d.agingBracket == '90+ DPD',
      'settled' => d.status == 'settled',
      _ => true,
    };

    return matchesSearch && matchesAging;
  }).toList();
});

/// Provider returning the current paginated slice of filtered debts
final paginatedDebtsProvider = Provider<List<Debt>>((ref) {
  final filtered = ref.watch(filteredDebtsProvider);
  final pageSize = ref.watch(debtPageSizeProvider);
  final pageIndex = ref.watch(debtPageIndexProvider);

  final startIndex = pageIndex * pageSize;
  if (startIndex >= filtered.length) return [];

  final endIndex = (startIndex + pageSize) > filtered.length
      ? filtered.length
      : startIndex + pageSize;

  return filtered.sublist(startIndex, endIndex);
});

class DebtController extends AsyncNotifier<List<Debt>> {
  late final DebtRepository _repository;

  @override
  FutureOr<List<Debt>> build() async {
    _repository = ref.watch(debtRepositoryProvider);
    final authProfile = ref.read(authControllerProvider).value;
    final tenantId = authProfile?.tenantId ?? 'a0000000-0000-0000-0000-000000000001';

    try {
      final list = await _repository.fetchDebts(tenantId).timeout(
        const Duration(seconds: 2),
      );
      return list.isNotEmpty
          ? list
          : _repository.generateDefaultDebts(tenantId, const []);
    } catch (_) {
      return _repository.generateDefaultDebts(tenantId, const []);
    }
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final authProfile = ref.read(authControllerProvider).value;
      final tenantId = authProfile?.tenantId ?? 'a0000000-0000-0000-0000-000000000001';
      try {
        final list = await _repository.fetchDebts(tenantId).timeout(
          const Duration(seconds: 2),
        );
        return list.isNotEmpty
            ? list
            : (state.value ?? _repository.generateDefaultDebts(tenantId, const []));
      } catch (_) {
        return state.value ?? _repository.generateDefaultDebts(tenantId, const []);
      }
    });
  }

  Future<Debt> createDebt({
    required String customerId,
    String? assignedOfficerId,
    required String referenceNumber,
    required int principalAmountCents,
    required DateTime originDate,
    required DateTime dueDate,
  }) async {
    final authProfile = ref.read(authControllerProvider).value;
    final tenantId = authProfile?.tenantId ?? 'a0000000-0000-0000-0000-000000000001';
    final currentList = state.value ?? [];

    try {
      final newDebt = await _repository.createDebt(
        tenantId: tenantId,
        customerId: customerId,
        assignedOfficerId: assignedOfficerId,
        referenceNumber: referenceNumber,
        principalAmountCents: principalAmountCents,
        originDate: originDate,
        dueDate: dueDate,
      ).timeout(const Duration(seconds: 2));

      state = AsyncValue.data([newDebt, ...currentList]);
      return newDebt;
    } catch (_) {
      // Local fallback in offline / test mode
      final localDebt = Debt(
        id: 'debt-${DateTime.now().millisecondsSinceEpoch}',
        tenantId: tenantId,
        customerId: customerId,
        assignedOfficerId: assignedOfficerId,
        referenceNumber: referenceNumber.trim(),
        principalAmountCents: principalAmountCents,
        remainingBalanceCents: principalAmountCents,
        originDate: originDate,
        dueDate: dueDate,
        status: 'active',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      state = AsyncValue.data([localDebt, ...currentList]);
      return localDebt;
    }
  }
}