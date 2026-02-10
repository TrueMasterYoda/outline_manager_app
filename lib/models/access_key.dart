class AccessKey {
  const AccessKey({
    required this.id,
    required this.name,
    this.accessUrl,
    this.password,
    this.method,
    this.port,
    this.dataLimit,
    this.dataUsageBytes,
  });

  final String id;
  final String name;
  final String? accessUrl;
  final String? password;
  final String? method;
  final int? port;
  final DataLimit? dataLimit;
  final int? dataUsageBytes;

  factory AccessKey.fromJson(Map<String, dynamic> json) {
    return AccessKey(
      id: json['id'].toString(),
      name: (json['name'] ?? '').toString(),
      accessUrl: json['accessUrl'] as String?,
      password: json['password'] as String?,
      method: json['method'] as String?,
      port: json['port'] is int
          ? json['port'] as int
          : int.tryParse('${json['port']}'),
      dataLimit: json['dataLimit'] != null
          ? DataLimit.fromJson(json['dataLimit'] as Map<String, dynamic>)
          : null,
    );
  }

  AccessKey copyWith({
    String? id,
    String? name,
    String? accessUrl,
    String? password,
    String? method,
    int? port,
    DataLimit? dataLimit,
    int? dataUsageBytes,
    bool clearDataLimit = false,
  }) {
    return AccessKey(
      id: id ?? this.id,
      name: name ?? this.name,
      accessUrl: accessUrl ?? this.accessUrl,
      password: password ?? this.password,
      method: method ?? this.method,
      port: port ?? this.port,
      dataLimit: clearDataLimit ? null : (dataLimit ?? this.dataLimit),
      dataUsageBytes: dataUsageBytes ?? this.dataUsageBytes,
    );
  }
}

class DataLimit {
  const DataLimit({required this.bytes});

  final int bytes;

  factory DataLimit.fromJson(Map<String, dynamic> json) {
    return DataLimit(bytes: json['bytes'] as int? ?? 0);
  }

  Map<String, dynamic> toJson() => {'bytes': bytes};
}
