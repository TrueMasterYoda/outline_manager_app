import 'dart:convert';

/// Local configuration for a saved Outline server.
/// Persisted to FlutterSecureStorage.
class ServerConfig {
  ServerConfig({
    required this.id,
    required this.apiUrl,
    this.name,
    this.certFingerprint,
  });

  final String id;
  final String apiUrl;
  String? name;
  final String? certFingerprint;

  factory ServerConfig.fromJson(Map<String, dynamic> json) {
    return ServerConfig(
      id: json['id'] as String,
      apiUrl: json['apiUrl'] as String,
      name: json['name'] as String?,
      certFingerprint: json['certFingerprint'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'apiUrl': apiUrl,
        'name': name,
        'certFingerprint': certFingerprint,
      };

  String toJsonString() => jsonEncode(toJson());

  factory ServerConfig.fromJsonString(String jsonString) {
    return ServerConfig.fromJson(
        jsonDecode(jsonString) as Map<String, dynamic>);
  }

  /// Extracts the host from the apiUrl for display.
  String get host {
    try {
      final uri = Uri.parse(apiUrl);
      return uri.host;
    } catch (_) {
      return apiUrl;
    }
  }

  /// Display name: user-set name, or hostname fallback.
  String get displayName => name?.isNotEmpty == true ? name! : host;
}
