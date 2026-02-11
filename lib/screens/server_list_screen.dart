import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/server_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/server_card.dart';
import 'add_server_screen.dart';
import 'server_detail_screen.dart';

class ServerListScreen extends StatefulWidget {
  const ServerListScreen({super.key});

  @override
  State<ServerListScreen> createState() => _ServerListScreenState();
}

class _ServerListScreenState extends State<ServerListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ServerProvider>().loadSavedServers();
    });
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(
              parent: AlwaysScrollableScrollPhysics()),
          slivers: [
            // Header
            SliverToBoxAdapter(child: _buildHeader(context)),
            const SliverToBoxAdapter(child: SizedBox(height: 12)),
            // Server list
            Consumer<ServerProvider>(
              builder: (context, provider, _) {
                if (provider.servers.isEmpty) {
                  return SliverFillRemaining(
                      hasScrollBody: false, child: _buildEmptyState(context));
                }
                return SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final config = provider.servers[index];
                      // Temporary: defaulting to true for UI demo as we don't have bulk-check yet
                      // In a real app, we'd fire a background ping for each server.
                      const isOnline = true;

                      return Dismissible(
                        key: Key(config.id),
                        direction: DismissDirection.endToStart,
                        confirmDismiss: (_) => _confirmDelete(context),
                        onDismissed: (_) => provider.removeServer(config.id),
                        background: Container(
                          margin: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppTheme.danger.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(22),
                            border: Border.all(
                                color: AppTheme.danger.withValues(alpha: 0.3)),
                          ),
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 28),
                          child: const Icon(
                            Icons.delete_outline_rounded,
                            color: AppTheme.danger,
                            size: 24,
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12.0),
                          child: ServerCard(
                            config: config,
                            isOnline: isOnline,
                            onTap: () => _openServer(context, provider, config),
                            onDelete: () async {
                              final confirmed = await _confirmDelete(context);
                              if (confirmed == true) {
                                provider.removeServer(config.id);
                              }
                            },
                          ),
                        ),
                      );
                    },
                    childCount: provider.servers.length,
                  ),
                );
              },
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 100)),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _addServer(context),
        child: const Icon(Icons.add_rounded, size: 28),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'My Servers',
                style: Theme.of(context).textTheme.headlineLarge,
              ),
              const SizedBox(height: 4),
              Consumer<ServerProvider>(
                builder: (context, provider, _) {
                  final count = provider.servers.length;
                  return Text(
                    '$count active connection${count != 1 ? 's' : ''}',
                    style: Theme.of(context).textTheme.bodyMedium,
                  );
                },
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppTheme.bgCard,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.border.withValues(alpha: 0.5)),
            ),
            child: const Icon(
              Icons.settings_rounded,
              color: AppTheme.textSecondary,
              size: 24,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(48),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Animated gradient circle
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppTheme.primary.withValues(alpha: 0.15),
                    AppTheme.primary.withValues(alpha: 0.03),
                    Colors.transparent,
                  ],
                  stops: const [0.0, 0.6, 1.0],
                ),
              ),
              child: Center(
                child: Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [
                        AppTheme.primary.withValues(alpha: 0.2),
                        AppTheme.accent.withValues(alpha: 0.1),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    border: Border.all(
                      color: AppTheme.primary.withValues(alpha: 0.15),
                    ),
                  ),
                  child: const Icon(
                    Icons.dns_rounded,
                    color: AppTheme.primary,
                    size: 30,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 28),
            Text(
              'No servers yet',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 10),
            Text(
              'Add an Outline server to start\nmanaging access keys and traffic.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.textMuted,
                    height: 1.5,
                  ),
            ),
            const SizedBox(height: 36),
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primary.withValues(alpha: 0.3),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: FilledButton.icon(
                onPressed: () => _addServer(context),
                icon: const Icon(Icons.add_rounded),
                label: const Text('Add Your First Server'),
                style: FilledButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
                  textStyle: const TextStyle(
                      fontWeight: FontWeight.w700, fontSize: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _addServer(BuildContext context) {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => const AddServerScreen(),
        transitionsBuilder: (_, anim, __, child) {
          return SlideTransition(
            position: Tween(
              begin: const Offset(0, 1),
              end: Offset.zero,
            ).animate(CurvedAnimation(parent: anim, curve: Curves.easeOutCubic)),
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 400),
      ),
    );
  }

  void _openServer(
      BuildContext context, ServerProvider provider, dynamic config) {
    provider.selectServer(config);
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ServerDetailScreen()),
    );
  }

  Future<bool?> _confirmDelete(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove Server'),
        content: const Text(
            'Remove this server from the app? This won\'t affect the server itself.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppTheme.danger),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
  }
}


