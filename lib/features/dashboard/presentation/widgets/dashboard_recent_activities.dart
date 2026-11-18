import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../domain/dashboard_models.dart';

class DashboardRecentActivities extends StatelessWidget {
  final List<RecentActivity> activities;
  final String selectedFilter;
  final Function(String) onFilterChanged;

  const DashboardRecentActivities({
    super.key,
    required this.activities,
    required this.selectedFilter,
    required this.onFilterChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? AppColors.surfaceDarkRaised : Colors.white;
    final primaryTextColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final secondaryTextColor = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
    final currencyFmt = NumberFormat.currency(symbol: '\$', decimalDigits: 2);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Recent Activities',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: primaryTextColor,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Real-time transaction feed',
                    style: TextStyle(
                      fontSize: 12,
                      color: secondaryTextColor,
                    ),
                  ),
                ],
              ),
              TextButton.icon(
                onPressed: () => _handleViewAll(context, selectedFilter),
                icon: const Icon(Icons.arrow_forward_rounded, size: 16),
                label: const Text('View All', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.brandPrimary,
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // Activity Category Filter Pills
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildFilterChip('all', 'All Activities', isDark),
                const SizedBox(width: 8),
                _buildFilterChip('payment', 'Payments', isDark),
                const SizedBox(width: 8),
                _buildFilterChip('credit', 'Credit Bills', isDark),
                const SizedBox(width: 8),
                _buildFilterChip('recovery', 'Recovery Logs', isDark),
                const SizedBox(width: 8),
                _buildFilterChip('customer', 'Customers', isDark),
              ],
            ),
          ),

          const SizedBox(height: 16),
          const Divider(height: 1),
          const SizedBox(height: 8),

          // Activities List or Empty State
          if (activities.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 32.0),
              child: Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.history_toggle_off_rounded,
                      size: 40,
                      color: secondaryTextColor,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'No recent activities found for this filter.',
                      style: TextStyle(
                        fontSize: 13,
                        color: secondaryTextColor,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: activities.length,
              separatorBuilder: (context, index) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final item = activities[index];
                return _ActivityListTile(
                  item: item,
                  isDark: isDark,
                  currencyFmt: currencyFmt,
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String filterKey, String label, bool isDark) {
    final isSelected = selectedFilter == filterKey;
    return InkWell(
      onTap: () => onFilterChanged(filterKey),
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.brandPrimary
              : (isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9)),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            color: isSelected
                ? Colors.white
                : (isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
          ),
        ),
      ),
    );
  }

  void _handleViewAll(BuildContext context, String filter) {
    switch (filter) {
      case 'payment':
        context.go('/payments');
        break;
      case 'credit':
        context.go('/debts');
        break;
      case 'recovery':
        context.go('/recovery');
        break;
      case 'customer':
        context.go('/customers');
        break;
      case 'all':
      default:
        context.go('/debts');
        break;
    }
  }
}

class _ActivityListTile extends StatelessWidget {
  final RecentActivity item;
  final bool isDark;
  final NumberFormat currencyFmt;

  const _ActivityListTile({
    required this.item,
    required this.isDark,
    required this.currencyFmt,
  });

  @override
  Widget build(BuildContext context) {
    final primaryTextColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final secondaryTextColor = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

    final config = _getTypeConfig(item.type);
    final timeStr = _formatTimestamp(item.timestamp);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Icon Avatar
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: config.color.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(
              config.icon,
              color: config.color,
              size: 20,
            ),
          ),
          const SizedBox(width: 14),

          // Title & Subtitle
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        item.title,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: primaryTextColor,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (item.status != null) ...[
                      const SizedBox(width: 8),
                      _buildStatusPill(item.status!, config.color),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  item.subtitle,
                  style: TextStyle(
                    fontSize: 11,
                    color: secondaryTextColor,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),

          const SizedBox(width: 12),

          // Amount & Timestamp
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (item.amount != null)
                Text(
                  currencyFmt.format(item.amount),
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: config.color,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                )
              else
                Text(
                  item.type.displayName,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: secondaryTextColor,
                  ),
                ),
              const SizedBox(height: 2),
              Text(
                timeStr,
                style: TextStyle(
                  fontSize: 10,
                  color: secondaryTextColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusPill(String status, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }

  _TypeConfig _getTypeConfig(ActivityType type) {
    switch (type) {
      case ActivityType.payment:
        return const _TypeConfig(
          icon: Icons.payments_rounded,
          color: Color(0xFF10B981), // Emerald
        );
      case ActivityType.credit:
        return const _TypeConfig(
          icon: Icons.receipt_long_rounded,
          color: Color(0xFF1E293B), // Navy
        );
      case ActivityType.recovery:
        return const _TypeConfig(
          icon: Icons.phone_callback_rounded,
          color: Color(0xFFF59E0B), // Amber
        );
      case ActivityType.customer:
        return const _TypeConfig(
          icon: Icons.person_rounded,
          color: Color(0xFF0D9488), // Teal
        );
    }
  }

  String _formatTimestamp(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);

    if (diff.inMinutes < 60) {
      return '${diff.inMinutes}m ago';
    } else if (diff.inHours < 24 && dt.day == now.day) {
      return DateFormat('h:mm a').format(dt);
    } else if (diff.inDays <= 1) {
      return 'Yesterday';
    } else {
      return DateFormat('MMM d').format(dt);
    }
  }
}

class _TypeConfig {
  final IconData icon;
  final Color color;

  const _TypeConfig({required this.icon, required this.color});
}
