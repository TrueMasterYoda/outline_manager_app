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

class _ServerListScreenState extends State<ServerListScreen>
    with TickerProviderStateMixin {
  late AnimationController _fabController;
  late AnimationController _bgController;

  @override
  void initState() {
    super.initState();
    _fabController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..forward();
    _bgController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ServerProvider>().loadSavedServers();
    });
  }

  @override
  void dispose() {
    _fabController.dispose();
    _bgController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Animated background gradient orbs
          _AnimatedBackground(controller: _bgController),
          // Main content
          SafeArea(
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(
                  parent: AlwaysScrollableScrollPhysics()),
              slivers: [
                // Header
                SliverToBoxAdapter(child: _buildHeader(context)),
                const SliverToBoxAdapter(child: SizedBox(height: 8)),
                // Server list
                Consumer<ServerProvider>(
                  builder: (context, provider, _) {
                    if (provider.servers.isEmpty) {
                      return SliverFillRemaining(
                          child: _buildEmptyState(context));
                    }
                    return SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final config = provider.servers[index];
                          return Dismissible(
                            key: Key(config.id),
                            direction: DismissDirection.endToStart,
                            confirmDismiss: (_) => _confirmDelete(context),
                            onDismissed: (_) =>
                                provider.removeServer(config.id),
                            background: Container(
                              margin: const EdgeInsets.symmetric(
                                  horizontal: 20, vertical: 6),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    AppTheme.danger.withValues(alpha: 0.0),
                                    AppTheme.danger.withValues(alpha: 0.15),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(22),
                              ),
                              alignment: Alignment.centerRight,
                              padding: const EdgeInsets.only(right: 28),
                              child: Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color:
                                      AppTheme.danger.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: const Icon(
                                  Icons.delete_outline_rounded,
                                  color: AppTheme.danger,
                                  size: 22,
                                ),
                              ),
                            ),
                            child: ServerCard(
                              config: config,
                              onTap: () =>
                                  _openServer(context, provider, config),
                              onDelete: () async {
                                final confirmed =
                                    await _confirmDelete(context);
                                if (confirmed == true) {
                                  provider.removeServer(config.id);
                                }
                              },
                            ),
                          );
                        },
                        childCount: provider.servers.length,
                      ),
                    );
                  },
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 120)),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 2),
          end: Offset.zero,
        ).animate(CurvedAnimation(
          parent: _fabController,
          curve: Curves.elasticOut,
        )),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: AppTheme.primary.withValues(alpha: 0.4),
                blurRadius: 20,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: FloatingActionButton.extended(
            onPressed: () => _addServer(context),
            icon: const Icon(Icons.add_rounded, size: 22),
            label: const Text(
              'Add Server',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Logo icon with gradient
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  gradient: AppTheme.heroGradient,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primary.withValues(alpha: 0.3),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.shield_rounded,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 14),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ShaderMask(
                    shaderCallback: (bounds) =>
                        AppTheme.heroGradient.createShader(bounds),
                    child: Text(
                      'Outline',
                      style: Theme.of(context)
                          .textTheme
                          .headlineLarge
                          ?.copyWith(
                            color: Colors.white,
                          ),
                    ),
                  ),
                  Text(
                    'SERVER MANAGER',
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                          color: AppTheme.textMuted,
                          letterSpacing: 2,
                          fontSize: 11,
                        ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          // Server count or quick stats
          Consumer<ServerProvider>(
            builder: (context, provider, _) {
              if (provider.servers.isEmpty) return const SizedBox.shrink();
              return Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: AppTheme.bgCard.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: AppTheme.border.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    _QuickStat(
                      icon: Icons.dns_rounded,
                      value: '${provider.servers.length}',
                      label: provider.servers.length == 1
                          ? 'Server'
                          : 'Servers',
                    ),
                  ],
                ),
              );
            },
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

// ─── Quick stat widget ────────────────────────────────────────────

class _QuickStat extends StatelessWidget {
  const _QuickStat(
      {required this.icon, required this.value, required this.label});
  final IconData icon;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: AppTheme.primary),
        const SizedBox(width: 8),
        Text(
          value,
          style: const TextStyle(
            color: AppTheme.textPrimary,
            fontWeight: FontWeight.w700,
            fontSize: 16,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(
            color: AppTheme.textMuted,
            fontSize: 13,
          ),
        ),
      ],
    );
  }
}

// ─── Animated background ──────────────────────────────────────────

class _AnimatedBackground extends StatelessWidget {
  const _AnimatedBackground({required this.controller});
  final AnimationController controller;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final size = MediaQuery.of(context).size;
        return CustomPaint(
          size: size,
          painter: _BgPainter(controller.value),
        );
      },
    );
  }
}

class _BgPainter extends CustomPainter {
  _BgPainter(this.t);
  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    // Primary glow orb
    final p1 = Offset(
      size.width * (0.2 + 0.1 * math.sin(t * 2 * math.pi)),
      size.height * (0.15 + 0.05 * math.cos(t * 2 * math.pi)),
    );
    canvas.drawCircle(
      p1,
      size.width * 0.45,
      Paint()
        ..shader = RadialGradient(
          colors: [
            AppTheme.primary.withValues(alpha: 0.04),
            Colors.transparent,
          ],
        ).createShader(Rect.fromCircle(center: p1, radius: size.width * 0.45)),
    );

    // Accent glow orb
    final p2 = Offset(
      size.width * (0.8 + 0.1 * math.cos(t * 2 * math.pi + 1)),
      size.height * (0.6 + 0.08 * math.sin(t * 2 * math.pi + 1)),
    );
    canvas.drawCircle(
      p2,
      size.width * 0.5,
      Paint()
        ..shader = RadialGradient(
          colors: [
            AppTheme.accent.withValues(alpha: 0.03),
            Colors.transparent,
          ],
        ).createShader(Rect.fromCircle(center: p2, radius: size.width * 0.5)),
    );
  }

  @override
  bool shouldRepaint(_BgPainter old) => old.t != t;
}
