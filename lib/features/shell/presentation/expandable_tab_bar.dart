import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';

class ExpandableTabBar extends ConsumerStatefulWidget {
  final List<TabBarItem> items;
  final String currentPath;
  const ExpandableTabBar({super.key, required this.items, required this.currentPath});

  @override
  ConsumerState<ExpandableTabBar> createState() => _ExpandableTabBarState();
}

class TabBarItem {
  final String route;
  final String label;
  final IconData icon;
  const TabBarItem({required this.route, required this.label, required this.icon});
}

class _ExpandableTabBarState extends ConsumerState<ExpandableTabBar> {
  bool _expanded = false;

  static const _primaryCount = 4;

  void _toggle() => setState(() => _expanded = !_expanded);

  @override
  Widget build(BuildContext context) {
    final primary = widget.items.take(_primaryCount).toList();
    final rest = widget.items.skip(_primaryCount).toList();

    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.bottomCenter,
      children: [
        if (_expanded)
          Positioned.fill(
            child: GestureDetector(
              onTap: _toggle,
              child: Container(color: Colors.black.withValues(alpha: 0.4)),
            ),
          ),
        Container(
          decoration: BoxDecoration(
            color: AppColors.surfaceBase,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
             border: Border.all(color: AppColors.accentSuccess, width: 1.5),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.25),
                blurRadius: 16,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_expanded) ...[
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  alignment: WrapAlignment.center,
                  children: rest.map(_buildExpandedItem).toList(),
                ),
                const SizedBox(height: 8),
              ],
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  ...primary.map(_buildTab),
                  _buildExpandButton(),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTab(TabBarItem item) {
    final selected = widget.currentPath == item.route;
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () => context.go(item.route),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(item.icon,
                color: selected ? AppColors.accentSuccess : AppColors.inkMuted,
                size: 24),
            const SizedBox(height: 2),
            Text(item.label,
                style: TextStyle(
                    fontSize: 10,
                    color: selected ? AppColors.accentSuccess : AppColors.inkMuted,
                    fontWeight: selected ? FontWeight.w600 : FontWeight.normal)),
          ],
        ),
      ),
    );
  }

  Widget _buildExpandedItem(TabBarItem item) {
    final selected = widget.currentPath == item.route;
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () {
        _toggle();
        context.go(item.route);
      },
      child: Container(
        width: 72,
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(item.icon,
                color: selected ? AppColors.accentSuccess : AppColors.inkPrimary,
                size: 22),
            const SizedBox(height: 4),
            Text(item.label,
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 10,
                    color: selected ? AppColors.accentSuccess : AppColors.inkPrimary)),
          ],
        ),
      ),
    );
  }

  Widget _buildExpandButton() {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: _toggle,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedRotation(
              turns: _expanded ? 0.5 : 0.0,
              duration: const Duration(milliseconds: 300),
              child: const Icon(Icons.expand_less,
                  color: AppColors.inkMuted, size: 24),
            ),
            const SizedBox(height: 2),
            const Text('More',
                style: TextStyle(fontSize: 10, color: AppColors.inkMuted)),
          ],
        ),
      ),
    );
  }
}
