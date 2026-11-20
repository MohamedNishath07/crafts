import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';

class ExpandableTabBar extends ConsumerStatefulWidget {
  final List<TabBarItem> items;
  final String currentPath;
  const ExpandableTabBar({
    super.key,
    required this.items,
    required this.currentPath,
  });

  @override
  ConsumerState<ExpandableTabBar> createState() => _ExpandableTabBarState();
}

class TabBarItem {
  final String route;
  final String label;
  final IconData icon;
  const TabBarItem({
    required this.route,
    required this.label,
    required this.icon,
  });
}

class _ExpandableTabBarState extends ConsumerState<ExpandableTabBar>
    with SingleTickerProviderStateMixin {
  bool _expanded = false;
  late final AnimationController _expandController;
  late final Animation<double> _expandAnimation;

  static const int _primaryCount = 4;

  @override
  void initState() {
    super.initState();
    _expandController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _expandAnimation = CurvedAnimation(
      parent: _expandController,
      curve: Curves.easeInOutCubic,
    );
    if (_expanded) {
      _expandController.value = 1.0;
    }
  }

  @override
  void dispose() {
    _expandController.dispose();
    super.dispose();
  }

  void _toggle() {
    setState(() => _expanded = !_expanded);
    if (_expanded) {
      _expandController.forward();
    } else {
      _expandController.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final primary = widget.items.take(_primaryCount).toList();
    final rest = widget.items.skip(_primaryCount).toList();

    final surfaceColor = isDark
        ? AppColors.surfaceDarkCard
        : AppColors.surfaceCard;
    final borderColor = isDark
        ? const Color(0xFF4A4A60).withValues(alpha: 0.5)
        : const Color(0xFFC1C7D0).withValues(alpha: 0.5);
    final shadowColor = isDark
        ? Colors.black.withValues(alpha: 0.5)
        : Colors.black.withValues(alpha: 0.10);
    final selectedColor = colorScheme.primary;
    final unselectedColor = isDark
        ? const Color(0xFF9AA5B1)
        : const Color(0xFF8D99AE);
    final selectedSurfaceAlpha = isDark ? 0.22 : 0.10;

    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.bottomCenter,
      children: [
        if (_expanded)
          AnimatedBuilder(
            animation: _expandAnimation,
            builder: (context, child) {
              return Positioned.fill(
                child: GestureDetector(
                  onTap: _toggle,
                  child: Container(
                    color: Colors.black.withValues(
                      alpha: 0.35 * _expandAnimation.value.clamp(0.0, 1.0),
                    ),
                  ),
                ),
              );
            },
          ),
        AnimatedBuilder(
          animation: _expandAnimation,
          builder: (context, child) {
            return Container(
              decoration: BoxDecoration(
                color: surfaceColor,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(30),
                ),
                border: Border.all(color: borderColor, width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: shadowColor,
                    blurRadius: 28 * _expandAnimation.value.clamp(0.0, 1.0),
                    offset: const Offset(0, -10),
                    spreadRadius: 2,
                  ),
                ],
              ),
              clipBehavior: Clip.antiAlias,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_expanded) ...[
                    AnimatedSize(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOutCubic,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Wrap(
                            spacing: 12,
                            runSpacing: 12,
                            alignment: WrapAlignment.center,
                            children: rest
                                .map(
                                  (item) => _buildExpandedItem(
                                    item,
                                    selectedColor: selectedColor,
                                    unselectedColor: unselectedColor,
                                    selectedSurfaceAlpha: selectedSurfaceAlpha,
                                  ),
                                )
                                .toList(),
                          ),
                          const SizedBox(height: 10),
                        ],
                      ),
                    ),
                  ],
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      ...primary.map(
                        (item) => _buildTab(
                          item,
                          selectedColor: selectedColor,
                          unselectedColor: unselectedColor,
                          selectedSurfaceAlpha: selectedSurfaceAlpha,
                        ),
                      ),
                      _buildExpandButton(
                        selectedColor: selectedColor,
                        unselectedColor: unselectedColor,
                        surfaceColor: isDark
                            ? const Color(0xFF4A4A60).withValues(alpha: 0.5)
                            : const Color(0xFFECF0F1).withValues(alpha: 0.7),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildTab(
    TabBarItem item, {
    required Color selectedColor,
    required Color unselectedColor,
    required double selectedSurfaceAlpha,
  }) {
    final selected = widget.currentPath == item.route;

    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: () {
        context.go(item.route);
        if (_expanded) {
          setState(() => _expanded = false);
          _expandController.reverse();
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: selected
                    ? selectedColor.withValues(alpha: selectedSurfaceAlpha)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(13),
              ),
              child: Center(
                child: Icon(
                  item.icon,
                  color: selected ? selectedColor : unselectedColor,
                  size: 23,
                ),
              ),
            ),
            const SizedBox(height: 5),
            Text(
              item.label,
              style: TextStyle(
                fontSize: 9.5,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                color: selected ? selectedColor : unselectedColor,
                letterSpacing: 0.2,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExpandedItem(
    TabBarItem item, {
    required Color selectedColor,
    required Color unselectedColor,
    required double selectedSurfaceAlpha,
  }) {
    final selected = widget.currentPath == item.route;

    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: () {
        context.go(item.route);
        setState(() => _expanded = false);
        _expandController.reverse();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        width: 78,
        padding: const EdgeInsets.symmetric(vertical: 9),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: selected
                    ? selectedColor.withValues(alpha: selectedSurfaceAlpha)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Center(
                child: Icon(
                  item.icon,
                  color: selected ? selectedColor : unselectedColor,
                  size: 22,
                ),
              ),
            ),
            const SizedBox(height: 7),
            Text(
              item.label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 9,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                color: selected ? selectedColor : unselectedColor,
                letterSpacing: 0.2,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 2,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExpandButton({
    required Color selectedColor,
    required Color unselectedColor,
    required Color surfaceColor,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: _toggle,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedRotation(
              turns: _expanded ? 0.5 : 0.0,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOutCubic,
              child: Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: surfaceColor,
                  borderRadius: BorderRadius.circular(13),
                ),
                child: const Center(
                  child: Icon(
                    Icons.expand_less,
                    color: Color(0xFF8D99AE),
                    size: 22,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 5),
            Text(
              'More',
              style: TextStyle(
                fontSize: 9.5,
                fontWeight: FontWeight.w600,
                color: unselectedColor,
                letterSpacing: 0.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
