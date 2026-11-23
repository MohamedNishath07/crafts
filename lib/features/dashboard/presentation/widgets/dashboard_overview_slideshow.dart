import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_colors.dart';
import '../../domain/dashboard_models.dart';

/// A full-width, auto-advancing slideshow of the six overview metric cards.
///
/// Each slide fills the section width (matching the Recent Activities card)
/// at a tall height and advances every [_slideInterval] with a smooth
/// fade + slide + scale transition. Hovering (desktop) pauses the rotation.
class DashboardOverviewSlideshow extends StatefulWidget {
  final DashboardOverviewMetrics metrics;
  final bool isLoading;

  const DashboardOverviewSlideshow({
    super.key,
    required this.metrics,
    required this.isLoading,
  });

  @override
  State<DashboardOverviewSlideshow> createState() =>
      _DashboardOverviewSlideshowState();
}

class _DashboardOverviewSlideshowState
    extends State<DashboardOverviewSlideshow> {
  static const Duration _slideInterval = Duration(seconds: 4);
  static const double _cardHeight = 340;

  Timer? _timer;
  int _index = 0;
  int _direction = 1; // 1 = forward, -1 = backward
  bool _hovering = false;

  List<_SlideMetric> _buildSlides() {
    final m = widget.metrics;
    final currency = NumberFormat.currency(symbol: r'$', decimalDigits: 2);
    final number = NumberFormat.decimalPattern();
    return [
      _SlideMetric(
        title: 'Total Customers',
        value: number.format(m.totalCustomers),
        subtitle: '${m.totalCustomers} registered in system',
        icon: Icons.people_alt_rounded,
        badge: 'Active',
      ),
      _SlideMetric(
        title: 'Total Credit Amount',
        value: currency.format(m.totalCreditAmount),
        subtitle: 'Principal billed across all ledgers',
        icon: Icons.account_balance_wallet_rounded,
        badge: 'Credit Issued',
      ),
      _SlideMetric(
        title: 'Total Collected Amount',
        value: currency.format(m.totalCollectedAmount),
        subtitle: 'Recovery rate: ${m.recoveryRate.toStringAsFixed(1)}%',
        icon: Icons.check_circle_rounded,
        badge: '+${m.recoveryRate.toStringAsFixed(0)}% Settled',
      ),
      _SlideMetric(
        title: 'Outstanding Balance',
        value: currency.format(m.outstandingBalance),
        subtitle: '${m.activeBillsCount} active pending bills',
        icon: Icons.timelapse_rounded,
        badge: 'Pending',
      ),
      _SlideMetric(
        title: "Today's Collections",
        value: currency.format(m.todayCollections),
        subtitle: "Recorded in today's transactions",
        icon: Icons.payments_rounded,
        badge: 'Today',
      ),
      _SlideMetric(
        title: 'Overdue Payments',
        value: currency.format(m.overdueBalance),
        subtitle: '${m.overdueCount} accounts past due date',
        icon: Icons.warning_amber_rounded,
        badge: m.overdueCount > 0 ? '${m.overdueCount} Overdue' : 'Clear',
      ),
    ];
  }

  @override
  void initState() {
    super.initState();
    _restartTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _restartTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(_slideInterval, (_) {
      if (_hovering || !mounted) return;
      _goTo((_index + 1) % _buildSlides().length, 1);
    });
  }

  void _goTo(int next, int direction) {
    if (!mounted || next == _index) return;
    setState(() {
      _direction = direction;
      _index = next;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final slides = _buildSlides();
    final active = slides[_index];

    return MouseRegion(
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: SizedBox(
        width: double.infinity,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              height: _cardHeight,
              child: Stack(
                children: [
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 600),
                    switchInCurve: Curves.easeOutCubic,
                    switchOutCurve: Curves.easeInCubic,
                    transitionBuilder: (child, animation) {
                      final curved = CurvedAnimation(
                        parent: animation,
                        curve: Curves.easeOutCubic,
                      );
                      final offset = Tween<Offset>(
                        begin: Offset(0.12 * _direction, 0),
                        end: Offset.zero,
                      ).animate(curved);
                      return ClipRect(
                        child: FadeTransition(
                          opacity: curved,
                          child: SlideTransition(
                            position: offset,
                            child: ScaleTransition(
                              scale: Tween<double>(begin: 0.96, end: 1.0)
                                  .animate(curved),
                              child: child,
                            ),
                          ),
                        ),
                      );
                    },
                    child: SizedBox(
                      key: ValueKey<int>(_index),
                      width: double.infinity,
                      height: double.infinity,
                      child: _MetricSlideCard(
                        data: active,
                        isDark: isDark,
                        isLoading: widget.isLoading,
                      ),
                    ),
                  ),
                  Positioned(
                    left: 12,
                    top: 0,
                    bottom: 0,
                    child: Center(
                      child: _NavArrow(
                        icon: Icons.chevron_left_rounded,
                        isDark: isDark,
                        onTap: () => _goTo(
                          (_index - 1 + slides.length) % slides.length,
                          -1,
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    right: 12,
                    top: 0,
                    bottom: 0,
                    child: Center(
                      child: _NavArrow(
                        icon: Icons.chevron_right_rounded,
                        isDark: isDark,
                        onTap: () =>
                            _goTo((_index + 1) % slides.length, 1),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            _DotsIndicator(
              count: slides.length,
              activeIndex: _index,
              isDark: isDark,
              onTap: (i) => _goTo(i, i >= _index ? 1 : -1),
            ),
          ],
        ),
      ),
    );
  }
}

class _MetricSlideCard extends StatelessWidget {
  final _SlideMetric data;
  final bool isDark;
  final bool isLoading;

  const _MetricSlideCard({
    required this.data,
    required this.isDark,
    required this.isLoading,
  });

  @override
  Widget build(BuildContext context) {
    final cardBg = AppColors.cardBgColor(isDark);
    final primaryTextColor = AppColors.textPrimaryColor(isDark);
    final secondaryTextColor = AppColors.textSecondaryColor(isDark);
    final border = AppColors.borderDarkColor(isDark);
    final accent = AppColors.brandPrimary;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(data.icon, color: accent, size: 30),
          ),
          const SizedBox(height: 18),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Opacity(
              opacity: isLoading ? 0.6 : 1.0,
              child: Text(
                data.value,
                maxLines: 1,
                style: TextStyle(
                  fontSize: 40,
                  fontWeight: FontWeight.w800,
                  color: primaryTextColor,
                  letterSpacing: -1.0,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            data.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: secondaryTextColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            data.subtitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: secondaryTextColor,
            ),
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              data.badge,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: isDark ? accent : AppColors.brandPrimaryDark,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NavArrow extends StatefulWidget {
  final IconData icon;
  final bool isDark;
  final VoidCallback onTap;

  const _NavArrow({
    required this.icon,
    required this.isDark,
    required this.onTap,
  });

  @override
  State<_NavArrow> createState() => _NavArrowState();
}

class _NavArrowState extends State<_NavArrow> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    final accent = AppColors.brandPrimary;
    final bg = _hovering
        ? accent.withValues(alpha: widget.isDark ? 0.28 : 0.16)
        : (widget.isDark ? Colors.black45 : Colors.white);
    final iconColor = _hovering
        ? (widget.isDark ? Colors.white : Colors.black)
        : (widget.isDark ? Colors.white70 : Colors.black54);
    final borderColor = widget.isDark ? Colors.white24 : Colors.black12;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: bg,
            shape: BoxShape.circle,
            border: Border.all(color: _hovering ? accent : borderColor),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.15),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Icon(widget.icon, color: iconColor, size: 24),
        ),
      ),
    );
  }
}

class _DotsIndicator extends StatelessWidget {
  final int count;
  final int activeIndex;
  final bool isDark;
  final ValueChanged<int> onTap;

  const _DotsIndicator({
    required this.count,
    required this.activeIndex,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final inactive = isDark ? Colors.white24 : Colors.black26;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(count, (i) {
        final active = i == activeIndex;
        return GestureDetector(
          onTap: () => onTap(i),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
            margin: const EdgeInsets.symmetric(horizontal: 3),
            width: active ? 22 : 7,
            height: 7,
            decoration: BoxDecoration(
              color: active ? AppColors.brandPrimary : inactive,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        );
      }),
    );
  }
}

class _SlideMetric {
  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final String badge;

  const _SlideMetric({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.badge,
  });
}