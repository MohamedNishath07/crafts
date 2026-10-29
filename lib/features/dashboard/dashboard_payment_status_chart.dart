import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:crafts/core/constants/app_colors.dart';

/// Widget that displays payment status breakdown donut chart
/// Shows proportion of Current, Overdue, and Settled debts
class PaymentStatusChart extends StatelessWidget {
  final Map<String, double> statusData;
  final Map<String, Color> colorScheme;

  const PaymentStatusChart({
    required this.statusData,
    required this.colorScheme,
    super.key,
  });

  /// Pre-configured with typical debt status distribution
  PaymentStatusChart.typical({
    super.key,
  })  : statusData = {'Current': 50000.00, 'Overdue': 15000.00, 'Settled': 40000.00},
        colorScheme = {
          'Current': AppColors.accentSuccess,
          'Overdue': AppColors.accentDanger,
          'Settled': AppColors.brandPrimary,
        };

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Calculate total for percentage calculations
    final total = statusData.values.reduce((a, b) => a + b);

    return PieChart(
      PieChartData(
        pieTouchData: PieTouchData(
          enabled: true,
        ),
        borderData: FlBorderData(show: false),
        sectionsSpace: 0,
        centerSpaceRadius: 40,
        sections: _buildPieSections(statusData, colorScheme, isDark, total),
      ),
    );
  }

  /// Builds pie chart sections from status data
  List<PieChartSectionData> _buildPieSections(
      Map<String, double> data,
      Map<String, Color> colors,
      bool isDark,
      double total,
      ) {
    final entries = <PieChartSectionData>[];

    data.forEach((label, value) {
      final percentage = total > 0 ? (value / total) * 100 : 0.0;
      final color = colors[label] ?? AppColors.inkSecondary;

      entries.add(PieChartSectionData(
        color: color,
        value: percentage,
        title: '$label ${percentage.toStringAsFixed(1)}%',
        titleStyle: TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
        radius: 60,
      ));


    });

    return entries;
  }
}