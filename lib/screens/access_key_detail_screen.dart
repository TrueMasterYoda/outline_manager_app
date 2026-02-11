import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

import '../models/access_key.dart';
import '../theme/app_theme.dart';
import '../utils/format_utils.dart';
import '../widgets/access_key_tile.dart';

class AccessKeyDetailScreen extends StatelessWidget {
  const AccessKeyDetailScreen(
      {super.key, required this.accessKey, required this.onDelete});

  final AccessKey accessKey;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final keyName =
        accessKey.name.isEmpty ? 'Key #${accessKey.id}' : accessKey.name;

    return Scaffold(
      backgroundColor: AppTheme.bgDeep,
      appBar: AppBar(
        title: Text(keyName),
        leading: IconButton(
          icon: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppTheme.bgCard.withValues(alpha: 0.8),
              borderRadius: BorderRadius.circular(12),
              border:
                  Border.all(color: AppTheme.border.withValues(alpha: 0.3)),
            ),
            child: const Icon(Icons.arrow_back_ios_new_rounded, size: 16),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppTheme.danger.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: AppTheme.danger.withValues(alpha: 0.3)),
              ),
              child: const Icon(Icons.delete_rounded,
                  size: 18, color: AppTheme.danger),
            ),
            onPressed: onDelete,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Key hero card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: AppTheme.highlightCard,
              child: Column(
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppTheme.primary.withValues(alpha: 0.2),
                          AppTheme.accent.withValues(alpha: 0.1),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: AppTheme.primary.withValues(alpha: 0.15),
                      ),
                    ),
                    child: const Icon(Icons.vpn_key_rounded,
                        color: AppTheme.primary, size: 28),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    keyName,
                    style: Theme.of(context).textTheme.headlineMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'ID: ${accessKey.id}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppTheme.textMuted,
                          fontFamily: 'monospace',
                        ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Info chips
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                if (accessKey.port != null)
                  _DetailChip(
                    icon: Icons.numbers_rounded,
                    label: 'Port',
                    value: accessKey.port.toString(),
                  ),
                if (accessKey.method != null)
                  _DetailChip(
                    icon: Icons.lock_rounded,
                    label: 'Cipher',
                    value: accessKey.method!,
                  ),
                if (accessKey.password != null)
                  _DetailChip(
                    icon: Icons.key_rounded,
                    label: 'Password',
                    value: '••••••',
                  ),
              ],
            ),

            // Data usage
            if (accessKey.dataUsageBytes != null ||
                accessKey.dataLimit != null) ...[
              const SizedBox(height: 28),
              _SectionLabel(label: 'Data Usage'),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: AppTheme.glassmorphicCard,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        ShaderMask(
                          shaderCallback: (bounds) =>
                              AppTheme.primaryGradient.createShader(bounds),
                          child: Text(
                            FormatUtils.formatBytes(
                                accessKey.dataUsageBytes ?? 0),
                            style: Theme.of(context)
                                .textTheme
                                .headlineMedium
                                ?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Padding(
                          padding: const EdgeInsets.only(bottom: 3),
                          child: Text(
                            'used',
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(color: AppTheme.textMuted),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    DataUsageBar(
                      usedBytes: accessKey.dataUsageBytes ?? 0,
                      limitBytes: accessKey.dataLimit?.bytes,
                    ),
                  ],
                ),
              ),
            ],

            // Access URL
            if (accessKey.accessUrl != null) ...[
              const SizedBox(height: 28),
              _SectionLabel(label: 'Access URL'),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(18),
                decoration: AppTheme.glassmorphicCard,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppTheme.bgDeep.withValues(alpha: 0.6),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppTheme.border.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Text(
                        accessKey.accessUrl!,
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 11,
                          color: AppTheme.textSecondary,
                          height: 1.5,
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: _GradientButton(
                            icon: Icons.copy_rounded,
                            label: 'Copy',
                            gradient: AppTheme.primaryGradient,
                            onTap: () =>
                                _copyAccessUrl(context),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _GradientButton(
                            icon: Icons.share_rounded,
                            label: 'Share',
                            gradient: const LinearGradient(
                              colors: [
                                AppTheme.accent,
                                AppTheme.accentBright
                              ],
                            ),
                            onTap: () =>
                                _shareAccessUrl(context),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _copyAccessUrl(BuildContext context) {
    Clipboard.setData(ClipboardData(text: accessKey.accessUrl!));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_rounded,
                color: AppTheme.success, size: 18),
            const SizedBox(width: 8),
            const Text('Copied to clipboard'),
          ],
        ),
      ),
    );
  }

  void _shareAccessUrl(BuildContext context) {
    Share.share(accessKey.accessUrl!);
  }
}

// ─── Detail Chip ──────────────────────────────────────────────────

class _DetailChip extends StatelessWidget {
  const _DetailChip(
      {required this.icon, required this.label, required this.value});
  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        gradient: AppTheme.cardGradient,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppTheme.border.withValues(alpha: 0.4),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppTheme.textMuted),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: AppTheme.textMuted,
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Section Label ────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 3,
          height: 18,
          decoration: BoxDecoration(
            gradient: AppTheme.primaryGradient,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          label,
          style: Theme.of(context).textTheme.titleLarge,
        ),
      ],
    );
  }
}

// ─── Gradient Button ──────────────────────────────────────────────

class _GradientButton extends StatelessWidget {
  const _GradientButton({
    required this.icon,
    required this.label,
    required this.gradient,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Gradient gradient;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: (gradient as LinearGradient)
                  .colors
                  .first
                  .withValues(alpha: 0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 16, color: AppTheme.bgDeep),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                color: AppTheme.bgDeep,
                fontWeight: FontWeight.w700,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
