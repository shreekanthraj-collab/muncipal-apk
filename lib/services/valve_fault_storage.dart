import 'package:shared_preferences/shared_preferences.dart';

class ValveFaultStorage {
  static const _prefix = 'oc_fault_';

  static Future<void> save(String valveId, bool ocFault) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('$_prefix$valveId', ocFault);
  }

  static Future<bool> load(String valveId) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('$_prefix$valveId') ?? false;
  }
}
