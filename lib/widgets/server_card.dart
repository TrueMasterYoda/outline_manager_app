import 'package:flutter/material.dart';

import '../models/server_config.dart';
import '../theme/app_theme.dart';

class ServerCard extends StatelessWidget {
  const ServerCard({
    super.key,
    required this.config,
    required this.onTap,
    required this.onDelete,
    this.isOnline,
    this.keyCount,
    this.totalTransfer,
  });

  final ServerConfig config;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  final bool? isOnline;
  final int? keyCount;
  final String? totalTransfer;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: AppTheme.glassmorphicCard,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Server icon
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  gradient: AppTheme.primaryGradient,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.dns_rounded,
                  color: AppTheme.bgDark,
                  size: 24,
                ),
              ),
              const SizedBox(width: 14),

              // Server info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      config.displayName,
                      style: Theme.of(context).textTheme.titleMedium,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        // Status dot
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isOnline == true
                                ? AppTheme.primary
                                : AppTheme.textMuted,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          config.host,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        if (keyCount != null) ...[
                          const SizedBox(width: 12),
                          Icon(
                            Icons.vpn_key_rounded,
                            size: 12,
                            color: AppTheme.textMuted,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '$keyCount',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),

              // Chevron
              const Icon(
                Icons.chevron_right_rounded,
                color: AppTheme.textMuted,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
