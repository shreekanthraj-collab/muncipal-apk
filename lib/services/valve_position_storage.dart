import 'package:shared_preferences/shared_preferences.dart';

/// Stores each valve's last successfully sent target locally on this phone.
/// This is an operator setpoint, not measured valve position or firmware NVS.
class ValvePositionStorage {
  static String _key(String valveId) => 'municipal_last_target_pct_${Uri.encodeComponent(valveId)}';

  static Future<int?> load(String valveId) async {
    final prefs = await SharedPreferences.getInstance();
    final value = prefs.getInt(_key(valveId));
    if (value == null || value < 0 || value > 100) return null;
    return value;
  }

  static Future<void> save(String valveId, int position) async {
    if (valveId.trim().isEmpty || position < 0 || position > 100) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_key(valveId), position);
  }
}
