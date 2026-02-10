import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(const OutlineManagerApp());
}

class OutlineManagerApp extends StatelessWidget {
  const OutlineManagerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Outline Mobile Manager',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
      ),
      home: const ServerListPage(),
    );
  }
}

class OutlineServerProfile {
  const OutlineServerProfile({
    required this.id,
    required this.name,
    required this.apiUrl,
  });

  final String id;
  final String name;
  final String apiUrl;

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'apiUrl': apiUrl,
      };

  factory OutlineServerProfile.fromJson(Map<String, dynamic> json) {
    return OutlineServerProfile(
      id: json['id'] as String,
      name: json['name'] as String,
      apiUrl: json['apiUrl'] as String,
    );
  }
}

class OutlineServerRepository {
  static const _storageKey = 'servers.v1';

  Future<List<OutlineServerProfile>> loadServers() async {
    final prefs = await SharedPreferences.getInstance();
    final rawServers = prefs.getStringList(_storageKey) ?? [];

    return rawServers
        .map((entry) => OutlineServerProfile.fromJson(
              jsonDecode(entry) as Map<String, dynamic>,
            ))
        .toList();
  }

  Future<void> saveServers(List<OutlineServerProfile> servers) async {
    final prefs = await SharedPreferences.getInstance();
    final rawServers = servers.map((server) => jsonEncode(server.toJson())).toList();
    await prefs.setStringList(_storageKey, rawServers);
  }
}

class OutlineAccessKey {
  const OutlineAccessKey({
    required this.id,
    required this.name,
    required this.password,
    required this.port,
    required this.method,
    required this.accessUrl,
    required this.usedBytes,
    required this.dataLimitBytes,
  });

  final String id;
  final String name;
  final String password;
  final int port;
  final String method;
  final String accessUrl;
  final int usedBytes;
  final int? dataLimitBytes;

  String get displayName => name.isEmpty ? 'Key $id' : name;

  factory OutlineAccessKey.fromJson(Map<String, dynamic> json) {
    final limit = json['dataLimit'] as Map<String, dynamic>?;

    return OutlineAccessKey(
      id: json['id'].toString(),
      name: json['name'] as String? ?? '',
      password: json['password'] as String? ?? '',
      port: json['port'] as int? ?? 0,
      method: json['method'] as String? ?? '',
      accessUrl: json['accessUrl'] as String? ?? '',
      usedBytes: json['usedBytes'] as int? ?? 0,
      dataLimitBytes: limit?['bytes'] as int?,
    );
  }
}

class OutlineApiException implements Exception {
  const OutlineApiException(this.message);

  final String message;

  @override
  String toString() => message;
}

class OutlineApi {
  const OutlineApi(this.baseUrl);

  final String baseUrl;

  Uri _uri(String path) {
    final trimmedBaseUrl = baseUrl.endsWith('/') ? baseUrl.substring(0, baseUrl.length - 1) : baseUrl;
    final normalizedPath = path.startsWith('/') ? path.substring(1) : path;
    return Uri.parse('$trimmedBaseUrl/$normalizedPath');
  }

  Future<Map<String, dynamic>> getServerInfo() async {
    final response = await http.get(_uri('/server'));
    return _decodeObjectResponse(response);
  }

  Future<List<OutlineAccessKey>> fetchAccessKeys() async {
    final response = await http.get(_uri('/access-keys'));
    final body = _decodeObjectResponse(response);
    final keys = body['accessKeys'] as List<dynamic>? ?? [];
    return keys
        .map((entry) => OutlineAccessKey.fromJson(entry as Map<String, dynamic>))
        .toList();
  }

  Future<void> createAccessKey({required String name}) async {
    final response = await http.post(_uri('/access-keys'));
    final key = _decodeObjectResponse(response);
    if (name.trim().isNotEmpty) {
      await renameAccessKey(key['id'].toString(), name);
    }
  }

  Future<void> deleteAccessKey(String keyId) async {
    final response = await http.delete(_uri('/access-keys/$keyId'));
    if (response.statusCode != 204) {
      throw OutlineApiException('Delete failed (${response.statusCode}): ${response.body}');
    }
  }

  Future<void> renameAccessKey(String keyId, String name) async {
    final response = await http.put(
      _uri('/access-keys/$keyId/name'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'name': name}),
    );
    _decodeObjectResponse(response);
  }

  Future<void> setDataLimit(String keyId, int? bytes) async {
    final response = await http.put(
      _uri('/access-keys/$keyId/data-limit'),
      headers: {'Content-Type': 'application/json'},
      body: bytes == null ? jsonEncode({}) : jsonEncode({'limit': {'bytes': bytes}}),
    );

    if (response.statusCode != 204) {
      throw OutlineApiException(
        'Updating data limit failed (${response.statusCode}): ${response.body}',
      );
    }
  }

  Map<String, dynamic> _decodeObjectResponse(http.Response response) {
    if (response.statusCode < 200 || response.statusCode > 299) {
      throw OutlineApiException('Request failed (${response.statusCode}): ${response.body}');
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      throw const OutlineApiException('Unexpected response format from server API.');
    }

    return decoded;
  }
}

class ServerListPage extends StatefulWidget {
  const ServerListPage({super.key});

  @override
  State<ServerListPage> createState() => _ServerListPageState();
}

class _ServerListPageState extends State<ServerListPage> {
  final OutlineServerRepository _repository = OutlineServerRepository();
  List<OutlineServerProfile> _servers = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadServers();
  }

  Future<void> _loadServers() async {
    final servers = await _repository.loadServers();
    if (!mounted) {
      return;
    }

    setState(() {
      _servers = servers;
      _loading = false;
    });
  }

  Future<void> _addServer() async {
    final createdServer = await showDialog<OutlineServerProfile>(
      context: context,
      builder: (_) => const AddServerDialog(),
    );

    if (createdServer == null) {
      return;
    }

    setState(() {
      _servers = [..._servers, createdServer];
    });
    await _repository.saveServers(_servers);
  }

  Future<void> _deleteServer(OutlineServerProfile server) async {
    setState(() {
      _servers = _servers.where((candidate) => candidate.id != server.id).toList();
    });
    await _repository.saveServers(_servers);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Outline Mobile Manager'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _servers.isEmpty
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 24),
                    child: Text(
                      'No servers yet. Tap + to add your Outline API URL.',
                      textAlign: TextAlign.center,
                    ),
                  ),
                )
              : ListView.builder(
                  itemCount: _servers.length,
                  itemBuilder: (_, index) {
                    final server = _servers[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      child: ListTile(
                        title: Text(server.name),
                        subtitle: Text(server.apiUrl),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete_outline),
                          onPressed: () => _deleteServer(server),
                        ),
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) => ServerDetailsPage(server: server),
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addServer,
        child: const Icon(Icons.add),
      ),
    );
  }
}

class AddServerDialog extends StatefulWidget {
  const AddServerDialog({super.key});

  @override
  State<AddServerDialog> createState() => _AddServerDialogState();
}

class _AddServerDialogState extends State<AddServerDialog> {
  final _nameController = TextEditingController();
  final _apiUrlController = TextEditingController();
  String? _errorMessage;

  @override
  void dispose() {
    _nameController.dispose();
    _apiUrlController.dispose();
    super.dispose();
  }

  void _submit() {
    final name = _nameController.text.trim();
    final apiUrl = _apiUrlController.text.trim();

    if (name.isEmpty || apiUrl.isEmpty) {
      setState(() {
        _errorMessage = 'Name and API URL are required.';
      });
      return;
    }

    final uri = Uri.tryParse(apiUrl);
    if (uri == null || !(uri.isScheme('http') || uri.isScheme('https'))) {
      setState(() {
        _errorMessage = 'Please enter a valid HTTP(S) API URL.';
      });
      return;
    }

    Navigator.of(context).pop(
      OutlineServerProfile(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        name: name,
        apiUrl: apiUrl,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add Outline Server'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _nameController,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(labelText: 'Display name'),
            ),
            TextField(
              controller: _apiUrlController,
              keyboardType: TextInputType.url,
              decoration: const InputDecoration(
                labelText: 'API URL',
                hintText: 'https://example.com/SECRET/',
              ),
            ),
            if (_errorMessage != null)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text(
                  _errorMessage!,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.error,
                  ),
                ),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _submit,
          child: const Text('Save'),
        ),
      ],
    );
  }
}

class ServerDetailsPage extends StatefulWidget {
  const ServerDetailsPage({super.key, required this.server});

  final OutlineServerProfile server;

  @override
  State<ServerDetailsPage> createState() => _ServerDetailsPageState();
}

class _ServerDetailsPageState extends State<ServerDetailsPage> {
  bool _loading = true;
  String? _error;
  String? _serverName;
  List<OutlineAccessKey> _keys = [];

  OutlineApi get _api => OutlineApi(widget.server.apiUrl);

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final serverInfo = await _api.getServerInfo();
      final keys = await _api.fetchAccessKeys();

      if (!mounted) {
        return;
      }

      setState(() {
        _serverName = serverInfo['name'] as String?;
        _keys = keys;
      });
    } on Exception catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _error = error.toString();
      });
    } finally {
      if (!mounted) {
        return;
      }

      setState(() {
        _loading = false;
      });
    }
  }

  Future<void> _addKey() async {
    final controller = TextEditingController();
    final keyName = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Create Access Key'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'Optional name'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(controller.text.trim()),
            child: const Text('Create'),
          ),
        ],
      ),
    );
    controller.dispose();

    if (keyName == null) {
      return;
    }

    try {
      await _api.createAccessKey(name: keyName);
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Access key created.')),
      );
      await _refresh();
    } on Exception catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.toString())),
      );
    }
  }

  Future<void> _deleteKey(OutlineAccessKey key) async {
    try {
      await _api.deleteAccessKey(key.id);
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Deleted ${key.displayName}.')),
      );
      await _refresh();
    } on Exception catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.toString())),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_serverName ?? widget.server.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refresh,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      _error!,
                      style: TextStyle(color: Theme.of(context).colorScheme.error),
                      textAlign: TextAlign.center,
                    ),
                  ),
                )
              : _keys.isEmpty
                  ? const Center(child: Text('No access keys found.'))
                  : ListView.builder(
                      itemCount: _keys.length,
                      itemBuilder: (_, index) {
                        final key = _keys[index];
                        return Card(
                          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          child: ListTile(
                            title: Text(key.displayName),
                            subtitle: Text(
                              '${key.method}:${key.port}\nUsed: ${_formatBytes(key.usedBytes)}${key.dataLimitBytes == null ? '' : ' / Limit: ${_formatBytes(key.dataLimitBytes!)}'}',
                            ),
                            isThreeLine: true,
                            trailing: IconButton(
                              icon: const Icon(Icons.delete_outline),
                              onPressed: () => _deleteKey(key),
                            ),
                          ),
                        );
                      },
                    ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addKey,
        icon: const Icon(Icons.vpn_key),
        label: const Text('Add key'),
      ),
    );
  }

  String _formatBytes(int bytes) {
    if (bytes < 1024) {
      return '$bytes B';
    }

    const units = ['KB', 'MB', 'GB', 'TB'];
    var value = bytes / 1024;
    var unitIndex = 0;
    while (value >= 1024 && unitIndex < units.length - 1) {
      value /= 1024;
      unitIndex += 1;
    }

    return '${value.toStringAsFixed(2)} ${units[unitIndex]}';
  }
}
