import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

import '../models/access_key.dart';
import '../theme/app_theme.dart';
import '../utils/format_utils.dart';

class AccessKeyTile extends StatefulWidget {
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
  State<AccessKeyTile> createState() => _AccessKeyTileState();
}

class _AccessKeyTileState extends State<AccessKeyTile> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final key = widget.accessKey;
    final hasUsage = key.dataUsageBytes != null || key.dataLimit != null;

    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF111833), Color(0xFF0F1530)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: AppTheme.border.withValues(alpha: 0.4),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top row: icon + name + actions
                Row(
                  children: [
                    // Key icon
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppTheme.primary.withValues(alpha: 0.18),
                            AppTheme.accent.withValues(alpha: 0.08),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppTheme.primary.withValues(alpha: 0.12),
                        ),
                      ),
                      child: const Icon(
                        Icons.vpn_key_rounded,
                        color: AppTheme.primary,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 14),

                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            key.name.isEmpty
                                ? 'Key #${key.id}'
                                : key.name,
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(fontWeight: FontWeight.w700),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (key.port != null)
                            Text(
                              'Port ${key.port} · ${key.method ?? 'default'}',
                              style:
                                  Theme.of(context).textTheme.bodySmall?.copyWith(
                                        color: AppTheme.textMuted,
                                        fontSize: 11,
                                      ),
                            ),
                        ],
                      ),
                    ),

                    // Action buttons
                    if (key.accessUrl != null) ...[
                      _ActionButton(
                        icon: Icons.copy_rounded,
                        onTap: () => _copyAccessUrl(context),
                        tooltip: 'Copy',
                      ),
                      const SizedBox(width: 4),
                      _ActionButton(
                        icon: Icons.share_rounded,
                        onTap: () => _shareAccessUrl(context),
                        tooltip: 'Share',
                      ),
                    ],
                  ],
                ),

                // Usage bar
                if (hasUsage) ...[
                  const SizedBox(height: 14),
                  DataUsageBar(
                    usedBytes: key.dataUsageBytes ?? 0,
                    limitBytes: key.dataLimit?.bytes,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _shareAccessUrl(BuildContext context) {
    if (widget.accessKey.accessUrl != null) {
      Share.share(widget.accessKey.accessUrl!);
    }
  }

  void _copyAccessUrl(BuildContext context) {
    if (widget.accessKey.accessUrl != null) {
      Clipboard.setData(ClipboardData(text: widget.accessKey.accessUrl!));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle_rounded,
                  color: AppTheme.success, size: 18),
              const SizedBox(width: 8),
              const Text('Access URL copied'),
            ],
          ),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }
}

// ─── Action Button ────────────────────────────────────────────────

class _ActionButton extends StatelessWidget {
  const _ActionButton(
      {required this.icon, required this.onTap, required this.tooltip});

  final IconData icon;
  final VoidCallback onTap;
  final String tooltip;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          child: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppTheme.surfaceDim.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 16, color: AppTheme.textMuted),
          ),
        ),
      ),
    );
  }
}

// ─── Data Usage Bar ───────────────────────────────────────────────

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
    final fraction =
        hasLimit ? (usedBytes / limitBytes!).clamp(0.0, 1.0) : 0.0;
    final isWarning = fraction > 0.85;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Progress bar
        Container(
          height: 6,
          decoration: BoxDecoration(
            color: AppTheme.surfaceDim.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(3),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: hasLimit
                ? FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: fraction,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: isWarning
                              ? [AppTheme.warning, AppTheme.danger]
                              : [AppTheme.primary, AppTheme.accentBright],
                        ),
                        borderRadius: BorderRadius.circular(3),
                        boxShadow: [
                          BoxShadow(
                            color: (isWarning
                                    ? AppTheme.warning
                                    : AppTheme.primary)
                                .withValues(alpha: 0.4),
                            blurRadius: 6,
                          ),
                        ],
                      ),
                    ),
                  )
                : const SizedBox(),
          ),
        ),
        const SizedBox(height: 8),

        // Labels
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              FormatUtils.formatBytes(usedBytes),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.textSecondary,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
            ),
            if (hasLimit)
              Text(
                '/ ${FormatUtils.formatBytes(limitBytes!)}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppTheme.textMuted,
                      fontSize: 11,
                    ),
              )
            else
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceDim.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  'No limit',
                  style: TextStyle(
                    color: AppTheme.textMuted,
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}
