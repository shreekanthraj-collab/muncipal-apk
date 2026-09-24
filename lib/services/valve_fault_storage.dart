import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ValveFaultStorage {
  static const _prefix = 'oc_fault_';

  // Map screen listens to this so pin colors update immediately.
  static final ValueNotifier<int> changes = ValueNotifier<int>(0);

  static Future<void> save(String valveId, bool ocFault) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('$_prefix$valveId', ocFault);
    changes.value++;
  }

  static Future<bool> load(String valveId) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('$_prefix$valveId') ?? false;
  }
}
