import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../utils/format_utils.dart';

class UsageChart extends StatelessWidget {
  const UsageChart({super.key, required this.dataByKeyName});

  final Map<String, int> dataByKeyName;

  @override
  Widget build(BuildContext context) {
    if (dataByKeyName.isEmpty) {
      return Container(
        height: 120,
        alignment: Alignment.center,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.bar_chart_rounded,
                color: AppTheme.textMuted.withValues(alpha: 0.4), size: 32),
            const SizedBox(height: 8),
            Text(
              'No data transfer yet',
              style: TextStyle(
                color: AppTheme.textMuted.withValues(alpha: 0.6),
                fontSize: 13,
              ),
            ),
          ],
        ),
      );
    }

    final entries = dataByKeyName.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final maxVal = entries.first.value.toDouble();
    final gradientColors = [
      [AppTheme.primary, AppTheme.accentBright],
      [AppTheme.accent, const Color(0xFF4EEAFF)],
      [AppTheme.purple, const Color(0xFFAE8FFF)],
      [AppTheme.warning, const Color(0xFFFFD97A)],
      [AppTheme.danger, const Color(0xFFFF8FA3)],
    ];

    return SizedBox(
      height: entries.length * 48.0 + 16,
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceEvenly,
          maxY: maxVal * 1.15,
          barTouchData: BarTouchData(
            touchTooltipData: BarTouchTooltipData(
              tooltipRoundedRadius: 12,
              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                final entry = entries[group.x.toInt()];
                return BarTooltipItem(
                  '${entry.key}\n',
                  const TextStyle(
                    color: AppTheme.textPrimary,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                  children: [
                    TextSpan(
                      text: FormatUtils.formatBytes(entry.value),
                      style: TextStyle(
                        color: gradientColors[
                                group.x.toInt() % gradientColors.length]
                            .first,
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          titlesData: FlTitlesData(
            show: true,
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 32,
                getTitlesWidget: (value, meta) {
                  final idx = value.toInt();
                  if (idx < 0 || idx >= entries.length) {
                    return const SizedBox.shrink();
                  }
                  final name = entries[idx].key;
                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      name.length > 8 ? '${name.substring(0, 7)}…' : name,
                      style: const TextStyle(
                        color: AppTheme.textMuted,
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  );
                },
              ),
            ),
            leftTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false)),
          ),
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: maxVal / 3,
            getDrawingHorizontalLine: (value) => FlLine(
              color: AppTheme.border.withValues(alpha: 0.3),
              strokeWidth: 0.8,
              dashArray: [4, 4],
            ),
          ),
          borderData: FlBorderData(show: false),
          barGroups: List.generate(entries.length, (i) {
            final colors = gradientColors[i % gradientColors.length];
            return BarChartGroupData(
              x: i,
              barRods: [
                BarChartRodData(
                  toY: entries[i].value.toDouble(),
                  width: entries.length <= 3 ? 28 : 18,
                  borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(8)),
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: colors,
                  ),
                  backDrawRodData: BackgroundBarChartRodData(
                    show: true,
                    toY: maxVal * 1.15,
                    color: AppTheme.surfaceDim.withValues(alpha: 0.25),
                  ),
                ),
              ],
            );
          }),
        ),
        duration: const Duration(milliseconds: 300),
      ),
    );
  }
}
