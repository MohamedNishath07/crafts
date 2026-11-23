import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_colors.dart';
import '../../domain/dashboard_models.dart';

/// A full-width, auto-advancing carousel of the six overview metric cards.
///
/// Built on a [PageController] + [PageView] so it supports native swipe /
/// drag gestures, programmatic navigation (arrows, dots) and auto-play.
/// Auto-play advances every [_autoPlayInterval] and pauses while hovered.
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
  static const Duration _autoPlayInterval = Duration(seconds: 4);
  static const Duration _transition = Duration(milliseconds: 500);
  static const double _cardHeight = 340;

  late final PageController _pageController;
  Timer? _autoPlayTimer;
  int _currentPage = 0;
  bool _isHovered = false;

  List<_SlideMetric> get _slides => _buildSlides();

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _pageController.addListener(_syncCurrentPage);
    _startAutoPlay();
  }

  @override
  void dispose() {
    _autoPlayTimer?.cancel();
    _pageController.removeListener(_syncCurrentPage);
    _pageController.dispose();
    super.dispose();
  }

  void _syncCurrentPage() {
    final page = _pageController.hasClients ? _pageController.page?.round() : null;
    if (page != null && page != _currentPage && mounted) {
      setState(() => _currentPage = page);
    }
  }

  void _startAutoPlay() {
    _autoPlayTimer?.cancel();
    _autoPlayTimer = Timer.periodic(_autoPlayInterval, (_) {
      if (_isHovered || !_pageController.hasClients || _slides.length < 2) {
        return;
      }
      _animateTo((_currentPage + 1) % _slides.length);
    });
  }

  void _animateTo(int index) {
    if (!_pageController.hasClients) return;
    _pageController.animateToPage(
      index,
      duration: _transition,
      curve: Curves.easeOutCubic,
    );
  }

  void _step(int delta) {
    final total = _slides.length;
    if (total < 2) return;
    _animateTo((_currentPage + delta + total) % total);
  }

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
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final slides = _slides;
    final showArrows = slides.length > 1;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
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
                  PageView(
                    controller: _pageController,
                    physics: const PageScrollPhysics(),
                    children: [
                      for (final slide in slides)
                        _MetricSlideCard(
                          key: ValueKey(slide.title),
                          data: slide,
                          isDark: isDark,
                          isLoading: widget.isLoading,
                        ),
                    ],
                  ),
                  if (showArrows) ...[
                    Positioned(
                      left: 12,
                      top: 0,
                      bottom: 0,
                      child: Center(
                        child: _NavArrow(
                          icon: Icons.chevron_left_rounded,
                          isDark: isDark,
                          onTap: () => _step(-1),
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
                          onTap: () => _step(1),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (showArrows) ...[
              const SizedBox(height: 14),
              _DotsIndicator(
                count: slides.length,
                activeIndex: _currentPage,
                isDark: isDark,
                onTap: _animateTo,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Immutable view-model for a single metric slide.
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

/// Reusable metric card rendered inside each [PageView] page.
class _MetricSlideCard extends StatelessWidget {
  final _SlideMetric data;
  final bool isDark;
  final bool isLoading;

  const _MetricSlideCard({
    super.key,
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

    return Semantics(
      label: '${data.title}: ${data.value}. ${data.subtitle}',
      child: Container(
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
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
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
      ),
    );
  }
}

/// Circular previous/next control with hover feedback.
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

/// Page position indicator; tap a dot to jump to that slide.
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