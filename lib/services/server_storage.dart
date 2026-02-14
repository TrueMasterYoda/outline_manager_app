import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/server_config.dart';

/// Persists saved server configurations to encrypted secure storage.
///
/// On first access after upgrade, existing data is automatically migrated
/// from SharedPreferences (plaintext) to FlutterSecureStorage (encrypted).
class ServerStorage {
  static const _secureKey = 'outline_servers_secure';
  static const _legacyKey = 'outline_servers';
  static const _migratedKey = 'outline_servers_migrated';

  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  /// Migrates data from SharedPreferences to secure storage if needed.
  Future<void> _migrateIfNeeded() async {
    final prefs = await SharedPreferences.getInstance();
    final alreadyMigrated = prefs.getBool(_migratedKey) ?? false;
    if (alreadyMigrated) return;

    final legacy = prefs.getStringList(_legacyKey);
    if (legacy != null && legacy.isNotEmpty) {
      // Write legacy data into secure storage.
      await _secureStorage.write(
        key: _secureKey,
        value: jsonEncode(legacy),
      );
      // Remove plaintext data.
      await prefs.remove(_legacyKey);
    }
    await prefs.setBool(_migratedKey, true);
  }

  Future<List<ServerConfig>> loadServers() async {
    await _migrateIfNeeded();
    final raw = await _secureStorage.read(key: _secureKey);
    if (raw == null) return [];
    final list = (jsonDecode(raw) as List<dynamic>).cast<String>();
    return list.map((s) {
      final json = jsonDecode(s) as Map<String, dynamic>;
      return ServerConfig.fromJson(json);
    }).toList();
  }

  Future<void> saveServers(List<ServerConfig> servers) async {
    final raw = servers.map((s) => jsonEncode(s.toJson())).toList();
    await _secureStorage.write(
      key: _secureKey,
      value: jsonEncode(raw),
    );
  }

  Future<void> addServer(ServerConfig server) async {
    final servers = await loadServers();
    servers.add(server);
    await saveServers(servers);
  }

  Future<void> removeServer(String id) async {
    final servers = await loadServers();
    servers.removeWhere((s) => s.id == id);
    await saveServers(servers);
  }

  Future<void> updateServer(ServerConfig server) async {
    final servers = await loadServers();
    final index = servers.indexWhere((s) => s.id == server.id);
    if (index != -1) {
      servers[index] = server;
      await saveServers(servers);
    }
  }
}
