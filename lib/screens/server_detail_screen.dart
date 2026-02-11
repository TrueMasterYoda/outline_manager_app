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
          backgroundColor: AppTheme.bgDeep,
          body: NestedScrollView(
            headerSliverBuilder: (context, innerBoxScrolled) {
              return [
                SliverAppBar(
                  expandedHeight: 200,
                  pinned: true,
                  backgroundColor: AppTheme.bgDeep,
                  surfaceTintColor: Colors.transparent,
                  leading: IconButton(
                    icon: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: AppTheme.bgCard.withValues(alpha: 0.8),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: AppTheme.border.withValues(alpha: 0.3)),
                      ),
                      child: const Icon(Icons.arrow_back_ios_new_rounded,
                          size: 16),
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                  actions: [
                    IconButton(
                      icon: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: AppTheme.bgCard.withValues(alpha: 0.8),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                              color: AppTheme.border.withValues(alpha: 0.3)),
                        ),
                        child:
                            const Icon(Icons.settings_rounded, size: 18),
                      ),
                      onPressed: () =>
                          _showServerSettings(context, provider),
                    ),
                    IconButton(
                      icon: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: AppTheme.bgCard.withValues(alpha: 0.8),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                              color: AppTheme.border.withValues(alpha: 0.3)),
                        ),
                        child:
                            const Icon(Icons.refresh_rounded, size: 18),
                      ),
                      onPressed: provider.isLoading
                          ? null
                          : () => provider.refreshServerData(),
                    ),
                    const SizedBox(width: 8),
                  ],
                  flexibleSpace: FlexibleSpaceBar(
                    background: _HeroSection(
                      serverName: config?.displayName ?? 'Server',
                      isConnected: provider.isConnected,
                      version: server?.version,
                    ),
                  ),
                ),
              ];
            },
            body: provider.isLoading && server == null
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: 32,
                          height: 32,
                          child: CircularProgressIndicator(
                            color: AppTheme.primary.withValues(alpha: 0.7),
                            strokeWidth: 3,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Connecting...',
                          style: TextStyle(
                              color: AppTheme.textMuted, fontSize: 14),
                        ),
                      ],
                    ),
                  )
                : provider.error != null && server == null
                    ? _buildErrorState(context, provider)
                    : _buildContent(context, provider),
          ),
          floatingActionButton: server != null
              ? Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.primary.withValues(alpha: 0.4),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: FloatingActionButton.extended(
                    onPressed: () =>
                        _createAccessKey(context, provider),
                    icon: const Icon(Icons.person_add_rounded, size: 20),
                    label: const Text('Add Key',
                        style: TextStyle(fontWeight: FontWeight.w700)),
                  ),
                )
              : null,
        );
      },
    );
  }

  Widget _buildErrorState(BuildContext context, ServerProvider provider) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(48),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.danger.withValues(alpha: 0.1),
              ),
              child: const Icon(Icons.cloud_off_rounded,
                  color: AppTheme.danger, size: 36),
            ),
            const SizedBox(height: 20),
            Text(
              'Connection Failed',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 10),
            Text(
              provider.error ?? 'Unknown error',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.textMuted,
                    height: 1.4,
                  ),
            ),
            const SizedBox(height: 28),
            FilledButton.icon(
              onPressed: () => provider.refreshServerData(),
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Retry'),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                    horizontal: 24, vertical: 14),
              ),
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
      backgroundColor: AppTheme.bgCard,
      onRefresh: () => provider.refreshServerData(),
      child: ListView(
        physics: const BouncingScrollPhysics(
            parent: AlwaysScrollableScrollPhysics()),
        padding: const EdgeInsets.only(bottom: 120, top: 8),
        children: [
          // Server info card
          if (server != null) _buildServerInfoCard(context, provider),

          // Data transfer section
          if (provider.dataTransfer.isNotEmpty) ...[
            _SectionHeader(
              title: 'Data Transfer',
              icon: Icons.bar_chart_rounded,
            ),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
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
                              provider.totalDataTransferred),
                          style: Theme.of(context)
                              .textTheme
                              .headlineMedium
                              ?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                              ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 3),
                        child: Text(
                          'total transferred',
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(color: AppTheme.textMuted),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  UsageChart(dataByKeyName: _buildChartData(provider)),
                ],
              ),
            ),
          ],

          // Access keys section
          _SectionHeader(
            title: 'Access Keys',
            icon: Icons.vpn_key_rounded,
            trailing: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 12, vertical: 5),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppTheme.primary.withValues(alpha: 0.2),
                    AppTheme.primary.withValues(alpha: 0.1),
                  ],
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '${provider.accessKeys.length}',
                style: const TextStyle(
                  color: AppTheme.primary,
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
            ),
          ),

          if (provider.accessKeys.isEmpty)
            _buildEmptyKeys(context)
          else
            ...provider.accessKeys.map((key) => AccessKeyTile(
                  accessKey: key,
                  onTap: () => _openKeyDetail(context, key),
                  onDelete: () =>
                      _deleteKey(context, provider, key),
                  onRename: () =>
                      _renameKey(context, provider, key),
                )),

          // Loading indicator
          if (provider.isLoading)
            Padding(
              padding: const EdgeInsets.all(20),
              child: Center(
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: AppTheme.primary.withValues(alpha: 0.5),
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
      margin: const EdgeInsets.fromLTRB(20, 4, 20, 8),
      decoration: AppTheme.highlightCard,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Info grid
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _InfoChip(
                  icon: Icons.dns_rounded,
                  label: 'Hostname',
                  value: server.hostnameForAccessKeys ?? 'Default',
                ),
                _InfoChip(
                  icon: Icons.numbers_rounded,
                  label: 'Port',
                  value: server.portForNewAccessKeys?.toString() ?? 'Default',
                ),
                _InfoChip(
                  icon: Icons.analytics_outlined,
                  label: 'Metrics',
                  value: server.metricsEnabled ? 'On' : 'Off',
                  valueColor: server.metricsEnabled
                      ? AppTheme.primary
                      : AppTheme.textMuted,
                ),
                if (server.accessKeyDataLimit != null)
                  _InfoChip(
                    icon: Icons.data_usage_rounded,
                    label: 'Global Limit',
                    value: FormatUtils.formatBytes(
                        server.accessKeyDataLimit!.bytes),
                  ),
                _InfoChip(
                  icon: Icons.calendar_today_rounded,
                  label: 'Created',
                  value: FormatUtils.formatDate(server.createdTimestampMs),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyKeys(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      padding: const EdgeInsets.all(32),
      decoration: AppTheme.glassmorphicCard,
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppTheme.surfaceDim.withValues(alpha: 0.5),
            ),
            child: const Icon(Icons.vpn_key_off_rounded,
                color: AppTheme.textMuted, size: 28),
          ),
          const SizedBox(height: 16),
          Text(
            'No access keys',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 6),
          Text(
            'Create one to share access',
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(color: AppTheme.textMuted),
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
        builder: (_) => AccessKeyDetailScreen(
          accessKey: key,
          onDelete: () async {
            // Navigator.pop(context); // Close detail screen first? No, let's do it after success?
            // Actually, common pattern is to show dialog on top of detail screen,
            // then if deleted, pop detail screen.
            // But _deleteKey shows a dialog.
            // If we run _deleteKey(context, ...), it shows dialog.
            // If confirmed and successful, we should probably pop the detail screen.

            // Wait for _deleteKey. It returns void.
            // It handles its own error showing.
            // But currently _deleteKey doesn't return whether it succeeded or was confirmed.
            // I should modify _deleteKey to return Future<bool>
            // For now, I'll just wrap it and if the key is gone from provider, pop?
            // Or easier: pass a callback that handles the UI flow.

            final provider =
                Provider.of<ServerProvider>(context, listen: false);
            final deleted = await _deleteKey(context, provider, key);
            if (deleted && context.mounted) {
              Navigator.pop(context);
            }
          },
        ),
      ),
    );
  }

  Future<void> _createAccessKey(
      BuildContext context, ServerProvider provider) async {
    final name = await _showNameDialog(context, 'Create Access Key',
        hint: 'Key name (optional)');
    if (name == null) return;

    try {
      await provider.createAccessKey(name: name.isEmpty ? null : name);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Future<bool> _deleteKey(BuildContext context, ServerProvider provider,
      AccessKey key) async {
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
        return true;
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e')),
          );
        }
        return false;
      }
    }
    return false;
  }

  Future<void> _renameKey(BuildContext context, ServerProvider provider,
      AccessKey key) async {
    final name = await _showNameDialog(context, 'Rename Access Key',
        initialValue: key.name);
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

  void _showServerSettings(
      BuildContext context, ServerProvider provider) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _ServerSettingsSheet(provider: provider),
    );
  }

  Future<String?> _showNameDialog(BuildContext context, String title,
      {String? initialValue, String? hint}) {
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

// ─── Hero Section ─────────────────────────────────────────────────

class _HeroSection extends StatelessWidget {
  const _HeroSection({
    required this.serverName,
    required this.isConnected,
    this.version,
  });

  final String serverName;
  final bool isConnected;
  final String? version;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: AppTheme.heroGradient,
      ),
      child: Stack(
        children: [
          // Glow accent
          Positioned(
            top: -40,
            right: -40,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    (isConnected ? AppTheme.primary : AppTheme.danger)
                        .withValues(alpha: 0.12),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          // Content
          Positioned(
            bottom: 20,
            left: 24,
            right: 24,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  serverName,
                  style: Theme.of(context).textTheme.headlineLarge,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: (isConnected
                                ? AppTheme.primary
                                : AppTheme.danger)
                            .withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: (isConnected
                                  ? AppTheme.primary
                                  : AppTheme.danger)
                              .withValues(alpha: 0.25),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: AppTheme.statusDot(
                              isConnected
                                  ? AppTheme.primary
                                  : AppTheme.danger,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            isConnected ? 'Connected' : 'Offline',
                            style: TextStyle(
                              color: isConnected
                                  ? AppTheme.primary
                                  : AppTheme.danger,
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (version != null) ...[
                      const SizedBox(width: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppTheme.surfaceDim
                              .withValues(alpha: 0.4),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          'v$version',
                          style: const TextStyle(
                            color: AppTheme.textMuted,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
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
    );
  }
}

// ─── Section Header ───────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(
      {required this.title, required this.icon, this.trailing});
  final String title;
  final IconData icon;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppTheme.primary),
          const SizedBox(width: 10),
          Text(title, style: Theme.of(context).textTheme.titleLarge),
          if (trailing != null) ...[
            const SizedBox(width: 10),
            trailing!,
          ],
        ],
      ),
    );
  }
}

// ─── Info Chip ────────────────────────────────────────────────────

class _InfoChip extends StatelessWidget {
  const _InfoChip({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
  });
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppTheme.surfaceDim.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.border.withValues(alpha: 0.3),
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
              const SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  color: valueColor ?? AppTheme.textSecondary,
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

// ─── Server Settings Bottom Sheet ─────────────────────────────────

class _ServerSettingsSheet extends StatelessWidget {
  const _ServerSettingsSheet({required this.provider});
  final ServerProvider provider;

  @override
  Widget build(BuildContext context) {
    final server = provider.serverInfo;
    if (server == null) return const SizedBox.shrink();

    return Container(
      decoration: const BoxDecoration(
        color: AppTheme.bgCard,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        border: Border(
          top: BorderSide(color: AppTheme.borderLight, width: 1),
          left: BorderSide(color: AppTheme.borderLight, width: 1),
          right: BorderSide(color: AppTheme.borderLight, width: 1),
        ),
      ),
      child: DraggableScrollableSheet(
        initialChildSize: 0.55,
        minChildSize: 0.3,
        maxChildSize: 0.85,
        expand: false,
        builder: (context, scrollController) {
          return SingleChildScrollView(
            controller: scrollController,
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Handle
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppTheme.textMuted.withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                Row(
                  children: [
                    const Icon(Icons.settings_rounded,
                        color: AppTheme.primary, size: 22),
                    const SizedBox(width: 10),
                    Text('Server Settings',
                        style: Theme.of(context).textTheme.titleLarge),
                  ],
                ),
                const SizedBox(height: 20),

                _SettingsTile(
                  icon: Icons.edit_rounded,
                  title: 'Rename Server',
                  subtitle: server.name,
                  onTap: () => _renameServer(context),
                ),
                _SettingsTile(
                  icon: Icons.dns_rounded,
                  title: 'Hostname',
                  subtitle: server.hostnameForAccessKeys ?? 'Default',
                  onTap: () => _setHostname(context),
                ),
                _SettingsTile(
                  icon: Icons.numbers_rounded,
                  title: 'Port for New Keys',
                  subtitle:
                      server.portForNewAccessKeys?.toString() ?? 'Default',
                  onTap: () => _setPort(context),
                ),
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
                  margin: const EdgeInsets.symmetric(vertical: 5),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 18, vertical: 14),
                  decoration: BoxDecoration(
                    color: AppTheme.bgCardLight.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: AppTheme.border.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: AppTheme.surfaceDim.withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.analytics_outlined,
                            color: AppTheme.textMuted, size: 18),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Share Metrics',
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium),
                            Text('Help improve Outline',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall),
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
      ),
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
            const SizedBox(height: 10),
            Text(
              'Applies to all access keys. Leave empty to remove.',
              style: Theme.of(ctx).textTheme.bodySmall,
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
              child: const Text('Remove'),
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

// ─── Settings Tile ────────────────────────────────────────────────

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
        margin: const EdgeInsets.symmetric(vertical: 5),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        decoration: BoxDecoration(
          color: AppTheme.bgCardLight.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppTheme.border.withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppTheme.surfaceDim.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: AppTheme.textMuted, size: 18),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: Theme.of(context).textTheme.titleMedium),
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
