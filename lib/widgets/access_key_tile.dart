import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

import '../models/access_key.dart';
import '../theme/app_theme.dart';
import '../utils/format_utils.dart';

class AccessKeyTile extends StatelessWidget {
  const AccessKeyTile({
    super.key,
    required this.accessKey,
    required this.onTap,
    required this.onDelete,
    required this.onRename,
  });

  final AccessKey accessKey;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  final VoidCallback onRename;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
        decoration: AppTheme.glassmorphicCard,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top row: name + actions
              Row(
                children: [
                  // Key icon
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.vpn_key_rounded,
                      color: AppTheme.primary,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 12),

                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          accessKey.name.isEmpty
                              ? 'Key #${accessKey.id}'
                              : accessKey.name,
                          style: Theme.of(context).textTheme.titleMedium,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (accessKey.port != null)
                          Text(
                            'Port ${accessKey.port} · ${accessKey.method ?? 'default'}',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                      ],
                    ),
                  ),

                  // Share button
                  if (accessKey.accessUrl != null)
                    IconButton(
                      icon: const Icon(Icons.share_rounded, size: 20),
                      color: AppTheme.textMuted,
                      onPressed: () => _shareAccessUrl(context),
                      tooltip: 'Share',
                    ),

                  // Copy button
                  if (accessKey.accessUrl != null)
                    IconButton(
                      icon: const Icon(Icons.copy_rounded, size: 20),
                      color: AppTheme.textMuted,
                      onPressed: () => _copyAccessUrl(context),
                      tooltip: 'Copy',
                    ),
                ],
              ),

              // Usage bar
              if (accessKey.dataUsageBytes != null ||
                  accessKey.dataLimit != null) ...[
                const SizedBox(height: 12),
                DataUsageBar(
                  usedBytes: accessKey.dataUsageBytes ?? 0,
                  limitBytes: accessKey.dataLimit?.bytes,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _shareAccessUrl(BuildContext context) {
    if (accessKey.accessUrl != null) {
      Share.share(accessKey.accessUrl!);
    }
  }

  void _copyAccessUrl(BuildContext context) {
    if (accessKey.accessUrl != null) {
      Clipboard.setData(ClipboardData(text: accessKey.accessUrl!));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Access URL copied to clipboard'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }
}

class DataUsageBar extends StatelessWidget {
  const DataUsageBar({
    super.key,
    required this.usedBytes,
    this.limitBytes,
  });

  final int usedBytes;
  final int? limitBytes;

  @override
  Widget build(BuildContext context) {
    final hasLimit = limitBytes != null && limitBytes! > 0;
    final fraction = hasLimit ? (usedBytes / limitBytes!).clamp(0.0, 1.0) : 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Progress bar
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: SizedBox(
            height: 6,
            child: Stack(
              children: [
                // Background
                Container(color: AppTheme.surfaceDim),
                // Fill
                FractionallySizedBox(
                  widthFactor: hasLimit ? fraction : 0,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: fraction > 0.9
                            ? [AppTheme.warning, AppTheme.danger]
                            : [AppTheme.primary, AppTheme.accent],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 6),

        // Label
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              FormatUtils.formatBytes(usedBytes),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.textSecondary,
                  ),
            ),
            if (hasLimit)
              Text(
                '/ ${FormatUtils.formatBytes(limitBytes!)}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppTheme.textMuted,
                    ),
              )
            else
              Text(
                'No limit',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppTheme.textMuted,
                    ),
              ),
          ],
        ),
      ],
    );
  }
}
