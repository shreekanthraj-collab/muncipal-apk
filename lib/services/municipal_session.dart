import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class MunicipalSession {
  final String accessToken;
  final String operatorId;
  final String organizationId;
  final String phone;
  final String role;
  final List<String> wardIds;
  final List<String> zoneIds;
  final List<String> valveIds;

  const MunicipalSession({
    required this.accessToken,
    required this.operatorId,
    required this.organizationId,
    required this.phone,
    required this.role,
    required this.wardIds,
    required this.zoneIds,
    required this.valveIds,
  });

  bool get isAdmin => const {
        'ADMIN',
        'SCADA_ADMIN',
        'MUNICIPAL_ADMIN',
      }.contains(role.toUpperCase());

  bool get isLineOperator => const {
        'LINE_OPERATOR',
        'OPERATOR',
      }.contains(role.toUpperCase());

  factory MunicipalSession.fromJson(Map<String, dynamic> json) {
    String requiredString(String key) {
      final value = json[key]?.toString().trim() ?? '';
      if (value.isEmpty) throw FormatException('Municipal session is missing $key');
      return value;
    }

    List<String> stringList(String key) {
      final value = json[key];
      if (value == null) return const [];
      if (value is! List) throw FormatException('Municipal session $key must be a list');
      return value.map((item) => item.toString()).toList(growable: false);
    }

    final session = MunicipalSession(
      accessToken: requiredString('access_token'),
      operatorId: requiredString('operator_id'),
      organizationId: requiredString('organization_id'),
      phone: requiredString('phone'),
      role: requiredString('role').toUpperCase(),
      wardIds: stringList('ward_ids'),
      zoneIds: stringList('zone_ids'),
      valveIds: stringList('valve_ids'),
    );

    if (!session.isAdmin && !session.isLineOperator) {
      throw const FormatException('Unsupported municipal operator role');
    }
    return session;
  }

  Map<String, dynamic> toJson() => {
        'access_token': accessToken,
        'operator_id': operatorId,
        'organization_id': organizationId,
        'phone': phone,
        'role': role,
        'ward_ids': wardIds,
        'zone_ids': zoneIds,
        'valve_ids': valveIds,
      };
}

class MunicipalSessionStorage {
  static const _key = 'municipal_authenticated_session';

  static Future<void> save(MunicipalSession session) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(session.toJson()));
    // Keep the existing token key for current API clients during migration.
    await prefs.setString('municipal_access_token', session.accessToken);
    await prefs.setString('municipal_operator_id', session.operatorId);
  }

  static Future<MunicipalSession?> load() async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = prefs.getString(_key);
    if (encoded == null || encoded.isEmpty) return null;
    try {
      final decoded = jsonDecode(encoded);
      if (decoded is! Map) return null;
      return MunicipalSession.fromJson(Map<String, dynamic>.from(decoded));
    } on FormatException {
      return null;
    } on TypeError {
      return null;
    }
  }

  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
    await prefs.remove('municipal_access_token');
    await prefs.remove('municipal_operator_id');
  }
}
