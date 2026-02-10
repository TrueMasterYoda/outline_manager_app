import 'package:flutter/material.dart';

import '../models/server_config.dart';
import '../theme/app_theme.dart';

class ServerCard extends StatefulWidget {
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
  State<ServerCard> createState() => _ServerCardState();
}

class _ServerCardState extends State<ServerCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  bool _pressed = false;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isOnline = widget.isOnline ?? false;
    final statusColor = isOnline ? AppTheme.primary : AppTheme.textMuted;

    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOut,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF111833), Color(0xFF0F1D3D)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: isOnline
                  ? AppTheme.primary.withValues(alpha: 0.15)
                  : AppTheme.border.withValues(alpha: 0.5),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.3),
                blurRadius: 20,
                offset: const Offset(0, 6),
              ),
              if (isOnline)
                BoxShadow(
                  color: AppTheme.primary.withValues(alpha: 0.06),
                  blurRadius: 40,
                  offset: const Offset(0, 4),
                ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(22),
            child: Stack(
              children: [
                // Subtle glow top-right
                Positioned(
                  top: -20,
                  right: -20,
                  child: Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          statusColor.withValues(alpha: 0.08),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),
                // Content
                Padding(
                  padding: const EdgeInsets.all(18),
                  child: Row(
                    children: [
                      // Server icon with gradient background
                      Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: isOnline
                                ? [
                                    AppTheme.primary.withValues(alpha: 0.2),
                                    AppTheme.accent.withValues(alpha: 0.1),
                                  ]
                                : [
                                    AppTheme.surfaceDim,
                                    AppTheme.bgCardLight,
                                  ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isOnline
                                ? AppTheme.primary.withValues(alpha: 0.2)
                                : AppTheme.border.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Icon(
                          Icons.dns_rounded,
                          color: isOnline ? AppTheme.primary : AppTheme.textMuted,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 16),

                      // Server info
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.config.displayName,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: -0.2,
                                  ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                // Animated status dot
                                AnimatedBuilder(
                                  animation: _pulseController,
                                  builder: (context, child) {
                                    return Container(
                                      width: 8,
                                      height: 8,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: statusColor,
                                        boxShadow: isOnline
                                            ? [
                                                BoxShadow(
                                                  color: statusColor.withValues(
                                                      alpha: 0.3 +
                                                          _pulseController
                                                                  .value *
                                                              0.4),
                                                  blurRadius: 6 +
                                                      _pulseController.value *
                                                          4,
                                                  spreadRadius:
                                                      _pulseController.value *
                                                          1,
                                                ),
                                              ]
                                            : null,
                                      ),
                                    );
                                  },
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  widget.config.host,
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(
                                        color: AppTheme.textMuted,
                                        fontFamily: 'monospace',
                                        fontSize: 12,
                                      ),
                                ),
                              ],
                            ),
                            // Stats row
                            if (widget.keyCount != null ||
                                widget.totalTransfer != null) ...[
                              const SizedBox(height: 10),
                              Row(
                                children: [
                                  if (widget.keyCount != null)
                                    _StatChip(
                                      icon: Icons.vpn_key_rounded,
                                      label: '${widget.keyCount} keys',
                                    ),
                                  if (widget.keyCount != null &&
                                      widget.totalTransfer != null)
                                    const SizedBox(width: 10),
                                  if (widget.totalTransfer != null)
                                    _StatChip(
                                      icon: Icons.arrow_upward_rounded,
                                      label: widget.totalTransfer!,
                                    ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),

                      // Arrow
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: AppTheme.surfaceDim.withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.arrow_forward_ios_rounded,
                          color: AppTheme.textMuted,
                          size: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppTheme.surfaceDim.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: AppTheme.border.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: AppTheme.textMuted),
          const SizedBox(width: 5),
          Text(
            label,
            style: const TextStyle(
              color: AppTheme.textMuted,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
