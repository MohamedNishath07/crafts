import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../domain/dashboard_models.dart';

class DashboardAnalyticsSection extends StatefulWidget {
  final ChartAnalyticsData analytics;
  final DashboardDateFilter selectedFilter;
  final Function(DashboardDateFilter) onFilterChanged;

  const DashboardAnalyticsSection({
    super.key,
    required this.analytics,
    required this.selectedFilter,
    required this.onFilterChanged,
  });

  @override
  State<DashboardAnalyticsSection> createState() => _DashboardAnalyticsSectionState();
}

class _DashboardAnalyticsSectionState extends State<DashboardAnalyticsSection> {
  int _selectedChartTypeIndex = 0; // 0 = Trends, 1 = Credit vs Collection, 2 = Status / Aging

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = AppColors.cardBgColor(isDark);
    final primaryTextColor = AppColors.textPrimaryColor(isDark);
    final secondaryTextColor = AppColors.textSecondaryColor(isDark);
    final borderDark = AppColors.borderDarkColor(isDark);
    final surfaceRaised = AppColors.surfaceRaisedColor(isDark);
    final currencyFmt = NumberFormat.currency(symbol: '\$', decimalDigits: 2);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: borderDark,
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
          // Section Header: Title & Date Filters
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Financial Analytics',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: primaryTextColor,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Performance insights & collection trends',
                      style: TextStyle(
                        fontSize: 12,
                        color: secondaryTextColor,
                      ),
                    ),
                  ],
                ),
              ),

              // Date Filter Segmented Buttons (This Week, This Month, This Year)
              Container(
                decoration: BoxDecoration(
                  color: surfaceRaised,
                  borderRadius: BorderRadius.circular(10),
                ),
                padding: const EdgeInsets.all(3),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: DashboardDateFilter.values.map((filter) {
                    final isSelected = widget.selectedFilter == filter;
                    return GestureDetector(
                      onTap: () => widget.onFilterChanged(filter),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.cardBgColor(isDark)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: isSelected
                              ? [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.06),
                                    blurRadius: 4,
                                    offset: const Offset(0, 1),
                                  ),
                                ]
                              : null,
                        ),
                        child: Text(
                          filter.label,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                            color: isSelected
                                ? (isDark ? Colors.white : AppColors.brandPrimary)
                                : secondaryTextColor,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Chart Type Selector Tabs
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildChartTypeTab(0, 'Collection Trend', Icons.show_chart_rounded, isDark),
                const SizedBox(width: 8),
                _buildChartTypeTab(1, 'Credit vs Collections', Icons.bar_chart_rounded, isDark),
                const SizedBox(width: 8),
                _buildChartTypeTab(2, 'Portfolio Status & Aging', Icons.pie_chart_outline_rounded, isDark),
              ],
            ),
          ),

          const SizedBox(height: 16),
          const Divider(height: 1),
          const SizedBox(height: 20),

          // Render active chart view
          if (_selectedChartTypeIndex == 0)
            _buildCollectionTrendChart(isDark, currencyFmt)
          else if (_selectedChartTypeIndex == 1)
            _buildCreditVsCollectionChart(isDark, currencyFmt)
          else
            _buildPortfolioStatusChart(isDark, currencyFmt),
        ],
      ),
    );
  }

  Widget _buildChartTypeTab(int index, String label, IconData icon, bool isDark) {
    final isSelected = _selectedChartTypeIndex == index;
    return InkWell(
      onTap: () => setState(() => _selectedChartTypeIndex = index),
      borderRadius: BorderRadius.circular(10),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.brandPrimary.withValues(alpha: isDark ? 0.25 : 0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected
                ? AppColors.brandPrimary
                : AppColors.borderDarkColor(isDark),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected ? AppColors.brandPrimary : AppColors.textSecondaryColor(isDark),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              color: isSelected ? AppColors.brandPrimary : AppColors.textSecondaryColor(isDark),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 1. Collection Trend Line Chart
  Widget _buildCollectionTrendChart(bool isDark, NumberFormat currencyFmt) {
    final points = widget.analytics.points;

    if (points.isEmpty) {
      return _buildEmptyChartState('No collection data recorded for ${widget.selectedFilter.label}.');
    }

    final spots = <FlSpot>[];
    for (int i = 0; i < points.length; i++) {
      spots.add(FlSpot(i.toDouble(), points[i].collectionAmount));
    }

    final maxY = widget.analytics.maxChartValue;

    return Column(
      children: [
        // KPI summary header for chart
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.brandPrimary,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  'Collected: ${currencyFmt.format(widget.analytics.totalCollectedInPeriod)}',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: AppColors.brandPrimary,
                  ),
                ),
              ],
            ),
            Text(
              '${widget.selectedFilter.label} Performance',
              style: TextStyle(
                fontSize: 12,
                color: AppColors.textSecondaryColor(isDark),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        SizedBox(
          height: 220,
          child: LineChart(
            LineChartData(
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                horizontalInterval: maxY > 0 ? (maxY / 4) : 100,
                getDrawingHorizontalLine: (value) => FlLine(
                  color: AppColors.borderSubtleColor(isDark).withValues(alpha: 0.5),
                  strokeWidth: 1,
                  dashArray: [4, 4],
                ),
              ),
              titlesData: FlTitlesData(
                show: true,
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 42,
                    interval: maxY > 0 ? (maxY / 4) : 100,
                    getTitlesWidget: (value, meta) {
                      return Text(
                        NumberFormat.compactCurrency(symbol: '\$', decimalDigits: 0).format(value),
                        style: TextStyle(
                          color: AppColors.textSecondaryColor(isDark),
                          fontSize: 10,
                        ),
                      );
                    },
                  ),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 28,
                    interval: 1,
                    getTitlesWidget: (value, meta) {
                      final idx = value.toInt();
                      if (idx >= 0 && idx < points.length) {
                        return Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Text(
                            points[idx].label,
                            style: TextStyle(
                              color: AppColors.textSecondaryColor(isDark),
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        );
                      }
                      return const SizedBox.shrink();
                    },
                  ),
                ),
              ),
              borderData: FlBorderData(show: false),
              minY: 0,
              maxY: maxY > 0 ? maxY : 100,
              lineTouchData: LineTouchData(
                touchTooltipData: LineTouchTooltipData(
                  getTooltipItems: (touchedSpots) {
                    return touchedSpots.map((spot) {
                      final idx = spot.x.toInt();
                      final label = idx >= 0 && idx < points.length ? points[idx].label : '';
                      return LineTooltipItem(
                        '$label\nCollected: ${currencyFmt.format(spot.y)}',
                        const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      );
                    }).toList();
                  },
                ),
              ),
              lineBarsData: [
                LineChartBarData(
                  spots: spots,
                  isCurved: true,
                  curveSmoothness: 0.35,
                  color: AppColors.brandPrimary,
                  barWidth: 3,
                  isStrokeCapRound: true,
                  dotData: FlDotData(
                    show: true,
                    getDotPainter: (spot, percent, barData, index) => FlDotCirclePainter(
                      radius: 4,
                      color: Colors.white,
                      strokeWidth: 2.5,
                      strokeColor: AppColors.brandPrimary,
                    ),
                  ),
                  belowBarData: BarAreaData(
                    show: true,
                    gradient: LinearGradient(
                      colors: [
                        AppColors.brandPrimary.withValues(alpha: 0.28),
                        AppColors.brandPrimary.withValues(alpha: 0.02),
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// 2. Credit vs Collection Comparison Grouped Bar Chart
  Widget _buildCreditVsCollectionChart(bool isDark, NumberFormat currencyFmt) {
    final points = widget.analytics.points;

    if (points.isEmpty) {
      return _buildEmptyChartState('No comparison data available.');
    }

    final maxY = widget.analytics.maxChartValue;

    return Column(
      children: [
        // Legend
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                _buildLegendItem(AppColors.brandPrimary, 'Credit Billed'),
                const SizedBox(width: 14),
                _buildLegendItem(AppColors.brandPrimary, 'Collections'),
              ],
            ),
            Text(
              'Ratio: ${widget.analytics.totalBilledInPeriod > 0 ? ((widget.analytics.totalCollectedInPeriod / widget.analytics.totalBilledInPeriod) * 100).toStringAsFixed(0) : 0}%',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimaryColor(isDark),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        SizedBox(
          height: 220,
          child: BarChart(
            BarChartData(
              maxY: maxY > 0 ? maxY : 100,
              barTouchData: BarTouchData(
                touchTooltipData: BarTouchTooltipData(
                  getTooltipItem: (group, groupIndex, rod, rodIndex) {
                    final label = groupIndex >= 0 && groupIndex < points.length ? points[groupIndex].label : '';
                    final type = rodIndex == 0 ? 'Credit' : 'Collected';
                    return BarTooltipItem(
                      '$label ($type)\n${currencyFmt.format(rod.toY)}',
                      const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    );
                  },
                ),
              ),
              titlesData: FlTitlesData(
                show: true,
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 42,
                    interval: maxY > 0 ? (maxY / 4) : 100,
                    getTitlesWidget: (value, meta) {
                      return Text(
                        NumberFormat.compactCurrency(symbol: '\$', decimalDigits: 0).format(value),
                        style: TextStyle(
                          color: AppColors.textSecondaryColor(isDark),
                          fontSize: 10,
                        ),
                      );
                    },
                  ),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 28,
                    getTitlesWidget: (value, meta) {
                      final idx = value.toInt();
                      if (idx >= 0 && idx < points.length) {
                        return Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Text(
                            points[idx].label,
                            style: TextStyle(
                              color: AppColors.textSecondaryColor(isDark),
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        );
                      }
                      return const SizedBox.shrink();
                    },
                  ),
                ),
              ),
              borderData: FlBorderData(show: false),
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                horizontalInterval: maxY > 0 ? (maxY / 4) : 100,
                getDrawingHorizontalLine: (value) => FlLine(
                  color: AppColors.borderSubtleColor(isDark).withValues(alpha: 0.5),
                  strokeWidth: 1,
                  dashArray: [4, 4],
                ),
              ),
              barGroups: List.generate(points.length, (index) {
                final pt = points[index];
                return BarChartGroupData(
                  x: index,
                  barsSpace: 4,
                  barRods: [
                    BarChartRodData(
                      toY: pt.creditAmount,
                      color: AppColors.borderDarkColor(isDark),
                      width: 9,
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                    ),
                    BarChartRodData(
                      toY: pt.collectionAmount,
                      color: AppColors.brandPrimary,
                      width: 9,
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                    ),
                  ],
                );
              }),
            ),
          ),
        ),
      ],
    );
  }

  /// 3. Portfolio Breakdown & Aging Analysis
  Widget _buildPortfolioStatusChart(bool isDark, NumberFormat currencyFmt) {
    final status = widget.analytics.statusBreakdown;
    final aging = widget.analytics.agingBreakdown;

    final current = status['Current'] ?? 0.0;
    final overdue = status['Overdue'] ?? 0.0;
    final settled = status['Settled'] ?? 0.0;
    final total = current + overdue + settled;

    if (total == 0) {
      return _buildEmptyChartState('No portfolio records to display.');
    }

    final sections = <PieChartSectionData>[];
    if (current > 0) {
      sections.add(PieChartSectionData(
        value: current,
        color: AppColors.brandPrimary,
        radius: 36,
        showTitle: false,
      ));
    }
    if (overdue > 0) {
      sections.add(PieChartSectionData(
        value: overdue,
        color: AppColors.brandPrimary,
        radius: 36,
        showTitle: false,
      ));
    }
    if (settled > 0) {
      sections.add(PieChartSectionData(
        value: settled,
        color: AppColors.brandPrimary,
        radius: 36,
        showTitle: false,
      ));
    }

    return Column(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Donut Chart
            SizedBox(
              width: 130,
              height: 130,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  PieChart(
                    PieChartData(
                      sections: sections,
                      sectionsSpace: 2,
                      centerSpaceRadius: 36,
                    ),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Total',
                        style: TextStyle(
                          fontSize: 10,
                          color: AppColors.textSecondaryColor(isDark),
                        ),
                      ),
                      Text(
                        NumberFormat.compactCurrency(symbol: '\$', decimalDigits: 1).format(total),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimaryColor(isDark),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 20),

            // Portfolio Legend & Percentages
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildStatusRow('Current Balances', current, total, AppColors.brandPrimary, currencyFmt, isDark),
                  const SizedBox(height: 8),
                  _buildStatusRow('Overdue Balances', overdue, total, AppColors.brandPrimary, currencyFmt, isDark),
                  const SizedBox(height: 8),
                  _buildStatusRow('Settled / Recovered', settled, total, AppColors.brandPrimary, currencyFmt, isDark),
                ],
              ),
            ),
          ],
        ),

        const SizedBox(height: 18),
        const Divider(height: 1),
        const SizedBox(height: 14),

        // Aging Schedule Breakdown
        Align(
          alignment: Alignment.centerLeft,
          child: Text(
            'Aging Schedule (Outstanding Portfolio)',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimaryColor(isDark),
            ),
          ),
        ),
        const SizedBox(height: 10),

        Row(
          children: [
            _buildAgingBadge('Current', aging['Current'] ?? 0.0, AppColors.brandPrimary, currencyFmt, isDark),
            const SizedBox(width: 6),
            _buildAgingBadge('1-30 D', aging['1-30 DPD'] ?? 0.0, AppColors.brandPrimary, currencyFmt, isDark),
            const SizedBox(width: 6),
            _buildAgingBadge('31-60 D', aging['31-60 DPD'] ?? 0.0, AppColors.brandPrimary, currencyFmt, isDark),
            const SizedBox(width: 6),
            _buildAgingBadge('61-90 D', aging['61-90 DPD'] ?? 0.0, AppColors.brandPrimary, currencyFmt, isDark),
            const SizedBox(width: 6),
            _buildAgingBadge('90+ D', aging['90+ DPD'] ?? 0.0, AppColors.brandPrimary, currencyFmt, isDark),
          ],
        ),
      ],
    );
  }

  Widget _buildStatusRow(
    String label,
    double amount,
    double total,
    Color color,
    NumberFormat currencyFmt,
    bool isDark,
  ) {
    final pct = total > 0 ? (amount / total) * 100 : 0.0;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(shape: BoxShape.circle, color: color),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: AppColors.textSecondaryColor(isDark),
              ),
            ),
          ],
        ),
        Text(
          '${currencyFmt.format(amount)} (${pct.toStringAsFixed(0)}%)',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimaryColor(isDark),
          ),
        ),
      ],
    );
  }

  Widget _buildAgingBadge(
    String title,
    double amount,
    Color color,
    NumberFormat currencyFmt,
    bool isDark,
  ) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        decoration: BoxDecoration(
          color: color.withValues(alpha: isDark ? 0.15 : 0.08),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 2),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                NumberFormat.compactCurrency(symbol: '\$', decimalDigits: 0).format(amount),
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimaryColor(isDark),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegendItem(Color color, String text) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          text,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyChartState(String message) {
    return Container(
      height: 180,
      alignment: Alignment.center,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.insert_chart_outlined_rounded, size: 40, color: AppColors.inkSecondary),
          const SizedBox(height: 8),
          Text(
            message,
            style: const TextStyle(fontSize: 12, color: AppColors.inkSecondary),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
