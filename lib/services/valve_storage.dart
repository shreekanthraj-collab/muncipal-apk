import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class ValveStorage {
  static const storageKey = 'municipal_map_valves_v2';

  static Future<Map<String, Map<String, String>>> loadValveDetails() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(storageKey);
    if (raw == null || raw.isEmpty) return const {};

    try {
      final decoded = jsonDecode(raw) as List<dynamic>;
      final details = <String, Map<String, String>>{};
      for (final item in decoded) {
        if (item is Map) {
          final id = item['id']?.toString().trim();
          if (id != null && id.isNotEmpty) {
            details[id] = {
              'zone': item['zone']?.toString() ?? '',
              'ward': item['ward']?.toString() ?? '',
            };
          }
        }
      }
      return details;
    } catch (_) {
      return const {};
    }
  }

  static Future<List<String>> loadValveIds() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(storageKey);
    if (raw == null || raw.isEmpty) return const [];

    try {
      final decoded = jsonDecode(raw) as List<dynamic>;
      final ids = <String>[];
      for (final item in decoded) {
        if (item is Map) {
          final id = item['id']?.toString().trim();
          if (id != null && id.isNotEmpty && !ids.contains(id)) {
            ids.add(id);
          }
        }
      }
      return ids;
    } catch (_) {
      return const [];
    }
  }
}
