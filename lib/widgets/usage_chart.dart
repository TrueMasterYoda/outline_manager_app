import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../utils/format_utils.dart';

/// Horizontal bar chart showing data usage per access key.
class UsageChart extends StatelessWidget {
  const UsageChart({
    super.key,
    required this.dataByKeyName,
  });

  /// Map of key name/id -> bytes transferred.
  final Map<String, int> dataByKeyName;

  @override
  Widget build(BuildContext context) {
    if (dataByKeyName.isEmpty) {
      return Container(
        height: 120,
        alignment: Alignment.center,
        child: Text(
          'No transfer data yet',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      );
    }

    final entries = dataByKeyName.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final topEntries = entries.take(8).toList();
    final maxVal =
        topEntries.isEmpty ? 1.0 : topEntries.first.value.toDouble();

    return SizedBox(
      height: (topEntries.length * 44).toDouble().clamp(80, 350),
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: maxVal * 1.15,
          barTouchData: BarTouchData(
            touchTooltipData: BarTouchTooltipData(
              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                final entry = topEntries[group.x.toInt()];
                return BarTooltipItem(
                  '${entry.key}\n${FormatUtils.formatBytes(entry.value)}',
                  const TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                );
              },
            ),
          ),
          titlesData: FlTitlesData(
            show: true,
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  final idx = value.toInt();
                  if (idx < 0 || idx >= topEntries.length) {
                    return const SizedBox.shrink();
                  }
                  final name = topEntries[idx].key;
                  return Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      name.length > 8 ? '${name.substring(0, 8)}…' : name,
                      style: const TextStyle(
                        color: AppTheme.textMuted,
                        fontSize: 10,
                      ),
                    ),
                  );
                },
                reservedSize: 28,
              ),
            ),
            leftTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
          ),
          gridData: const FlGridData(show: false),
          borderData: FlBorderData(show: false),
          barGroups: topEntries.asMap().entries.map((e) {
            final idx = e.key;
            final val = e.value.value.toDouble();
            return BarChartGroupData(
              x: idx,
              barRods: [
                BarChartRodData(
                  toY: val,
                  width: 20,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(6),
                  ),
                  gradient: AppTheme.primaryGradient,
                ),
              ],
            );
          }).toList(),
        ),
        duration: const Duration(milliseconds: 400),
      ),
    );
  }
}
