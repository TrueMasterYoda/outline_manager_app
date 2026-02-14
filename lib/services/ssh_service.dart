import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dartssh2/dartssh2.dart';

class SshService {
  SSHClient? _client;
  final StringBuffer _outputBuffer = StringBuffer();

  /// Connects to the SSH server.
  Future<void> connect({
    required String host,
    required int port,
    required String username,
    String? password,
    String? privateKey,
  }) async {
    try {
      final socket = await SSHSocket.connect(host, port);

      List<SSHKeyPair> identities = [];
      if (privateKey != null && privateKey.isNotEmpty) {
        try {
          identities = SSHKeyPair.fromPem(privateKey);
        } catch (e) {
          // Silently handle parse failure — do not log key material
        }
      }

      _client = SSHClient(
        socket,
        username: username,
        onPasswordRequest: password != null ? () => password : null,
        identities: identities,
      );

      await _client!.authenticated;
    } catch (e) {
      throw Exception('Failed to connect: $e');
    }
  }

  /// Runs the Outline installation script and streams the output.
  /// The stream emits output chunks. When installation completes and the
  /// config JSON is detected, it emits a special marker and closes.
  Stream<String> installOutlineServer() {
    if (_client == null) throw Exception('SSH Client not connected');

    _outputBuffer.clear();
    final controller = StreamController<String>();
    _runInstall(controller);
    return controller.stream;
  }

  Future<void> _runInstall(StreamController<String> controller) async {
    try {
      final session = await _client!.shell(
        pty: SSHPtyConfig(width: 500, height: 24),
      );

      await Future.delayed(const Duration(seconds: 1));

      const installCommand =
          'sudo bash -c "\$(wget -qO- https://raw.githubusercontent.com/Jigsaw-Code/outline-apps/master/server_manager/install_scripts/install_server.sh)"';

      session.write(Uint8List.fromList(utf8.encode('$installCommand\n')));

      bool configDetected = false;

      final stdoutSubscription = session.stdout.listen((data) {
        final output = utf8.decode(data, allowMalformed: true);
        _outputBuffer.write(output);
        controller.add(output);

        // Auto-answer Y/N prompts
        if (output.toLowerCase().contains('[y/n]')) {
          session.write(Uint8List.fromList(utf8.encode('Y\n')));
        }

        // Check if the config JSON has appeared in the accumulated output
        if (!configDetected) {
          final parsed = parseInstallOutput(_outputBuffer.toString());
          if (parsed != null) {
            configDetected = true;
            // Give a short delay to collect any remaining output
            Future.delayed(const Duration(seconds: 3), () {
              if (!controller.isClosed) {
                controller.close();
              }
              session.close();
            });
          }
        }
      }, onError: (e) {
        controller.addError(e);
      });

      final stderrSubscription = session.stderr.listen((data) {
        final output = utf8.decode(data, allowMalformed: true);
        _outputBuffer.write(output);
        controller.add(output);
      }, onError: (e) {
        controller.addError(e);
      });

      // If session.done fires (e.g. connection drops), also close
      await session.done;
      
      await stdoutSubscription.cancel();
      await stderrSubscription.cancel();

      if (!controller.isClosed) {
        controller.close();
      }
    } catch (e) {
      if (!controller.isClosed) {
        controller.addError(e);
        controller.close();
      }
    }
  }

  /// Returns the full accumulated output buffer.
  String get fullOutput => _outputBuffer.toString();

  /// Parses the install log to find the JSON config.
  String? parseInstallOutput(String fullLog) {
    // 1. Strip ANSI escape codes
    final ansiRegex = RegExp(r'\x1B(?:[@-Z\\-_]|\[[0-?]*[ -/]*[@-~])');
    final cleanLog = fullLog.replaceAll(ansiRegex, '');

    // 2. Extract fields individually
    final apiUrlRegex = RegExp(r'"apiUrl"\s*:\s*"([^"]+)"');
    final certRegex = RegExp(r'"certSha256"\s*:\s*"([^"]+)"');

    final apiUrlMatch = apiUrlRegex.firstMatch(cleanLog);
    final certMatch = certRegex.firstMatch(cleanLog);

    if (apiUrlMatch != null) {
      final apiUrl = apiUrlMatch.group(1);
      final certSha256 = certMatch?.group(1);

      final Map<String, dynamic> config = {
        'apiUrl': apiUrl,
        if (certSha256 != null) 'certSha256': certSha256,
      };
      
      return jsonEncode(config);
    }
    
    return null;
  }

  Future<void> disconnect() async {
    _client?.close();
    await _client?.done;
    _client = null;
  }
}
