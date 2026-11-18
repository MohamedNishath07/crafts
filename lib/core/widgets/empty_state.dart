import 'package:flutter/material.dart';

/// Empty state widget shown when there is no data to display
class EmptyState extends StatelessWidget {
  final String? message;
  final IconData? iconData;
  final VoidCallback? onRetry;
  final String? retryLabel;

  const EmptyState({
    super.key,
    this.message,
    this.iconData,
    this.onRetry,
    this.retryLabel,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final msg = message ?? 'No data available';
    // Use a default icon if none provided
    final data = iconData ?? _kDefaultIcon;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            data,
            size: 64,
            color: theme.colorScheme.onSurface,
          ),
          const SizedBox(height: 16),
          Text(
            msg,
            style: theme.textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          if (onRetry != null)
            OutlinedButton(
              onPressed: onRetry,
              child: Text(retryLabel ?? 'Retry'),
            ),
        ],
      ),
    );
  }

  // Default fallback icon - use a constant from the material icon set
  static const IconData _kDefaultIcon = IconData(0xf02e, fontFamily: 'MaterialIcons');
}