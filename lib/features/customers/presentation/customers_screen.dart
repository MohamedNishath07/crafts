import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_colors.dart';
import '../domain/customer.dart';
import 'customer_controller.dart';
import 'widgets/add_customer_dialog.dart';

class CustomersScreen extends ConsumerWidget {
  const CustomersScreen({super.key});

  void _showAddCustomerDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const AddCustomerDialog(),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: AppColors.surfaceBaseColor(isDark),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
            24.0,
            24.0,
            24.0,
            24.0 + MediaQuery.of(context).padding.bottom,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              CustomersHeader(onAddCustomer: () => _showAddCustomerDialog(context)),
              const SizedBox(height: 20),
              const CustomerSearchBar(),
              const SizedBox(height: 16),
              const CustomerTable(),
              const SizedBox(height: 12),
              const CustomersPaginationBar(),
            ],
          ),
        ),
      ),
    );
  }
}

class CustomersHeader extends StatelessWidget {
  const CustomersHeader({super.key, required this.onAddCustomer});

  final VoidCallback onAddCustomer;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Customer Directory',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppColors.inkPrimaryColor(isDark),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Search, filter, and register borrower and customer accounts',
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.inkSecondaryColor(isDark),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 16),
        ElevatedButton.icon(
          onPressed: onAddCustomer,
          icon: const Icon(Icons.add, size: 18),
          label: const Text('Add Customer'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.brandPrimary,
            foregroundColor: AppColors.inkWhite,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
      ],
    );
  }
}

class CustomerSearchBar extends ConsumerWidget {
  const CustomerSearchBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final query = ref.watch(customerSearchQueryProvider);

    return Card(
      color: AppColors.surfaceDarkCardColor(isDark),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: AppColors.borderSubtleColor(isDark)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: TextField(
          decoration: InputDecoration(
            hintText:
                'Search by customer name, phone number, email, or national ID...',
            prefixIcon: Icon(
              Icons.search,
              size: 20,
              color: AppColors.inkSecondaryColor(isDark),
            ),
            border: InputBorder.none,
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(vertical: 8),
            suffixIcon: query.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear, size: 18),
                    tooltip: 'Clear search',
                    onPressed: () => ref
                        .read(customerSearchQueryProvider.notifier)
                        .clear(),
                  )
                : null,
          ),
          onChanged: (val) => ref
              .read(customerSearchQueryProvider.notifier)
              .onSearchChanged(val),
        ),
      ),
    );
  }
}

class CustomerTable extends ConsumerWidget {
  const CustomerTable({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final customerAsync = ref.watch(customerControllerProvider);
    final paginatedCustomers = ref.watch(paginatedCustomersProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Card(
      color: AppColors.surfaceDarkCardColor(isDark),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: AppColors.borderSubtleColor(isDark)),
      ),
      child: customerAsync.isLoading
          ? const _CustomersLoading()
          : customerAsync.hasError
          ? _CustomersError(error: customerAsync.error)
          : paginatedCustomers.isEmpty
          ? const _CustomersEmpty()
          : LayoutBuilder(
              builder: (context, constraints) {
                final useCards = constraints.maxWidth < 720;
                return useCards
                    ? _CustomerCardList(customers: paginatedCustomers)
                    : _CustomerDataTable(customers: paginatedCustomers);
              },
            ),
    );
  }
}

class _CustomersLoading extends StatelessWidget {
  const _CustomersLoading();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      key: ValueKey('customers-loading'),
      padding: EdgeInsets.symmetric(vertical: 48),
      child: Center(child: CircularProgressIndicator()),
    );
  }
}

class _CustomersError extends ConsumerWidget {
  const _CustomersError({required this.error});

  final Object? error;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      key: ValueKey('customers-error'),
      padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 40,
              color: AppColors.accentDanger,
            ),
            const SizedBox(height: 12),
            Text(
              'Failed to load customer directory: $error',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.inkSecondaryColor(isDark)),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () =>
                  ref.read(customerControllerProvider.notifier).refresh(),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}

class _CustomersEmpty extends StatelessWidget {
  const _CustomersEmpty();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textSecondary = AppColors.inkSecondaryColor(isDark);

    return Padding(
      key: ValueKey('customers-empty'),
      padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.person_search_outlined,
              size: 48,
              color: textSecondary,
            ),
            const SizedBox(height: 12),
            Text(
              'No customers found matching your search',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CustomerDataTable extends StatelessWidget {
  const _CustomerDataTable({required this.customers});

  final List<Customer> customers;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final headingColor = isDark
        ? const Color(0xFF16213E)
        : AppColors.lightBorderSubtle;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          minWidth: MediaQuery.of(context).size.width - 96,
        ),
        child: DataTable(
          headingRowColor: WidgetStateProperty.all(headingColor),
          dataRowMinHeight: 52,
          dataRowMaxHeight: 56,
          columns: const [
            DataColumn(
              label: Text(
                'Customer Name',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
            DataColumn(
              label: Text(
                'Phone Number',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
            DataColumn(
              label: Text(
                'Email Address',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
            DataColumn(
              label: Text(
                'National ID',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
            DataColumn(
              label: Text(
                'Address',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
            DataColumn(
              label: Text(
                'Registered',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ],
          rows: customers.map((c) => _buildRow(c, isDark)).toList(),
        ),
      ),
    );
  }

  DataRow _buildRow(Customer customer, bool isDark) {
    final avatarBg = AppColors.brandPrimary.withValues(
      alpha: isDark ? 0.25 : 0.1,
    );
    final dateStr =
        '${customer.createdAt.year}-${customer.createdAt.month.toString().padLeft(2, '0')}-${customer.createdAt.day.toString().padLeft(2, '0')}';

    return DataRow(
      cells: [
        DataCell(
          Semantics(
            label: 'Customer: ${customer.fullName}',
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircleAvatar(
                  radius: 14,
                  backgroundColor: avatarBg,
                  child: Text(
                    customer.fullName.isNotEmpty
                        ? customer.fullName[0].toUpperCase()
                        : 'C',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: isDark
                          ? AppColors.brandAccent
                          : AppColors.brandPrimary,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  customer.fullName,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: AppColors.inkPrimaryColor(isDark),
                  ),
                ),
              ],
            ),
          ),
        ),
        DataCell(
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                customer.phoneNumber,
                style: TextStyle(color: AppColors.inkPrimaryColor(isDark)),
              ),
              if (customer.secondaryPhone != null &&
                  customer.secondaryPhone!.isNotEmpty)
                Text(
                  customer.secondaryPhone!,
                  style: TextStyle(
                    fontSize: 11,
                    color: AppColors.inkSecondaryColor(isDark),
                  ),
                ),
            ],
          ),
        ),
        DataCell(
          Text(
            customer.email ?? '—',
            style: TextStyle(color: AppColors.inkPrimaryColor(isDark)),
          ),
        ),
        DataCell(
          Text(
            customer.nationalId ?? '—',
            style: TextStyle(color: AppColors.inkSecondaryColor(isDark)),
          ),
        ),
        DataCell(
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 200),
            child: Text(
              customer.address ?? '—',
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: AppColors.inkSecondaryColor(isDark)),
            ),
          ),
        ),
        DataCell(
          Text(
            dateStr,
            style: TextStyle(color: AppColors.inkSecondaryColor(isDark)),
          ),
        ),
      ],
    );
  }
}

class _CustomerCardList extends StatelessWidget {
  const _CustomerCardList({required this.customers});

  final List<Customer> customers;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.all(12),
      itemCount: customers.length,
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (context, index) =>
          CustomerListTile(customer: customers[index]),
    );
  }
}

class CustomerListTile extends StatelessWidget {
  const CustomerListTile({super.key, required this.customer});

  final Customer customer;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final avatarBg = AppColors.brandPrimary.withValues(
      alpha: isDark ? 0.25 : 0.1,
    );
    final dateStr =
        '${customer.createdAt.year}-${customer.createdAt.month.toString().padLeft(2, '0')}-${customer.createdAt.day.toString().padLeft(2, '0')}';

    return Semantics(
      label: 'Customer: ${customer.fullName}',
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.surfaceDarkCardColor(isDark),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.borderSubtleColor(isDark)),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: avatarBg,
              child: Text(
                customer.fullName.isNotEmpty
                    ? customer.fullName[0].toUpperCase()
                    : 'C',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: isDark ? AppColors.brandAccent : AppColors.brandPrimary,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    customer.fullName,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: AppColors.inkPrimaryColor(isDark),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    customer.phoneNumber,
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.inkSecondaryColor(isDark),
                    ),
                  ),
                  if ((customer.email ?? '').isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      customer.email!,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.inkSecondaryColor(isDark),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(
              dateStr,
              style: TextStyle(
                fontSize: 12,
                color: AppColors.inkSecondaryColor(isDark),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class CustomersPaginationBar extends ConsumerWidget {
  const CustomersPaginationBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = AppColors.inkPrimaryColor(isDark);
    final textSecondary = AppColors.inkSecondaryColor(isDark);

    final totalCount = ref.watch(filteredCustomersProvider).length;
    final pageSize = ref.watch(customerPageSizeProvider);
    final pageIndex = ref.watch(customerPageIndexProvider);

    final startRecord = totalCount == 0 ? 0 : (pageIndex * pageSize) + 1;
    final endRecord = ((pageIndex + 1) * pageSize) > totalCount
        ? totalCount
        : (pageIndex + 1) * pageSize;
    final maxPage = totalCount == 0 ? 0 : ((totalCount - 1) ~/ pageSize);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        children: [
          Text(
            'Showing $startRecord-$endRecord of $totalCount records',
            style: TextStyle(fontSize: 13, color: textSecondary),
          ),
          const Spacer(),
          Text(
            'Rows per page: ',
            style: TextStyle(fontSize: 13, color: textSecondary),
          ),
          DropdownButton<int>(
            value: pageSize,
            underline: const SizedBox.shrink(),
            items: const [
              DropdownMenuItem(value: 25, child: Text('25')),
              DropdownMenuItem(value: 50, child: Text('50')),
              DropdownMenuItem(value: 100, child: Text('100')),
            ],
            onChanged: (newSize) {
              if (newSize != null) {
                ref
                    .read(customerPageSizeProvider.notifier)
                    .setPageSize(newSize);
                ref.read(customerPageIndexProvider.notifier).setPage(0);
              }
            },
          ),
          const SizedBox(width: 16),
          IconButton(
            key: const ValueKey('customers-prev-page'),
            icon: const Icon(Icons.chevron_left, size: 20),
            tooltip: 'Previous Page',
            onPressed: pageIndex > 0
                ? () => ref
                      .read(customerPageIndexProvider.notifier)
                      .previousPage()
                : null,
          ),
          Text(
            'Page ${pageIndex + 1} of ${maxPage + 1}',
            style: TextStyle(fontSize: 13, color: textPrimary),
          ),
          IconButton(
            key: const ValueKey('customers-next-page'),
            icon: const Icon(Icons.chevron_right, size: 20),
            tooltip: 'Next Page',
            onPressed: pageIndex < maxPage
                ? () =>
                      ref.read(customerPageIndexProvider.notifier).nextPage()
                : null,
          ),
        ],
      ),
    );
  }
}