import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'server_install_screen.dart';
import '../models/server_config.dart';
import '../providers/server_provider.dart';
import '../theme/app_theme.dart';

enum AddServerMode { url, json }

class AddServerScreen extends StatefulWidget {
  const AddServerScreen({super.key, this.mode = AddServerMode.url});

  final AddServerMode mode;

  @override
  State<AddServerScreen> createState() => _AddServerScreenState();
}

class _AddServerScreenState extends State<AddServerScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _urlController = TextEditingController();
  final _nameController = TextEditingController();
  final _fingerprintController = TextEditingController();
  bool _isConnecting = false;
  String? _errorMessage;
  late AnimationController _animController;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..forward();
  }

  @override
  void dispose() {
    _urlController.dispose();
    _nameController.dispose();
    _fingerprintController.dispose();
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgDeep,
      appBar: AppBar(
        title: const Text('Add Server'),
        leading: IconButton(
          icon: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppTheme.bgCard,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.border.withValues(alpha: 0.3)),
            ),
            child: const Icon(Icons.close_rounded, size: 18),
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          child: FadeTransition(
            opacity: CurvedAnimation(
              parent: _animController,
              curve: Curves.easeOut,
            ),
            child: SlideTransition(
              position: Tween(
                begin: const Offset(0, 0.05),
                end: Offset.zero,
              ).animate(CurvedAnimation(
                parent: _animController,
                curve: Curves.easeOutCubic,
              )),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Info card with gradient border
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: AppTheme.highlightCard,
                      child: Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  AppTheme.primary.withValues(alpha: 0.2),
                                  AppTheme.accent.withValues(alpha: 0.1),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: const Icon(
                              Icons.info_outline_rounded,
                              color: AppTheme.primary,
                              size: 22,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Text(
                              'Paste your server\'s management API URL from the Outline setup output.',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(
                                    color: AppTheme.textSecondary,
                                    height: 1.4,
                                  ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    Center(
                      child: TextButton.icon(
                        onPressed: () async {
                          final result = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const ServerInstallScreen(),
                            ),
                          );

                          if (result != null && result is String && mounted) {
                            try {
                              final map = jsonDecode(result);
                              // Whether in URL or JSON mode, we can try to populate or switch.
                              // If in URL mode:
                              if (widget.mode == AddServerMode.url) {
                                _urlController.text = map['apiUrl'] ?? '';
                                if (map['certSha256'] != null) {
                                  _fingerprintController.text =
                                      map['certSha256'];
                                }
                              } else {
                                // In JSON mode, just paste the whole JSON
                                _urlController.text = result;
                              }
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                      'Configuration received. Please confirm details and add.'),
                                ),
                              );
                            } catch (e) {
                              // ignore
                            }
                          }
                        },
                        icon: const Icon(Icons.build_circle_outlined, size: 18),
                        label: const Text('Install Outline on a VPS'),
                        style: TextButton.styleFrom(
                          foregroundColor: AppTheme.primary,
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),
                    const SizedBox(height: 32),

                    // API URL or JSON field
                    if (widget.mode == AddServerMode.url) ...[
                      _FieldLabel(label: 'API URL', icon: Icons.link_rounded),
                      const SizedBox(height: 10),
                      TextFormField(
                        controller: _urlController,
                        decoration: InputDecoration(
                          hintText: 'https://1.2.3.4:1234/secret-path',
                          prefixIcon: Container(
                            margin: const EdgeInsets.all(12),
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              color: AppTheme.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.link_rounded,
                                size: 14, color: AppTheme.primary),
                          ),
                        ),
                        keyboardType: TextInputType.url,
                        autocorrect: false,
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 13,
                          color: AppTheme.textPrimary,
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter the API URL';
                          }
                          final uri = Uri.tryParse(value.trim());
                          if (uri == null ||
                              !uri.hasScheme ||
                              !uri.hasAuthority) {
                            return 'Invalid URL format';
                          }
                          return null;
                        },
                      ),
                    ] else ...[
                      _FieldLabel(
                          label: 'Server Configuration (JSON)',
                          icon: Icons.data_object_rounded),
                      const SizedBox(height: 10),
                      SizedBox(
                        height: 120,
                        child: TextFormField(
                          controller: _urlController,
                          textAlignVertical: TextAlignVertical.center,
                          expands: true,
                          maxLines: null,
                          minLines: null,
                          decoration: InputDecoration(
                            hintText:
                                'Paste the full JSON output from your server setup code here...',
                            prefixIcon: Container(
                              margin: const EdgeInsets.all(12),
                              width: 24,
                              height: 24,
                              decoration: BoxDecoration(
                                color: AppTheme.primary.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(Icons.data_object_rounded,
                                  size: 14, color: AppTheme.primary),
                            ),
                          ),
                          keyboardType: TextInputType.multiline,
                          autocorrect: false,
                          style: const TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 12,
                            color: AppTheme.textPrimary,
                            height: 1.5,
                          ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please paste the server configuration';
                          }
                          try {
                            final json = jsonDecode(value.trim());
                            if (json is! Map || !json.containsKey('apiUrl')) {
                              return 'Invalid configuration: missing apiUrl';
                            }
                          } catch (e) {
                            return 'Invalid JSON format';
                          }
                          return null;
                        },
                      ),
                    ),
                    ],

                    const SizedBox(height: 24),

                    // Display name field
                    _FieldLabel(
                        label: 'Display Name',
                        icon: Icons.label_outline_rounded,
                        optional: true),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: _nameController,
                      decoration: InputDecoration(
                        hintText: 'My VPN Server',
                        prefixIcon: Container(
                          margin: const EdgeInsets.all(12),
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            color: AppTheme.accent.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.label_outline_rounded,
                              size: 14, color: AppTheme.accent),
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Certificate fingerprint (Only for URL mode)
                    if (widget.mode == AddServerMode.url) ...[
                      const SizedBox(height: 24),
                      const _FieldLabel(
                          label: 'Certificate Fingerprint',
                          icon: Icons.fingerprint_rounded),
                      const SizedBox(height: 10),
                      TextFormField(
                        controller: _fingerprintController,
                        decoration: InputDecoration(
                          hintText: 'SHA-256 fingerprint',
                          prefixIcon: Container(
                            margin: const EdgeInsets.all(12),
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              color: AppTheme.purple.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.fingerprint_rounded,
                                size: 14, color: AppTheme.purple),
                          ),
                        ),
                        autocorrect: false,
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 12,
                          color: AppTheme.textPrimary,
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Certificate fingerprint is required for secure connections';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 8),
                      Padding(
                        padding: const EdgeInsets.only(left: 4),
                        child: Text(
                          'Required. Provide the SHA-256 fingerprint from your server setup to prevent MITM attacks.',
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: AppTheme.textMuted
                                        .withValues(alpha: 0.7),
                                    height: 1.4,
                                  ),
                        ),
                      ),
                    ],

                    // Error message
                    if (_errorMessage != null) ...[
                      const SizedBox(height: 24),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppTheme.danger.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color:
                                AppTheme.danger.withValues(alpha: 0.2),
                          ),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: AppTheme.danger
                                    .withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(
                                Icons.error_outline_rounded,
                                color: AppTheme.danger,
                                size: 18,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                _errorMessage!,
                                style: TextStyle(
                                  color: AppTheme.danger
                                      .withValues(alpha: 0.9),
                                  fontSize: 13,
                                  height: 1.4,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    const SizedBox(height: 36),

                    // Connect button with gradient
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          gradient: _isConnecting
                              ? null
                              : AppTheme.primaryGradient,
                          boxShadow: _isConnecting
                              ? null
                              : [
                                  BoxShadow(
                                    color: AppTheme.primary
                                        .withValues(alpha: 0.35),
                                    blurRadius: 20,
                                    offset: const Offset(0, 6),
                                  ),
                                ],
                        ),
                        child: FilledButton(
                          onPressed: _isConnecting ? null : _connect,
                          style: FilledButton.styleFrom(
                            backgroundColor: _isConnecting
                                ? AppTheme.bgCardLight
                                : Colors.transparent,
                            shadowColor: Colors.transparent,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: _isConnecting
                              ? Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2.5,
                                        color: AppTheme.primary
                                            .withValues(alpha: 0.7),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Text(
                                      'Connecting...',
                                      style: TextStyle(
                                        color: AppTheme.textSecondary,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 15,
                                      ),
                                    ),
                                  ],
                                )
                              : const Text(
                                  'Connect & Add',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: AppTheme.bgDeep,
                                  ),
                                ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _connect() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isConnecting = true;
      _errorMessage = null;
    });

    try {
      String apiUrl = '';
      String? certFingerprint;

      if (widget.mode == AddServerMode.url) {
        apiUrl = _urlController.text.trim();
        certFingerprint = _fingerprintController.text.trim().isEmpty
            ? null
            : _fingerprintController.text.trim();
      } else {
        // Parse JSON
        final json = jsonDecode(_urlController.text.trim());
        apiUrl = json['apiUrl'] as String;
        certFingerprint = json['certSha256'] as String?;
        if (certFingerprint == null || certFingerprint.trim().isEmpty) {
          setState(() {
            _errorMessage = 'JSON must include a "certSha256" field for secure connections.';
          });
          return;
        }
      }

      final config = ServerConfig(
        id: List.generate(16, (_) => Random.secure().nextInt(256).toRadixString(16).padLeft(2, '0')).join(),
        apiUrl: apiUrl,
        name: _nameController.text.trim().isEmpty
            ? null
            : _nameController.text.trim(),
        certFingerprint: certFingerprint,
      );

      await context.read<ServerProvider>().addServer(config);

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle_rounded,
                    color: AppTheme.success, size: 20),
                const SizedBox(width: 10),
                const Text('Server added successfully'),
              ],
            ),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _errorMessage =
            'Could not connect to server. Check the URL and try again.';
      });
    } finally {
      if (mounted) {
        setState(() => _isConnecting = false);
      }
    }
  }
}

// ─── Field Label ──────────────────────────────────────────────────

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(
      {required this.label, required this.icon, this.optional = false});
  final String label;
  final IconData icon;
  final bool optional;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: AppTheme.textSecondary,
                fontWeight: FontWeight.w600,
              ),
        ),
        if (optional) ...[
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: AppTheme.surfaceDim.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              'optional',
              style: TextStyle(
                color: AppTheme.textMuted.withValues(alpha: 0.7),
                fontSize: 10,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ],
    );
  }
}
