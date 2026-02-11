import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';

import '../models/access_key.dart';
import '../models/server.dart';

/// HTTP client wrapping the Outline Server Management API.
/// Handles self-signed certificate verification via SHA-256 fingerprint.
class OutlineApiService {
  OutlineApiService({
    required this.apiUrl,
    this.certFingerprint,
  });

  final String apiUrl;
  final String? certFingerprint;
  HttpClient? _httpClient;

  HttpClient get _client {
    if (_httpClient != null) return _httpClient!;
    _httpClient = HttpClient()
      ..badCertificateCallback = (X509Certificate cert, String host, int port) {
        // Accept self-signed certs — optionally verify fingerprint
        if (certFingerprint == null || certFingerprint!.isEmpty) return true;
        
        final digest = sha256.convert(cert.der);
        // Normalize computed hash: lowercase, no colons
        final certHex = digest.bytes
            .map((b) => b.toRadixString(16).padLeft(2, '0'))
            .join()
            .toLowerCase();
            
        // Normalize expected fingerprint: lowercase, no colons
        final expected = certFingerprint!
            .replaceAll(':', '')
            .toLowerCase();
            
        return certHex == expected;
      };
    return _httpClient!;
  }

  void dispose() {
    _httpClient?.close(force: true);
    _httpClient = null;
  }

  // ─── Helpers ──────────────────────────────────────────────────────

  Uri _uri(String path) => Uri.parse('$apiUrl$path');

  Future<HttpClientResponse> _request(
    String method,
    String path, {
    Map<String, dynamic>? body,
  }) async {
    final uri = _uri(path);
    final request = await _openRequest(method, uri);
    request.headers.set('Content-Type', 'application/json');

    if (body != null) {
      request.write(jsonEncode(body));
    }

    return request.close();
  }

  Future<HttpClientRequest> _openRequest(String method, Uri uri) {
    switch (method.toUpperCase()) {
      case 'GET':
        return _client.getUrl(uri);
      case 'POST':
        return _client.postUrl(uri);
      case 'PUT':
        return _client.putUrl(uri);
      case 'DELETE':
        return _client.deleteUrl(uri);
      default:
        return _client.openUrl(method, uri);
    }
  }

  Future<Map<String, dynamic>> _jsonResponse(HttpClientResponse response) async {
    final body = await response.transform(utf8.decoder).join();
    if (body.isEmpty) return {};
    return jsonDecode(body) as Map<String, dynamic>;
  }

  // ─── Server ───────────────────────────────────────────────────────

  /// GET /server — Returns server information.
  Future<Server> getServerInfo() async {
    final response = await _request('GET', '/server');
    if (response.statusCode != 200) {
      throw ApiException('Failed to get server info', response.statusCode);
    }
    final json = await _jsonResponse(response);
    return Server.fromJson(json);
  }

  /// PUT /name — Renames the server.
  Future<void> renameServer(String name) async {
    final response = await _request('PUT', '/name', body: {'name': name});
    if (response.statusCode != 204) {
      throw ApiException('Failed to rename server', response.statusCode);
    }
  }

  /// PUT /server/hostname-for-access-keys — Changes the hostname.
  Future<void> setHostname(String hostname) async {
    final response = await _request(
      'PUT',
      '/server/hostname-for-access-keys',
      body: {'hostname': hostname},
    );
    if (response.statusCode != 204) {
      throw ApiException('Failed to set hostname', response.statusCode);
    }
  }

  /// PUT /server/port-for-new-access-keys — Changes the default port.
  Future<void> setPortForNewKeys(int port) async {
    final response = await _request(
      'PUT',
      '/server/port-for-new-access-keys',
      body: {'port': port},
    );
    if (response.statusCode != 204) {
      throw ApiException('Failed to set port', response.statusCode);
    }
  }

  /// PUT /server/access-key-data-limit — Sets a global data limit.
  Future<void> setGlobalDataLimit(int bytes) async {
    final response = await _request(
      'PUT',
      '/server/access-key-data-limit',
      body: {
        'limit': {'bytes': bytes}
      },
    );
    if (response.statusCode != 204) {
      throw ApiException('Failed to set global data limit', response.statusCode);
    }
  }

  /// DELETE /server/access-key-data-limit — Removes the global data limit.
  Future<void> removeGlobalDataLimit() async {
    final response = await _request('DELETE', '/server/access-key-data-limit');
    if (response.statusCode != 204) {
      throw ApiException(
          'Failed to remove global data limit', response.statusCode);
    }
  }

  // ─── Access Keys ──────────────────────────────────────────────────

  /// GET /access-keys — Lists all access keys.
  Future<List<AccessKey>> listAccessKeys() async {
    final response = await _request('GET', '/access-keys/');
    if (response.statusCode != 200) {
      throw ApiException('Failed to list access keys', response.statusCode);
    }
    final json = await _jsonResponse(response);
    final keys = (json['accessKeys'] as List<dynamic>?) ?? [];
    return keys
        .map((k) => AccessKey.fromJson(k as Map<String, dynamic>))
        .toList();
  }

  /// POST /access-keys — Creates a new access key.
  Future<AccessKey> createAccessKey({String? name}) async {
    final body = <String, dynamic>{};
    if (name != null && name.isNotEmpty) body['name'] = name;
    final response = await _request('POST', '/access-keys', body: body);
    if (response.statusCode != 201) {
      throw ApiException('Failed to create access key', response.statusCode);
    }
    final json = await _jsonResponse(response);
    return AccessKey.fromJson(json);
  }

  /// GET /access-keys/{id} — Gets a single access key.
  Future<AccessKey> getAccessKey(String id) async {
    final response = await _request('GET', '/access-keys/$id');
    if (response.statusCode != 200) {
      throw ApiException('Failed to get access key', response.statusCode);
    }
    final json = await _jsonResponse(response);
    return AccessKey.fromJson(json);
  }

  /// DELETE /access-keys/{id} — Deletes an access key.
  Future<void> deleteAccessKey(String id) async {
    final response = await _request('DELETE', '/access-keys/$id');
    if (response.statusCode != 204) {
      throw ApiException('Failed to delete access key', response.statusCode);
    }
  }

  /// PUT /access-keys/{id}/name — Renames an access key.
  Future<void> renameAccessKey(String id, String name) async {
    final response = await _request(
      'PUT',
      '/access-keys/$id/name',
      body: {'name': name},
    );
    if (response.statusCode != 204) {
      throw ApiException('Failed to rename access key', response.statusCode);
    }
  }

  /// PUT /access-keys/{id}/data-limit — Sets a per-key data limit.
  Future<void> setKeyDataLimit(String id, int bytes) async {
    final response = await _request(
      'PUT',
      '/access-keys/$id/data-limit',
      body: {
        'limit': {'bytes': bytes}
      },
    );
    if (response.statusCode != 204) {
      throw ApiException('Failed to set key data limit', response.statusCode);
    }
  }

  /// DELETE /access-keys/{id}/data-limit — Removes a per-key data limit.
  Future<void> removeKeyDataLimit(String id) async {
    final response =
        await _request('DELETE', '/access-keys/$id/data-limit');
    if (response.statusCode != 204) {
      throw ApiException(
          'Failed to remove key data limit', response.statusCode);
    }
  }

  // ─── Metrics ──────────────────────────────────────────────────────

  /// GET /metrics/transfer — Returns data transferred per access key.
  Future<Map<String, int>> getDataTransfer() async {
    final response = await _request('GET', '/metrics/transfer');
    if (response.statusCode != 200) {
      throw ApiException('Failed to get data transfer', response.statusCode);
    }
    final json = await _jsonResponse(response);
    final byUser =
        json['bytesTransferredByUserId'] as Map<String, dynamic>? ?? {};
    return byUser.map((key, value) => MapEntry(key, (value as num).toInt()));
  }

  /// GET /metrics/enabled — Returns whether metrics sharing is enabled.
  Future<bool> getMetricsEnabled() async {
    final response = await _request('GET', '/metrics/enabled');
    if (response.statusCode != 200) {
      throw ApiException('Failed to get metrics status', response.statusCode);
    }
    final json = await _jsonResponse(response);
    return json['metricsEnabled'] as bool? ?? false;
  }

  /// PUT /metrics/enabled — Enables or disables metrics sharing.
  Future<void> setMetricsEnabled(bool enabled) async {
    final response = await _request(
      'PUT',
      '/metrics/enabled',
      body: {'metricsEnabled': enabled},
    );
    if (response.statusCode != 204) {
      throw ApiException('Failed to set metrics', response.statusCode);
    }
  }

  /// Quick connectivity check — tries to GET /server.
  Future<bool> testConnection() async {
    try {
      await getServerInfo();
      return true;
    } catch (_) {
      return false;
    }
  }
}

class ApiException implements Exception {
  final String message;
  final int statusCode;
  ApiException(this.message, this.statusCode);

  @override
  String toString() => 'ApiException($statusCode): $message';
}
