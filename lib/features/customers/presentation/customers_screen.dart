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
    final customerAsync = ref.watch(customerControllerProvider);
    final filteredCustomers = ref.watch(filteredCustomersProvider);
    final paginatedCustomers = ref.watch(paginatedCustomersProvider);

    final pageSize = ref.watch(customerPageSizeProvider);
    final pageIndex = ref.watch(customerPageIndexProvider);

    final totalCount = filteredCustomers.length;
    final startRecord = totalCount == 0 ? 0 : (pageIndex * pageSize) + 1;
    final endRecord = ((pageIndex + 1) * pageSize) > totalCount ? totalCount : (pageIndex + 1) * pageSize;
    final maxPage = totalCount == 0 ? 0 : ((totalCount - 1) ~/ pageSize);

    return Scaffold(
      backgroundColor: AppColors.surfaceBase,
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Top Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Customer Directory',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: AppColors.inkPrimary,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Search, filter, and register borrower and customer accounts',
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.inkSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                ElevatedButton.icon(
                  onPressed: () => _showAddCustomerDialog(context),
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
            ),
            const SizedBox(height: 20),

            // Search Toolbar
            Card(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        decoration: InputDecoration(
                          hintText: 'Search by customer name, phone number, email, or national ID...',
                          prefixIcon: const Icon(Icons.search, size: 20, color: AppColors.inkSecondary),
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(vertical: 8),
                          suffixIcon: ref.watch(customerSearchQueryProvider).isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear, size: 18),
                                  onPressed: () {
                                    ref.read(customerSearchQueryProvider.notifier).setQuery('');
                                    ref.read(customerPageIndexProvider.notifier).setPage(0);
                                  },
                                )
                              : null,
                        ),
                        onChanged: (val) {
                          ref.read(customerSearchQueryProvider.notifier).setQuery(val);
                          ref.read(customerPageIndexProvider.notifier).setPage(0);
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Main Data Table Card
            Expanded(
              child: Card(
                child: customerAsync.isLoading
                    ? const Center(
                        child: CircularProgressIndicator(),
                      )
                    : customerAsync.hasError
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.error_outline, size: 40, color: AppColors.accentDanger),
                                const SizedBox(height: 12),
                                Text(
                                  'Failed to load customer directory: ${customerAsync.error}',
                                  style: const TextStyle(color: AppColors.inkSecondary),
                                ),
                                const SizedBox(height: 12),
                                ElevatedButton(
                                  onPressed: () => ref.read(customerControllerProvider.notifier).refresh(),
                                  child: const Text('Retry'),
                                ),
                              ],
                            ),
                          )
                        : paginatedCustomers.isEmpty
                            ? const Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.person_search_outlined, size: 48, color: AppColors.inkMuted),
                                    SizedBox(height: 12),
                                    Text(
                                      'No customers found matching your search',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w500,
                                        color: AppColors.inkSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            : LayoutBuilder(
                                builder: (context, constraints) {
                                  return SingleChildScrollView(
                                    scrollDirection: Axis.vertical,
                                    child: SingleChildScrollView(
                                      scrollDirection: Axis.horizontal,
                                      child: ConstrainedBox(
                                        constraints: BoxConstraints(minWidth: constraints.maxWidth),
                                        child: DataTable(
                                          headingRowColor: WidgetStateProperty.all(const Color(0xFFF8FAFC)),
                                          dataRowMinHeight: 52,
                                          dataRowMaxHeight: 56,
                                          columns: const [
                                            DataColumn(
                                              label: Text('Customer Name', style: TextStyle(fontWeight: FontWeight.w600)),
                                            ),
                                            DataColumn(
                                              label: Text('Phone Number', style: TextStyle(fontWeight: FontWeight.w600)),
                                            ),
                                            DataColumn(
                                              label: Text('Email Address', style: TextStyle(fontWeight: FontWeight.w600)),
                                            ),
                                            DataColumn(
                                              label: Text('National ID', style: TextStyle(fontWeight: FontWeight.w600)),
                                            ),
                                            DataColumn(
                                              label: Text('Address', style: TextStyle(fontWeight: FontWeight.w600)),
                                            ),
                                            DataColumn(
                                              label: Text('Registered', style: TextStyle(fontWeight: FontWeight.w600)),
                                            ),
                                          ],
                                          rows: paginatedCustomers.map((customer) {
                                            return _buildCustomerRow(customer);
                                          }).toList(),
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
              ),
            ),
            const SizedBox(height: 12),

            // Pagination Footer Toolbar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Row(
                children: [
                  Text(
                    'Showing $startRecord-$endRecord of $totalCount records',
                    style: const TextStyle(fontSize: 13, color: AppColors.inkSecondary),
                  ),
                  const Spacer(),
                  const Text('Rows per page: ', style: TextStyle(fontSize: 13, color: AppColors.inkSecondary)),
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
                        ref.read(customerPageSizeProvider.notifier).setPageSize(newSize);
                        ref.read(customerPageIndexProvider.notifier).setPage(0);
                      }
                    },
                  ),
                  const SizedBox(width: 16),
                  IconButton(
                    icon: const Icon(Icons.chevron_left, size: 20),
                    tooltip: 'Previous Page',
                    onPressed: pageIndex > 0
                        ? () => ref.read(customerPageIndexProvider.notifier).previousPage()
                        : null,
                  ),
                  Text(
                    'Page ${pageIndex + 1} of ${maxPage + 1}',
                    style: const TextStyle(fontSize: 13, color: AppColors.inkPrimary),
                  ),
                  IconButton(
                    icon: const Icon(Icons.chevron_right, size: 20),
                    tooltip: 'Next Page',
                    onPressed: pageIndex < maxPage
                        ? () => ref.read(customerPageIndexProvider.notifier).nextPage()
                        : null,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  DataRow _buildCustomerRow(Customer customer) {
    final dateStr = '${customer.createdAt.year}-${customer.createdAt.month.toString().padLeft(2, '0')}-${customer.createdAt.day.toString().padLeft(2, '0')}';

    return DataRow(
      cells: [
        DataCell(
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircleAvatar(
                radius: 14,
                backgroundColor: AppColors.brandPrimary.withValues(alpha: 0.1),
                child: Text(
                  customer.fullName.isNotEmpty ? customer.fullName[0].toUpperCase() : 'C',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.brandPrimary),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                customer.fullName,
                style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.inkPrimary),
              ),
            ],
          ),
        ),
        DataCell(
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(customer.phoneNumber, style: const TextStyle(color: AppColors.inkPrimary)),
              if (customer.secondaryPhone != null && customer.secondaryPhone!.isNotEmpty)
                Text(
                  customer.secondaryPhone!,
                  style: const TextStyle(fontSize: 11, color: AppColors.inkSecondary),
                ),
            ],
          ),
        ),
        DataCell(
          Text(customer.email ?? '—', style: const TextStyle(color: AppColors.inkPrimary)),
        ),
        DataCell(
          Text(customer.nationalId ?? '—', style: const TextStyle(color: AppColors.inkSecondary)),
        ),
        DataCell(
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 200),
            child: Text(
              customer.address ?? '—',
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: AppColors.inkSecondary),
            ),
          ),
        ),
        DataCell(
          Text(dateStr, style: const TextStyle(color: AppColors.inkSecondary)),
        ),
      ],
    );
  }
}
