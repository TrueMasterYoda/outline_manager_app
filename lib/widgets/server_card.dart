import 'dart:math';

import 'package:flutter/material.dart';

import '../models/server_config.dart';
import '../theme/app_theme.dart';
import 'gradient_card.dart';
import 'sparkline_chart.dart';

class ServerCard extends StatelessWidget {
  const ServerCard({
    super.key,
    required this.config,
    required this.onTap,
    this.onDelete,
    this.isOnline,
    this.keyCount,
    this.totalTransfer,
  });

  final ServerConfig config;
  final VoidCallback onTap;
  final VoidCallback? onDelete;
  final bool? isOnline;
  final int? keyCount;
  final String? totalTransfer;

  @override
  Widget build(BuildContext context) {
    // Dummy data for the sparkline to match the visual design
    final random = Random(config.id.hashCode);
    final dataPoints = List.generate(10, (_) => 2 + random.nextDouble() * 5);

    final statusColor = (isOnline ?? false) ? AppTheme.accent : AppTheme.danger;

    return GradientCard(
      onTap: onTap,
      gradient: AppTheme.cardGradient,
      padding: EdgeInsets.zero,
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header: Name + Arrow
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        config.displayName,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontSize: 18,
                            ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const Icon(
                      Icons.chevron_right_rounded,
                      color: AppTheme.textSecondary,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                // Status + IP
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: AppTheme.statusDot(statusColor),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      (isOnline ?? false) ? 'Reachable' : 'Unreachable',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: statusColor,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      '•',
                      style: TextStyle(color: AppTheme.borderLight),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        config.host,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              fontFamily: 'monospace',
                              letterSpacing: 0.5,
                            ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                // Chart area
                SizedBox(
                  height: 60,
                  child: SparklineChart(
                    dataPoints: dataPoints,
                    color: AppTheme.primary,
                    height: 60,
                  ),
                ),
                const SizedBox(height: 16),
                // Footer stats
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'DATA TRANSFER (24H)',
                          style:
                              Theme.of(context).textTheme.labelSmall?.copyWith(
                                    color: AppTheme.textMuted,
                                    fontSize: 10,
                                    letterSpacing: 0.5,
                                  ),
                        ),
                        const SizedBox(height: 4),
                        RichText(
                          text: TextSpan(
                            style: Theme.of(context).textTheme.bodyMedium,
                            children: [
                              TextSpan(
                                text: totalTransfer ?? '0 GB',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  color: AppTheme.textPrimary,
                                ),
                              ),
                              TextSpan(
                                text: ' / 1 TB', // Placeholder limit
                                style: TextStyle(
                                  color: AppTheme.textMuted.withValues(alpha: 0.5),
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    if (keyCount != null)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            'ACCESS KEYS',
                            style: Theme.of(context)
                                .textTheme
                                .labelSmall
                                ?.copyWith(
                                  color: AppTheme.textMuted,
                                  fontSize: 10,
                                  letterSpacing: 0.5,
                                ),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppTheme.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '$keyCount',
                              style: const TextStyle(
                                color: AppTheme.primary,
                                fontWeight: FontWeight.w700,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ],
            ),
          ),
          // Left accent bar
          Positioned(
            left: 0,
            top: 20,
            bottom: 20,
            child: Container(
              width: 4,
              decoration: BoxDecoration(
                color: (isOnline ?? false) ? AppTheme.accent : AppTheme.danger,
                borderRadius: const BorderRadius.only(
                  topRight: Radius.circular(4),
                  bottomRight: Radius.circular(4),
                ),
                boxShadow: [
                  BoxShadow(
                    color: ((isOnline ?? false)
                            ? AppTheme.accent
                            : AppTheme.danger)
                        .withValues(alpha: 0.5),
                    blurRadius: 6,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

