import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/access_key.dart';
import '../providers/server_provider.dart';
import '../theme/app_theme.dart';
import '../utils/format_utils.dart';
import '../widgets/access_key_tile.dart';
import '../widgets/usage_chart.dart';
import 'access_key_detail_screen.dart';

class ServerDetailScreen extends StatefulWidget {
  const ServerDetailScreen({super.key});

  @override
  State<ServerDetailScreen> createState() => _ServerDetailScreenState();
}

class _ServerDetailScreenState extends State<ServerDetailScreen> {
  @override
  Widget build(BuildContext context) {
    return Consumer<ServerProvider>(
      builder: (context, provider, _) {
        final server = provider.serverInfo;
        final config = provider.selectedServer;

        return Scaffold(
          appBar: AppBar(
            title: Text(config?.displayName ?? 'Server'),
            actions: [
              IconButton(
                icon: const Icon(Icons.settings_rounded),
                onPressed: () => _showServerSettings(context, provider),
                tooltip: 'Server Settings',
              ),
              IconButton(
                icon: const Icon(Icons.refresh_rounded),
                onPressed: provider.isLoading
                    ? null
                    : () => provider.refreshServerData(),
                tooltip: 'Refresh',
              ),
            ],
          ),
          body: provider.isLoading && server == null
              ? const Center(
                  child: CircularProgressIndicator(color: AppTheme.primary),
                )
              : provider.error != null && server == null
                  ? _buildErrorState(context, provider)
                  : _buildContent(context, provider),
          floatingActionButton: server != null
              ? FloatingActionButton(
                  onPressed: () => _createAccessKey(context, provider),
                  child: const Icon(Icons.person_add_rounded),
                )
              : null,
        );
      },
    );
  }

  Widget _buildErrorState(BuildContext context, ServerProvider provider) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off_rounded,
                color: AppTheme.danger, size: 48),
            const SizedBox(height: 16),
            Text(
              'Connection Failed',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 8),
            Text(
              provider.error ?? 'Unknown error',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.textMuted,
                  ),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () => provider.refreshServerData(),
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, ServerProvider provider) {
    final server = provider.serverInfo;

    return RefreshIndicator(
      color: AppTheme.primary,
      onRefresh: () => provider.refreshServerData(),
      child: ListView(
        padding: const EdgeInsets.only(bottom: 100),
        children: [
          // Server info card
          if (server != null) _buildServerInfoCard(context, provider),

          // Data transfer summary
          if (provider.dataTransfer.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
              child: Text(
                'Data Transfer',
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.all(16),
              decoration: AppTheme.glassmorphicCard,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      ShaderMask(
                        shaderCallback: (bounds) =>
                            AppTheme.primaryGradient.createShader(bounds),
                        child: Text(
                          FormatUtils.formatBytes(
                              provider.totalDataTransferred),
                          style: Theme.of(context)
                              .textTheme
                              .headlineMedium
                              ?.copyWith(color: Colors.white),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'total',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  UsageChart(
                    dataByKeyName: _buildChartData(provider),
                  ),
                ],
              ),
            ),
          ],

          // Access keys section
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 10),
            child: Row(
              children: [
                Text(
                  'Access Keys',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${provider.accessKeys.length}',
                    style: const TextStyle(
                      color: AppTheme.primary,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          ),

          if (provider.accessKeys.isEmpty)
            Padding(
              padding: const EdgeInsets.all(32),
              child: Center(
                child: Column(
                  children: [
                    const Icon(Icons.vpn_key_off_rounded,
                        color: AppTheme.textMuted, size: 40),
                    const SizedBox(height: 12),
                    Text(
                      'No access keys',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Create one to share access',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            )
          else
            ...provider.accessKeys.map((key) => AccessKeyTile(
                  accessKey: key,
                  onTap: () => _openKeyDetail(context, key),
                  onDelete: () => _deleteKey(context, provider, key),
                  onRename: () => _renameKey(context, provider, key),
                )),

          // Loading indicator
          if (provider.isLoading)
            const Padding(
              padding: EdgeInsets.all(16),
              child: Center(
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppTheme.primary,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildServerInfoCard(
      BuildContext context, ServerProvider provider) {
    final server = provider.serverInfo!;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      decoration: AppTheme.accentGradientCard,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: provider.isConnected
                        ? AppTheme.primary
                        : AppTheme.danger,
                    boxShadow: [
                      BoxShadow(
                        color: (provider.isConnected
                                ? AppTheme.primary
                                : AppTheme.danger)
                            .withValues(alpha: 0.5),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  provider.isConnected ? 'Connected' : 'Offline',
                  style: TextStyle(
                    color: provider.isConnected
                        ? AppTheme.primary
                        : AppTheme.danger,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                const Spacer(),
                if (server.version != null)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.bgDark.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'v${server.version}',
                      style: const TextStyle(
                        color: AppTheme.textMuted,
                        fontSize: 12,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 14),
            _infoRow(context, 'Server ID', server.serverId),
            _infoRow(context, 'Hostname',
                server.hostnameForAccessKeys ?? 'Default'),
            _infoRow(context, 'Port',
                server.portForNewAccessKeys?.toString() ?? 'Default'),
            _infoRow(context, 'Metrics',
                server.metricsEnabled ? 'Enabled' : 'Disabled'),
            if (server.accessKeyDataLimit != null)
              _infoRow(
                context,
                'Global Limit',
                FormatUtils.formatBytes(server.accessKeyDataLimit!.bytes),
              ),
            _infoRow(context, 'Created',
                FormatUtils.formatDate(server.createdTimestampMs)),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
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
                  ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Map<String, int> _buildChartData(ServerProvider provider) {
    final result = <String, int>{};
    for (final key in provider.accessKeys) {
      final name = key.name.isEmpty ? 'Key #${key.id}' : key.name;
      final usage = provider.dataTransfer[key.id] ?? 0;
      if (usage > 0) result[name] = usage;
    }
    return result;
  }

  void _openKeyDetail(BuildContext context, AccessKey key) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AccessKeyDetailScreen(accessKey: key),
      ),
    );
  }

  Future<void> _createAccessKey(
      BuildContext context, ServerProvider provider) async {
    final name = await _showNameDialog(context, 'Create Access Key',
        hint: 'Key name (optional)');
    if (name == null) return; // User cancelled

    try {
      await provider.createAccessKey(
          name: name.isEmpty ? null : name);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Future<void> _deleteKey(
      BuildContext context, ServerProvider provider, AccessKey key) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Access Key'),
        content: Text(
            'Delete "${key.name.isEmpty ? 'Key #${key.id}' : key.name}"? This will revoke access for anyone using this key.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppTheme.danger),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      try {
        await provider.deleteAccessKey(key.id);
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e')),
          );
        }
      }
    }
  }

  Future<void> _renameKey(
      BuildContext context, ServerProvider provider, AccessKey key) async {
    final name = await _showNameDialog(
      context,
      'Rename Access Key',
      initialValue: key.name,
    );
    if (name == null) return;
    try {
      await provider.renameAccessKey(key.id, name);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  void _showServerSettings(BuildContext context, ServerProvider provider) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => _ServerSettingsSheet(provider: provider),
    );
  }

  Future<String?> _showNameDialog(
    BuildContext context,
    String title, {
    String? initialValue,
    String? hint,
  }) {
    final controller = TextEditingController(text: initialValue);
    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: InputDecoration(hintText: hint ?? 'Enter name'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, controller.text),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}

// ─── Server Settings Bottom Sheet ─────────────────────────────────

class _ServerSettingsSheet extends StatelessWidget {
  const _ServerSettingsSheet({required this.provider});

  final ServerProvider provider;

  @override
  Widget build(BuildContext context) {
    final server = provider.serverInfo;
    if (server == null) return const SizedBox.shrink();

    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.3,
      maxChildSize: 0.85,
      expand: false,
      builder: (context, scrollController) {
        return SingleChildScrollView(
          controller: scrollController,
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppTheme.textMuted,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              Text(
                'Server Settings',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 24),

              // Rename server
              _SettingsTile(
                icon: Icons.edit_rounded,
                title: 'Rename Server',
                subtitle: server.name,
                onTap: () => _renameServer(context),
              ),

              // Update hostname
              _SettingsTile(
                icon: Icons.dns_rounded,
                title: 'Hostname',
                subtitle: server.hostnameForAccessKeys ?? 'Default',
                onTap: () => _setHostname(context),
              ),

              // Update port
              _SettingsTile(
                icon: Icons.numbers_rounded,
                title: 'Port for New Keys',
                subtitle: server.portForNewAccessKeys?.toString() ?? 'Default',
                onTap: () => _setPort(context),
              ),

              // Global data limit
              _SettingsTile(
                icon: Icons.data_usage_rounded,
                title: 'Global Data Limit',
                subtitle: server.accessKeyDataLimit != null
                    ? FormatUtils.formatBytes(
                        server.accessKeyDataLimit!.bytes)
                    : 'No limit',
                onTap: () => _setGlobalDataLimit(context),
              ),

              // Metrics toggle
              Container(
                margin: const EdgeInsets.symmetric(vertical: 4),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: AppTheme.bgCardLight,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.analytics_outlined,
                        color: AppTheme.textMuted, size: 22),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Share Metrics',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          Text(
                            'Help improve Outline',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                    Switch(
                      value: server.metricsEnabled,
                      onChanged: (val) {
                        provider.setMetricsEnabled(val);
                        Navigator.pop(context);
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _renameServer(BuildContext context) async {
    final controller =
        TextEditingController(text: provider.serverInfo?.name);
    final name = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Rename Server'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'Server name'),
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
      await provider.renameServer(name);
      if (context.mounted) Navigator.pop(context);
    }
  }

  Future<void> _setHostname(BuildContext context) async {
    final controller = TextEditingController(
        text: provider.serverInfo?.hostnameForAccessKeys);
    final hostname = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Set Hostname'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration:
              const InputDecoration(hintText: 'Hostname or IP address'),
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
    if (hostname != null && hostname.isNotEmpty) {
      await provider.setHostname(hostname);
      if (context.mounted) Navigator.pop(context);
    }
  }

  Future<void> _setPort(BuildContext context) async {
    final controller = TextEditingController(
        text: provider.serverInfo?.portForNewAccessKeys?.toString());
    final portStr = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Set Default Port'),
        content: TextField(
          controller: controller,
          autofocus: true,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(hintText: '1-65535'),
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
    if (portStr != null && portStr.isNotEmpty) {
      final port = int.tryParse(portStr);
      if (port != null && port >= 1 && port <= 65535) {
        await provider.setPort(port);
        if (context.mounted) Navigator.pop(context);
      }
    }
  }

  Future<void> _setGlobalDataLimit(BuildContext context) async {
    final current = provider.serverInfo?.accessKeyDataLimit?.bytes;
    final controller = TextEditingController(
        text: current != null
            ? FormatUtils.bytesToGb(current).toStringAsFixed(1)
            : '');

    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Global Data Limit'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: controller,
              autofocus: true,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                hintText: 'Limit in GB',
                suffixText: 'GB',
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Applies to all access keys. Leave empty and save to remove.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          if (current != null)
            TextButton(
              onPressed: () => Navigator.pop(ctx, 'REMOVE'),
              style:
                  TextButton.styleFrom(foregroundColor: AppTheme.danger),
              child: const Text('Remove Limit'),
            ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, controller.text),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (result == null) return;

    if (result == 'REMOVE') {
      await provider.removeGlobalDataLimit();
    } else if (result.isNotEmpty) {
      final gb = double.tryParse(result);
      if (gb != null && gb > 0) {
        await provider.setGlobalDataLimit(FormatUtils.gbToBytes(gb));
      }
    }
    if (context.mounted) Navigator.pop(context);
  }
}

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppTheme.bgCardLight,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Icon(icon, color: AppTheme.textMuted, size: 22),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  Text(
                    subtitle,
                    style: Theme.of(context).textTheme.bodySmall,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded,
                color: AppTheme.textMuted, size: 20),
          ],
        ),
      ),
    );
  }
}
