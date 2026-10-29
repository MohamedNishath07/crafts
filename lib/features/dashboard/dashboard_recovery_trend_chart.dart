import 'dart:math';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:crafts/core/constants/app_colors.dart';

/// Widget that displays monthly recovery trend chart (line chart)
/// Shows recovery volume over the past 6 months
class RecoveryTrendChart extends StatelessWidget {
  final List<double> recoveryData;
  final List<String> monthLabels;

  const RecoveryTrendChart({
    required this.recoveryData,
    required this.monthLabels,
    super.key,
  });

  /// Pre-configured for past 6 months with sample data
  const RecoveryTrendChart.past6Months({
    super.key,
  })  : recoveryData = const [4500.00, 5200.00, 3800.00, 6100.00, 7000.00, 8500.00],
        monthLabels = const ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun'];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return LineChart(
      LineChartData(
        gridData: const FlGridData(show: true),
        titlesData: FlTitlesData(
          show: true,
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              interval: 2000,
              getTitlesWidget: (value, meta) {
                return Text(
                  '\$${value.toInt()}',
                  style: TextStyle(
                    color: isDark ? AppColors.inkPrimary : AppColors.inkSecondary,
                    fontSize: 10,
                  ),
                );
              },
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 32,
              interval: 1,
              getTitlesWidget: (value, meta) {
                final idx = value.toInt();
                if (idx >= 0 && idx < monthLabels.length) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      monthLabels[idx],
                      style: TextStyle(
                        color: isDark ? AppColors.inkPrimary : AppColors.inkSecondary,
                        fontSize: 10,
                      ),
                    ),
                  );
                }
                return const Text('');
              },
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          LineChartBarData(
            isCurved: true,
            color: AppColors.accentSuccess,
            barWidth: 3,
            dotData: const FlDotData(show: true),
            belowBarData: BarAreaData(show: false),
            spots: List.generate(recoveryData.length, (index) {
              return FlSpot(index.toDouble(), recoveryData[index]);
            }),
          ),
        ],
        maxY: recoveryData.isNotEmpty
            ? recoveryData.reduce(max) * 1.2
            : 10000,
        minY: 0,
      ),
    );
  }
}