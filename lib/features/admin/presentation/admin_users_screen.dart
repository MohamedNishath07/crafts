import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../auth/domain/user_profile.dart';
import '../../auth/presentation/auth_controller.dart';
import 'staff_controller.dart';
import 'widgets/add_staff_dialog.dart';

class AdminUsersScreen extends ConsumerWidget {
  const AdminUsersScreen({super.key});

  Color _getRoleColor(UserRole role) {
    switch (role) {
      case UserRole.admin:
        return AppColors.accentDanger;
      case UserRole.financeOfficer:
        return AppColors.accentSuccess;
      case UserRole.recoveryOfficer:
        return AppColors.accentWarning;
    }
  }

  void _showAddStaffDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const AddStaffDialog(),
    );
  }

  void _confirmToggleStatus(
    BuildContext context,
    WidgetRef ref,
    UserProfile member,
    bool isSelf,
  ) {
    if (isSelf) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You cannot deactivate your own administrative account'),
          backgroundColor: AppColors.accentWarning,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final actionLabel = member.isActive ? 'Deactivate' : 'Activate';

    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: AppColors.surfaceRaised,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: AppColors.borderSubtle),
        ),
        title: Text('$actionLabel Staff Member'),
        content: Text(
          'Are you sure you want to $actionLabel ${member.fullName} (${member.email})?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(),
            child: const Text('Cancel', style: TextStyle(color: AppColors.inkSecondary)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(dialogCtx).pop();
              ref.read(staffControllerProvider.notifier).toggleStaffStatus(
                    userId: member.id,
                    currentStatus: member.isActive,
                  );
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Staff member ${member.fullName} was ${actionLabel.toLowerCase()}d'),
                  backgroundColor: AppColors.brandPrimary,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: member.isActive ? AppColors.accentDanger : AppColors.accentSuccess,
              foregroundColor: AppColors.inkWhite,
            ),
            child: Text(actionLabel),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final staffAsync = ref.watch(staffControllerProvider);
    final filteredStaff = ref.watch(filteredStaffListProvider);
    final currentAdmin = ref.watch(authControllerProvider).value;

    final selectedRole = ref.watch(staffRoleFilterProvider);
    final selectedStatus = ref.watch(staffStatusFilterProvider);

    return Scaffold(
      backgroundColor: AppColors.surfaceBase,
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Screen Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Staff User Management',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: AppColors.inkPrimary,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Administrator control: manage staff accounts, roles, and status',
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
                  onPressed: () => _showAddStaffDialog(context),
                  icon: const Icon(Icons.person_add_alt_1_outlined, size: 18),
                  label: const Text('Add Staff Member'),
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

            // Toolbar / Filters
            Card(
              color: AppColors.surfaceRaised,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
                side: const BorderSide(color: AppColors.borderSubtle),
              ),
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    // Search Input
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 260),
                      child: TextField(
                        decoration: InputDecoration(
                          hintText: 'Search staff by name or email...',
                          prefixIcon: const Icon(Icons.search, size: 18),
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(color: AppColors.borderSubtle),
                          ),
                        ),
                        onChanged: (val) {
                          ref.read(staffSearchQueryProvider.notifier).setQuery(val);
                        },
                      ),
                    ),

                    // Role Filter Dropdown
                    DropdownButton<UserRole?>(
                      value: selectedRole,
                      hint: const Text('All Roles', style: TextStyle(fontSize: 13)),
                      underline: const SizedBox.shrink(),
                      items: [
                        const DropdownMenuItem<UserRole?>(
                          value: null,
                          child: Text('All Roles', style: TextStyle(fontSize: 13)),
                        ),
                        ...UserRole.values.map((role) {
                          return DropdownMenuItem<UserRole?>(
                            value: role,
                            child: Text(role.displayName, style: const TextStyle(fontSize: 13)),
                          );
                        }),
                      ],
                      onChanged: (role) {
                        ref.read(staffRoleFilterProvider.notifier).setRole(role);
                      },
                    ),

                    // Status Filter Dropdown
                    DropdownButton<bool?>(
                      value: selectedStatus,
                      hint: const Text('All Statuses', style: TextStyle(fontSize: 13)),
                      underline: const SizedBox.shrink(),
                      items: const [
                        DropdownMenuItem<bool?>(
                          value: null,
                          child: Text('All Statuses', style: TextStyle(fontSize: 13)),
                        ),
                        DropdownMenuItem<bool?>(
                          value: true,
                          child: Text('Active Only', style: TextStyle(fontSize: 13)),
                        ),
                        DropdownMenuItem<bool?>(
                          value: false,
                          child: Text('Inactive Only', style: TextStyle(fontSize: 13)),
                        ),
                      ],
                      onChanged: (status) {
                        ref.read(staffStatusFilterProvider.notifier).setStatus(status);
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Staff Table
            Expanded(
              child: Card(
                color: AppColors.surfaceRaised,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                  side: const BorderSide(color: AppColors.borderSubtle),
                ),
                child: staffAsync.when(
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (err, stack) => Center(
                    child: Text('Error loading staff: $err', style: const TextStyle(color: AppColors.accentDanger)),
                  ),
                  data: (_) {
                    if (filteredStaff.isEmpty) {
                      return const Center(
                        child: Text(
                          'No staff members match the selected filters',
                          style: TextStyle(color: AppColors.inkSecondary),
                        ),
                      );
                    }

                    return SingleChildScrollView(
                      scrollDirection: Axis.vertical,
                      child: SizedBox(
                        width: double.infinity,
                        child: DataTable(
                          columnSpacing: 24,
                          headingRowHeight: 44,
                          dataRowMinHeight: 52,
                          dataRowMaxHeight: 56,
                          columns: const [
                            DataColumn(label: Text('Staff Member', style: TextStyle(fontWeight: FontWeight.bold))),
                            DataColumn(label: Text('Role', style: TextStyle(fontWeight: FontWeight.bold))),
                            DataColumn(label: Text('Status', style: TextStyle(fontWeight: FontWeight.bold))),
                            DataColumn(label: Text('Actions', style: TextStyle(fontWeight: FontWeight.bold))),
                          ],
                          rows: filteredStaff.map((member) {
                            final isSelf = currentAdmin != null && currentAdmin.id == member.id;
                            final roleColor = _getRoleColor(member.role);

                            return DataRow(
                              cells: [
                                // Staff Member
                                DataCell(
                                  Row(
                                    children: [
                                      CircleAvatar(
                                        radius: 16,
                                        backgroundColor: roleColor.withValues(alpha: 0.15),
                                        child: Text(
                                          member.fullName.isNotEmpty ? member.fullName[0].toUpperCase() : '?',
                                          style: TextStyle(
                                            color: roleColor,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Text(
                                            member.fullName,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w600,
                                              fontSize: 13,
                                              color: AppColors.inkPrimary,
                                            ),
                                          ),
                                          Text(
                                            member.email,
                                            style: const TextStyle(
                                              fontSize: 11,
                                              color: AppColors.inkSecondary,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),

                                // Role Badge
                                DataCell(
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: roleColor.withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(color: roleColor.withValues(alpha: 0.3)),
                                    ),
                                    child: Text(
                                      member.role.displayName,
                                      style: TextStyle(
                                        color: roleColor,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ),

                                // Status Badge
                                DataCell(
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: member.isActive
                                          ? AppColors.accentSuccess.withValues(alpha: 0.12)
                                          : AppColors.inkMuted.withValues(alpha: 0.2),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      member.isActive ? 'Active' : 'Inactive',
                                      style: TextStyle(
                                        color: member.isActive ? AppColors.accentSuccess : AppColors.inkSecondary,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ),

                                // Actions
                                DataCell(
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      // Toggle Active / Deactivate
                                      IconButton(
                                        tooltip: isSelf
                                            ? 'Cannot deactivate yourself'
                                            : (member.isActive ? 'Deactivate User' : 'Activate User'),
                                        icon: Icon(
                                          member.isActive ? Icons.block_outlined : Icons.check_circle_outline,
                                          size: 18,
                                          color: isSelf
                                              ? AppColors.inkMuted
                                              : (member.isActive ? AppColors.accentDanger : AppColors.accentSuccess),
                                        ),
                                        onPressed: () => _confirmToggleStatus(context, ref, member, isSelf),
                                      ),

                                      // Role change menu
                                      PopupMenuButton<UserRole>(
                                        tooltip: 'Change Role',
                                        icon: const Icon(Icons.more_vert, size: 18, color: AppColors.inkSecondary),
                                        onSelected: (newRole) {
                                          ref.read(staffControllerProvider.notifier).changeStaffRole(
                                                userId: member.id,
                                                newRole: newRole,
                                              );
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(
                                              content: Text('${member.fullName} role changed to ${newRole.displayName}'),
                                              backgroundColor: AppColors.brandPrimary,
                                              behavior: SnackBarBehavior.floating,
                                            ),
                                          );
                                        },
                                        itemBuilder: (ctx) => UserRole.values.map((r) {
                                          return PopupMenuItem(
                                            value: r,
                                            child: Row(
                                              children: [
                                                Icon(
                                                  r == member.role ? Icons.check : Icons.circle_outlined,
                                                  size: 16,
                                                  color: _getRoleColor(r),
                                                ),
                                                const SizedBox(width: 8),
                                                Text(r.displayName),
                                              ],
                                            ),
                                          );
                                        }).toList(),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            );
                          }).toList(),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
