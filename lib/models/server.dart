import 'access_key.dart';

class Server {
  const Server({
    required this.name,
    required this.serverId,
    required this.metricsEnabled,
    required this.createdTimestampMs,
    this.version,
    this.portForNewAccessKeys,
    this.hostnameForAccessKeys,
    this.accessKeyDataLimit,
  });

  final String name;
  final String serverId;
  final bool metricsEnabled;
  final int createdTimestampMs;
  final String? version;
  final int? portForNewAccessKeys;
  final String? hostnameForAccessKeys;
  final DataLimit? accessKeyDataLimit;

  factory Server.fromJson(Map<String, dynamic> json) {
    return Server(
      name: (json['name'] ?? 'Outline Server').toString(),
      serverId: (json['serverId'] ?? '').toString(),
      metricsEnabled: json['metricsEnabled'] as bool? ?? false,
      createdTimestampMs: json['createdTimestampMs'] as int? ?? 0,
      version: json['version'] as String?,
      portForNewAccessKeys: json['portForNewAccessKeys'] as int?,
      hostnameForAccessKeys: json['hostnameForAccessKeys'] as String?,
      accessKeyDataLimit: json['accessKeyDataLimit'] != null
          ? DataLimit.fromJson(
              json['accessKeyDataLimit'] as Map<String, dynamic>)
          : null,
    );
  }

  Server copyWith({
    String? name,
    bool? metricsEnabled,
    int? portForNewAccessKeys,
    String? hostnameForAccessKeys,
    DataLimit? accessKeyDataLimit,
    bool clearDataLimit = false,
  }) {
    return Server(
      name: name ?? this.name,
      serverId: serverId,
      metricsEnabled: metricsEnabled ?? this.metricsEnabled,
      createdTimestampMs: createdTimestampMs,
      version: version,
      portForNewAccessKeys: portForNewAccessKeys ?? this.portForNewAccessKeys,
      hostnameForAccessKeys:
          hostnameForAccessKeys ?? this.hostnameForAccessKeys,
      accessKeyDataLimit:
          clearDataLimit ? null : (accessKeyDataLimit ?? this.accessKeyDataLimit),
    );
  }
}
