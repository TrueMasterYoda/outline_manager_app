import 'package:flutter/material.dart';

import '../models/access_key.dart';
import '../models/server.dart';
import '../models/server_config.dart';
import '../services/outline_api_service.dart';
import '../services/server_storage.dart';

/// Central state manager for all Outline servers.
class ServerProvider extends ChangeNotifier {
  final ServerStorage _storage = ServerStorage();
  final Map<String, OutlineApiService> _apiServices = {};

  List<ServerConfig> _servers = [];
  List<ServerConfig> get servers => _servers;

  ServerConfig? _selectedServer;
  ServerConfig? get selectedServer => _selectedServer;

  Server? _serverInfo;
  Server? get serverInfo => _serverInfo;

  List<AccessKey> _accessKeys = [];
  List<AccessKey> get accessKeys => _accessKeys;

  Map<String, int> _dataTransfer = {};
  Map<String, int> get dataTransfer => _dataTransfer;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _error;
  String? get error => _error;

  bool _isConnected = false;
  bool get isConnected => _isConnected;

  // ─── Initialization ───────────────────────────────────────────────

  Future<void> loadSavedServers() async {
    _servers = await _storage.loadServers();
    notifyListeners();
  }

  // ─── Server Management ────────────────────────────────────────────

  OutlineApiService _getApi(ServerConfig config) {
    return _apiServices.putIfAbsent(
      config.id,
      () => OutlineApiService(
        apiUrl: config.apiUrl,
        certFingerprint: config.certFingerprint,
      ),
    );
  }

  Future<void> addServer(ServerConfig config) async {
    _setLoading(true);
    _clearError();
    try {
      // Test connectivity first
      final api = OutlineApiService(
        apiUrl: config.apiUrl,
        certFingerprint: config.certFingerprint,
      );
      final info = await api.getServerInfo();

      // Use server name if user didn't provide one
      if (config.name == null || config.name!.isEmpty) {
        config.name = info.name;
      }

      _apiServices[config.id] = api;
      _servers.add(config);
      await _storage.saveServers(_servers);
      notifyListeners();
    } catch (e) {
      _setError('Failed to connect: ${e.toString()}');
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> removeServer(String id) async {
    _apiServices[id]?.dispose();
    _apiServices.remove(id);
    _servers.removeWhere((s) => s.id == id);
    await _storage.saveServers(_servers);

    if (_selectedServer?.id == id) {
      _selectedServer = null;
      _serverInfo = null;
      _accessKeys = [];
      _dataTransfer = {};
      _isConnected = false;
    }
    notifyListeners();
  }

  // ─── Select & Load Server ─────────────────────────────────────────

  Future<void> selectServer(ServerConfig config) async {
    _selectedServer = config;
    _isConnected = false;
    _serverInfo = null;
    _accessKeys = [];
    _dataTransfer = {};
    _clearError();
    notifyListeners();

    await refreshServerData();
  }

  Future<void> refreshServerData() async {
    if (_selectedServer == null) return;
    _setLoading(true);
    _clearError();

    try {
      final api = _getApi(_selectedServer!);
      _serverInfo = await api.getServerInfo();
      _isConnected = true;

      // Load access keys and metrics in parallel
      final results = await Future.wait([
        api.listAccessKeys(),
        api.getDataTransfer(),
      ]);

      final keys = results[0] as List<AccessKey>;
      _dataTransfer = results[1] as Map<String, int>;

      // Merge usage data into access keys
      _accessKeys = keys.map((k) {
        final usage = _dataTransfer[k.id];
        return usage != null ? k.copyWith(dataUsageBytes: usage) : k;
      }).toList();
    } catch (e) {
      _isConnected = false;
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  // ─── Access Key Operations ────────────────────────────────────────

  Future<void> createAccessKey({String? name}) async {
    if (_selectedServer == null) return;
    _clearError();
    try {
      final api = _getApi(_selectedServer!);
      await api.createAccessKey(name: name);
      await refreshServerData();
    } catch (e) {
      _setError('Failed to create key: $e');
      rethrow;
    }
  }

  Future<void> deleteAccessKey(String id) async {
    if (_selectedServer == null) return;
    _clearError();
    try {
      final api = _getApi(_selectedServer!);
      await api.deleteAccessKey(id);
      await refreshServerData();
    } catch (e) {
      _setError('Failed to delete key: $e');
      rethrow;
    }
  }

  Future<void> renameAccessKey(String id, String name) async {
    if (_selectedServer == null) return;
    _clearError();
    try {
      final api = _getApi(_selectedServer!);
      await api.renameAccessKey(id, name);
      await refreshServerData();
    } catch (e) {
      _setError('Failed to rename key: $e');
      rethrow;
    }
  }

  Future<void> setKeyDataLimit(String id, int bytes) async {
    if (_selectedServer == null) return;
    try {
      final api = _getApi(_selectedServer!);
      await api.setKeyDataLimit(id, bytes);
      await refreshServerData();
    } catch (e) {
      _setError('Failed to set data limit: $e');
      rethrow;
    }
  }

  Future<void> removeKeyDataLimit(String id) async {
    if (_selectedServer == null) return;
    try {
      final api = _getApi(_selectedServer!);
      await api.removeKeyDataLimit(id);
      await refreshServerData();
    } catch (e) {
      _setError('Failed to remove data limit: $e');
      rethrow;
    }
  }

  // ─── Server Settings ──────────────────────────────────────────────

  Future<void> renameServer(String name) async {
    if (_selectedServer == null) return;
    try {
      final api = _getApi(_selectedServer!);
      await api.renameServer(name);
      _selectedServer!.name = name;
      await _storage.updateServer(_selectedServer!);
      await refreshServerData();
    } catch (e) {
      _setError('Failed to rename server: $e');
      rethrow;
    }
  }

  Future<void> setHostname(String hostname) async {
    if (_selectedServer == null) return;
    try {
      final api = _getApi(_selectedServer!);
      await api.setHostname(hostname);
      await refreshServerData();
    } catch (e) {
      _setError('Failed to set hostname: $e');
      rethrow;
    }
  }

  Future<void> setPort(int port) async {
    if (_selectedServer == null) return;
    try {
      final api = _getApi(_selectedServer!);
      await api.setPortForNewKeys(port);
      await refreshServerData();
    } catch (e) {
      _setError('Failed to set port: $e');
      rethrow;
    }
  }

  Future<void> setGlobalDataLimit(int bytes) async {
    if (_selectedServer == null) return;
    try {
      final api = _getApi(_selectedServer!);
      await api.setGlobalDataLimit(bytes);
      await refreshServerData();
    } catch (e) {
      _setError('Failed to set global data limit: $e');
      rethrow;
    }
  }

  Future<void> removeGlobalDataLimit() async {
    if (_selectedServer == null) return;
    try {
      final api = _getApi(_selectedServer!);
      await api.removeGlobalDataLimit();
      await refreshServerData();
    } catch (e) {
      _setError('Failed to remove global data limit: $e');
      rethrow;
    }
  }

  Future<void> setMetricsEnabled(bool enabled) async {
    if (_selectedServer == null) return;
    try {
      final api = _getApi(_selectedServer!);
      await api.setMetricsEnabled(enabled);
      await refreshServerData();
    } catch (e) {
      _setError('Failed to update metrics setting: $e');
      rethrow;
    }
  }

  // ─── Helpers ──────────────────────────────────────────────────────

  int get totalDataTransferred =>
      _dataTransfer.values.fold(0, (sum, v) => sum + v);

  void _setLoading(bool val) {
    _isLoading = val;
    notifyListeners();
  }

  void _setError(String msg) {
    _error = msg;
    notifyListeners();
  }

  void _clearError() {
    _error = null;
  }

  @override
  void dispose() {
    for (final api in _apiServices.values) {
      api.dispose();
    }
    _apiServices.clear();
    super.dispose();
  }
}
