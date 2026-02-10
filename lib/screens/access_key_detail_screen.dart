import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../models/access_key.dart';
import '../providers/server_provider.dart';
import '../theme/app_theme.dart';
import '../utils/format_utils.dart';
import '../widgets/access_key_tile.dart';

class AccessKeyDetailScreen extends StatelessWidget {
  const AccessKeyDetailScreen({super.key, required this.accessKey});

  final AccessKey accessKey;

  @override
  Widget build(BuildContext context) {
    // Find latest version from provider
    return Consumer<ServerProvider>(
      builder: (context, provider, _) {
        final key = provider.accessKeys.firstWhere(
          (k) => k.id == accessKey.id,
          orElse: () => accessKey,
        );

        return Scaffold(
          appBar: AppBar(
            title: Text(
                key.name.isEmpty ? 'Key #${key.id}' : key.name),
            actions: [
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert_rounded),
                onSelected: (action) =>
                    _handleAction(context, provider, key, action),
                itemBuilder: (ctx) => [
                  const PopupMenuItem(
                    value: 'rename',
                    child: ListTile(
                      leading: Icon(Icons.edit_rounded),
                      title: Text('Rename'),
                      dense: true,
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: ListTile(
                      leading:
                          Icon(Icons.delete_rounded, color: AppTheme.danger),
                      title:
                          Text('Delete', style: TextStyle(color: AppTheme.danger)),
                      dense: true,
                    ),
                  ),
                ],
              ),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Access URL section
                if (key.accessUrl != null) ...[
                  _SectionTitle(title: 'Access URL'),
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: AppTheme.glassmorphicCard,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          key.accessUrl!,
                          style: const TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 12,
                            color: AppTheme.textSecondary,
                          ),
                          maxLines: 4,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () => _copyUrl(context, key),
                                icon: const Icon(Icons.copy_rounded, size: 18),
                                label: const Text('Copy'),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: AppTheme.primary,
                                  side: const BorderSide(
                                      color: AppTheme.primary,
                                      width: 1.5),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 12),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: FilledButton.icon(
                                onPressed: () => _shareUrl(key),
                                icon:
                                    const Icon(Icons.share_rounded, size: 18),
                                label: const Text('Share'),
                                style: FilledButton.styleFrom(
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 12),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                ],

                // Connection Details
                _SectionTitle(title: 'Connection Details'),
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: AppTheme.glassmorphicCard,
                  child: Column(
                    children: [
                      _DetailRow(label: 'ID', value: key.id),
                      _DetailRow(label: 'Port', value: key.port?.toString() ?? '-'),
                      _DetailRow(
                          label: 'Encryption', value: key.method ?? '-'),
                      if (key.password != null)
                        _DetailRow(label: 'Password', value: '••••••••'),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Data Usage section
                _SectionTitle(title: 'Data Usage'),
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: AppTheme.glassmorphicCard,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      DataUsageBar(
                        usedBytes: key.dataUsageBytes ?? 0,
                        limitBytes: key.dataLimit?.bytes,
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () =>
                                  _setDataLimit(context, provider, key),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppTheme.textSecondary,
                                side: const BorderSide(color: AppTheme.border),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                padding: const EdgeInsets.symmetric(
                                    vertical: 12),
                              ),
                              child: Text(key.dataLimit != null
                                  ? 'Change Limit'
                                  : 'Set Limit'),
                            ),
                          ),
                          if (key.dataLimit != null) ...[
                            const SizedBox(width: 12),
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () =>
                                    _removeDataLimit(context, provider, key),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: AppTheme.danger,
                                  side: BorderSide(
                                      color: AppTheme.danger
                                          .withValues(alpha: 0.5)),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 12),
                                ),
                                child: const Text('Remove Limit'),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _copyUrl(BuildContext context, AccessKey key) {
    Clipboard.setData(ClipboardData(text: key.accessUrl!));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Access URL copied')),
    );
  }

  void _shareUrl(AccessKey key) {
    Share.share(key.accessUrl!);
  }

  void _handleAction(BuildContext context, ServerProvider provider,
      AccessKey key, String action) {
    switch (action) {
      case 'rename':
        _renameKey(context, provider, key);
        break;
      case 'delete':
        _deleteKey(context, provider, key);
        break;
    }
  }

  Future<void> _renameKey(
      BuildContext context, ServerProvider provider, AccessKey key) async {
    final controller = TextEditingController(text: key.name);
    final name = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Rename Key'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'Key name'),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, controller.text),
              child: const Text('Save')),
        ],
      ),
    );
    if (name != null && name.isNotEmpty) {
      await provider.renameAccessKey(key.id, name);
    }
  }

  Future<void> _deleteKey(
      BuildContext context, ServerProvider provider, AccessKey key) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Key'),
        content: const Text(
            'This will permanently revoke access for anyone using this key.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppTheme.danger),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await provider.deleteAccessKey(key.id);
      if (context.mounted) Navigator.pop(context);
    }
  }

  Future<void> _setDataLimit(
      BuildContext context, ServerProvider provider, AccessKey key) async {
    final controller = TextEditingController(
      text: key.dataLimit != null
          ? FormatUtils.bytesToGb(key.dataLimit!.bytes).toStringAsFixed(1)
          : '',
    );
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Set Data Limit'),
        content: TextField(
          controller: controller,
          autofocus: true,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(
            hintText: 'Limit in GB',
            suffixText: 'GB',
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, controller.text),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (result != null && result.isNotEmpty) {
      final gb = double.tryParse(result);
      if (gb != null && gb > 0) {
        await provider.setKeyDataLimit(key.id, FormatUtils.gbToBytes(gb));
      }
    }
  }

  Future<void> _removeDataLimit(
      BuildContext context, ServerProvider provider, AccessKey key) async {
    await provider.removeKeyDataLimit(key.id);
  }
}

// ─── Helper Widgets ──────────────────────────────────────────────

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleLarge,
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.textMuted,
                  ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.textSecondary,
                    fontFamily: 'monospace',
                  ),
            ),
          ),
        ],
      ),
    );
  }
}
