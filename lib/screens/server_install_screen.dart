import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import '../services/ssh_service.dart';
import '../theme/app_theme.dart';

class ServerInstallScreen extends StatefulWidget {
  const ServerInstallScreen({super.key});

  @override
  State<ServerInstallScreen> createState() => _ServerInstallScreenState();
}

class _ServerInstallScreenState extends State<ServerInstallScreen> {
  final _formKey = GlobalKey<FormState>();
  final _hostController = TextEditingController();
  final _portController = TextEditingController(text: '22');
  final _userController = TextEditingController(text: 'root');
  final _passwordController = TextEditingController();
  final _privateKeyController = TextEditingController();

  bool _isInstalling = false;
  final List<String> _logs = [];
  final ScrollController _scrollController = ScrollController();

  final SshService _sshService = SshService();

  @override
  void dispose() {
    _hostController.dispose();
    _portController.dispose();
    _userController.dispose();
    _passwordController.dispose();
    _privateKeyController.dispose();
    _scrollController.dispose();
    _sshService.disconnect();
    super.dispose();
  }

  Future<void> _pickPrivateKey() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.any, // PEM files might not have a specific extension
      );

      if (result != null && result.files.single.path != null) {
        final file = File(result.files.single.path!);
        final contents = await file.readAsString();
        setState(() {
          _privateKeyController.text = contents;
        });
        if (mounted) {
           ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Private key loaded')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error reading file: $e')),
        );
      }
    }
  }

  Future<void> _startInstall() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isInstalling = true;
      _logs.clear();
      _logs.add("Connecting to ${_hostController.text}...");
    });

    try {
      await _sshService.connect(
        host: _hostController.text,
        port: int.parse(_portController.text),
        username: _userController.text,
        password:
            _passwordController.text.isNotEmpty ? _passwordController.text : null,
        privateKey: _privateKeyController.text.isNotEmpty
            ? _privateKeyController.text
            : null,
      );

      setState(() {
        _logs.add("Connected. Starting installation...");
      });

      final stream = _sshService.installOutlineServer();

      stream.listen((data) {
        if (mounted) {
          setState(() {
            _logs.add(data.trim());
          });
          _scrollToBottom();
        }
      }, onDone: () {
        _finishInstall();
      }, onError: (e) {
        if (mounted) {
          setState(() {
            _logs.add("Error: $e");
          });
          _scrollToBottom();
        }
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _logs.add("Connection Error: $e");
          // Keep _isInstalling true to show the error log
        });
      }
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  /// Extracts port info from the installation output.
  List<String> _extractPorts(String output) {
    final ansiRegex = RegExp(r'\x1B(?:[@-Z\\-_]|\[[0-?]*[ -/]*[@-~])');
    final clean = output.replaceAll(ansiRegex, '');
    final ports = <String>[];

    final mgmtMatch = RegExp(r'Management port (\d+)').firstMatch(clean);
    final accessMatch = RegExp(r'Access key port (\d+)').firstMatch(clean);

    if (mgmtMatch != null) ports.add('Management: ${mgmtMatch.group(1)} (TCP)');
    if (accessMatch != null) ports.add('Access Key: ${accessMatch.group(1)} (TCP & UDP)');

    return ports;
  }

  void _finishInstall() {
    // Use the raw accumulated output from the service for reliable parsing
    final configJson = _sshService.parseInstallOutput(_sshService.fullOutput);

    if (configJson != null) {
      final ports = _extractPorts(_sshService.fullOutput);

      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            title: const Text('Installation Complete'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Outline Server installed successfully!'),
                if (ports.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.warning.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppTheme.warning.withValues(alpha: 0.3)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.warning_amber_rounded, color: AppTheme.warning, size: 20),
                            const SizedBox(width: 8),
                            Text(
                              'Open these ports first!',
                              style: TextStyle(
                                color: AppTheme.warning,
                                fontWeight: FontWeight.w700,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        ...ports.map((p) => Padding(
                              padding: const EdgeInsets.only(left: 28, bottom: 4),
                              child: Text(
                                '• $p',
                                style: const TextStyle(
                                  fontFamily: 'monospace',
                                  fontSize: 13,
                                  color: AppTheme.textPrimary,
                                ),
                              ),
                            )),
                        const SizedBox(height: 8),
                        const Padding(
                          padding: EdgeInsets.only(left: 28),
                          child: Text(
                            'Open these ports on your firewall / cloud provider before continuing, or the app won\'t be able to connect.',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppTheme.textSecondary,
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context); // close dialog
                  Navigator.pop(context, configJson); // return result
                },
                child: const Text('I\'ve opened the ports — Continue'),
              ),
            ],
          ),
        );
      }
    } else {
      if (mounted) {
        setState(() {
          _logs.add(
              "Installation finished but could not find the configuration JSON in the output.");
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgDeep,
      appBar: AppBar(
        title: const Text('Install Server'),
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
        child: _isInstalling ? _buildLogView() : _buildForm(),
      ),
    );
  }

  Widget _buildForm() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
                      Icons.terminal_rounded,
                      color: AppTheme.primary,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      'Enter your VPS SSH credentials. The app will connect and run the installation script for you.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppTheme.textSecondary,
                            height: 1.4,
                          ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 2,
                  child: Column(
                    children: [
                      const _FieldLabel(label: 'Hostname / IP', icon: Icons.dns_rounded),
                      const SizedBox(height: 10),
                      TextFormField(
                        controller: _hostController,
                        decoration: _inputDeco('1.2.3.4', Icons.dns_rounded, AppTheme.primary),
                        style: _inputStyle,
                        validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    children: [
                      const _FieldLabel(label: 'Port', icon: Icons.numbers_rounded),
                      const SizedBox(height: 10),
                      TextFormField(
                        controller: _portController,
                        decoration: _inputDeco('22', Icons.numbers_rounded, AppTheme.accent),
                        style: _inputStyle,
                        keyboardType: TextInputType.number,
                        validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            const _FieldLabel(label: 'Username', icon: Icons.person_rounded),
            const SizedBox(height: 10),
            TextFormField(
              controller: _userController,
              decoration: _inputDeco('root', Icons.person_rounded, AppTheme.purple),
              style: _inputStyle,
              validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
            ),
            const SizedBox(height: 24),

             const _FieldLabel(label: 'Password', icon: Icons.lock_rounded, optional: true),
            const SizedBox(height: 10),
            TextFormField(
              controller: _passwordController,
              decoration: _inputDeco('••••••', Icons.lock_rounded, AppTheme.warning),
              style: _inputStyle,
              obscureText: true,
            ),
             const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.only(left: 4),
                child: Text(
                  'Leave empty if using a private key.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.textMuted.withValues(alpha: 0.7),
                      ),
                ),
              ),
            const SizedBox(height: 24),

             const _FieldLabel(label: 'Private Key', icon: Icons.vpn_key_rounded, optional: true),
            const SizedBox(height: 10),
            TextFormField(
              controller: _privateKeyController,
              decoration: InputDecoration(
                hintText: '-----BEGIN PRIVATE KEY-----\n...',
                prefixIcon: Container(
                  margin: const EdgeInsets.fromLTRB(12, 12, 12, 80), // Align icon to top
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: AppTheme.success.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.vpn_key_rounded, size: 14, color: AppTheme.success),
                ),
                suffixIcon: IconButton(
                  onPressed: _pickPrivateKey,
                  icon: const Icon(Icons.upload_file_rounded, color: AppTheme.textSecondary),
                  tooltip: 'Load from file',
                ),
              ),
              maxLines: 5,
              style: _inputStyle.copyWith(fontSize: 12, height: 1.4),
            ),
            
            const SizedBox(height: 36),
            
            SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          gradient: AppTheme.primaryGradient,
                          boxShadow: [
                                  BoxShadow(
                                    color: AppTheme.primary
                                        .withValues(alpha: 0.35),
                                    blurRadius: 20,
                                    offset: const Offset(0, 6),
                                  ),
                                ],
                        ),
                        child: FilledButton(
                          onPressed: _startInstall,
                           style: FilledButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: const Text(
                            'Connect & Install',
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
    );
  }

  InputDecoration _inputDeco(String hint, IconData icon, Color color) {
    return InputDecoration(
      hintText: hint,
      prefixIcon: Container(
        margin: const EdgeInsets.all(12),
        width: 24,
        height: 24,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, size: 14, color: color),
      ),
    );
  }

  TextStyle get _inputStyle => const TextStyle(
    fontFamily: 'monospace',
    fontSize: 13,
    color: AppTheme.textPrimary,
  );


  Widget _buildLogView() {
    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          color: AppTheme.bgCard,
          child: Column(
             crossAxisAlignment: CrossAxisAlignment.start,
             children: [
               Text(
                 'Installation Log',
                 style: Theme.of(context).textTheme.titleSmall,
               ),
               const SizedBox(height: 4),
               const LinearProgressIndicator(
                 backgroundColor: AppTheme.bgDeep,
                 color: AppTheme.accent,
                 minHeight: 2,
               ),
             ],
          ),
        ),
        Expanded(
          child: Container(
            width: double.infinity,
            color: Colors.black,
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: _logs.length,
              itemBuilder: (context, index) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(
                    _logs[index],
                    style: const TextStyle(
                      color: AppTheme.accentBright,
                      fontFamily: 'monospace',
                      fontSize: 11,
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}

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
