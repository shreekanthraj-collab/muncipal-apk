import 'dart:convert';

class ApkAccessGrant {
  final String phone;
  final String ward;
  final List<String> zones;
  final List<String> valves;
  final bool enabled;

  const ApkAccessGrant({
    required this.phone,
    this.ward = '',
    required this.zones,
    this.valves = const [],
    required this.enabled,
  });

  Map<String, dynamic> toJson() => {
        'phone': phone,
        'ward': ward,
        'zones': List<String>.from(zones),
        'valves': List<String>.from(valves),
        'enabled': enabled,
      };

  factory ApkAccessGrant.fromJson(Map<String, dynamic> json) {
    final zones = json['zones'];
    final valves = json['valves'];
    return ApkAccessGrant(
      phone: (json['phone'] ?? '').toString(),
      ward: (json['ward'] ?? '').toString(),
      zones: zones is List
          ? zones.map((e) => e.toString()).toList(growable: false)
          : const [],
      valves: valves is List
          ? valves.map((e) => e.toString()).toList(growable: false)
          : const [],
      enabled: json['enabled'] == true,
    );
  }
}

class ApkAccessSnapshot {
  static const schema = 'orb.apk-access.v1';

  final List<ApkAccessGrant> grants;

  const ApkAccessSnapshot({required this.grants});

  Map<String, dynamic> toJson() => {
        'schema': schema,
        'grants': grants.map((grant) => grant.toJson()).toList(),
      };

  String encode() => jsonEncode(toJson());

  factory ApkAccessSnapshot.fromJson(Map<String, dynamic> json) {
    if (json['schema'] != schema) {
      throw const FormatException('Unsupported APK access schema');
    }

    final raw = json['grants'];
    if (raw is! List) {
      throw const FormatException('APK access grants are missing');
    }

    return ApkAccessSnapshot(
      grants: raw
          .whereType<Map>()
          .map((item) => ApkAccessGrant.fromJson(
                Map<String, dynamic>.from(item),
              ))
          .toList(growable: false),
    );
  }

  factory ApkAccessSnapshot.decode(String payload) {
    final decoded = jsonDecode(payload);
    if (decoded is! Map) {
      throw const FormatException('APK access payload is not an object');
    }
    return ApkAccessSnapshot.fromJson(
      Map<String, dynamic>.from(decoded),
    );
  }
}

const String apkAccessSnapshotTopic = 'orb/scada/apk-access/v1/snapshot';
