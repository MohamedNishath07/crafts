import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../auth/domain/user_profile.dart';

class DashboardHeader extends StatelessWidget {
  final UserProfile? user;
  final bool isRefreshing;
  final bool isDatabaseEmpty;
  final VoidCallback onRefresh;
  final VoidCallback onSeedDemoData;

  const DashboardHeader({
    super.key,
    required this.user,
    required this.isRefreshing,
    required this.isDatabaseEmpty,
    required this.onRefresh,
    required this.onSeedDemoData,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final now = DateTime.now();
    final dateString = DateFormat('EEEE, MMM d, yyyy').format(now);
    final role = user?.role ?? UserRole.admin;

    final primaryNavy = isDark ? const Color(0xFF0F172A) : const Color(0xFF1E293B);
    final cardBg = isDark ? AppColors.surfaceDarkRaised : Colors.white;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
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
          // Top Row: User Avatar, Name & Role, Refresh Button
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Avatar
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [
                      primaryNavy,
                      AppColors.brandPrimary,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.brandPrimary.withValues(alpha: 0.25),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    (user?.fullName.isNotEmpty == true)
                        ? user!.fullName[0].toUpperCase()
                        : 'A',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 14),

              // Title and Subtitle
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            user?.fullName ?? 'Administrator',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : primaryNavy,
                              letterSpacing: -0.3,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        _buildRoleBadge(role, isDark),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Real-time overview of outstanding debt and recovery performance',
                      style: TextStyle(
                        fontSize: 13,
                        color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                        fontWeight: FontWeight.w400,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),

              // Actions (Seed Data chip & Refresh button)
              if (isDatabaseEmpty)
                Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: Tooltip(
                    message: 'Initialize sample financial data for demonstration',
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.brandPrimary,
                        side: const BorderSide(color: AppColors.brandPrimary),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      ),
                      icon: const Icon(Icons.auto_fix_high, size: 16),
                      label: const Text('Load Demo Data', style: TextStyle(fontSize: 12)),
                      onPressed: onSeedDemoData,
                    ),
                  ),
                ),

              IconButton(
                style: IconButton.styleFrom(
                  backgroundColor: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: Icon(
                  Icons.refresh_rounded,
                  color: isDark ? Colors.white : primaryNavy,
                  size: 20,
                ),
                tooltip: 'Refresh Dashboard',
                onPressed: isRefreshing ? null : onRefresh,
              ),
            ],
          ),

          const SizedBox(height: 14),
          const Divider(height: 1),
          const SizedBox(height: 12),

          // Bottom Info Row: Today's Date & Operations Dashboard badge
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.calendar_today_outlined,
                    size: 14,
                    color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    dateString,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  Container(
                    width: 7,
                    height: 7,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.accentSuccess,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Offline SQLite Active',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRoleBadge(UserRole role, bool isDark) {
    Color badgeBg;
    Color badgeTextColor;
    String label = role.displayName;

    switch (role) {
      case UserRole.admin:
        badgeBg = const Color(0xFF0F8D65).withValues(alpha: 0.15);
        badgeTextColor = const Color(0xFF0F8D65);
        break;
      case UserRole.financeOfficer:
        badgeBg = const Color(0xFF3B82F6).withValues(alpha: 0.15);
        badgeTextColor = const Color(0xFF2563EB);
        break;
      case UserRole.recoveryOfficer:
        badgeBg = const Color(0xFFF59E0B).withValues(alpha: 0.15);
        badgeTextColor = const Color(0xFFD97706);
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: badgeBg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: badgeTextColor,
        ),
      ),
    );
  }
}
