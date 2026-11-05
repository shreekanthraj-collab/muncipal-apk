import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:orb_valve_app/services/valve_position_storage.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('last target is persisted independently for each valve', () async {
    await ValvePositionStorage.save('LORA-001', 50);
    await ValvePositionStorage.save('GSM-002', 75);

    expect(await ValvePositionStorage.load('LORA-001'), 50);
    expect(await ValvePositionStorage.load('GSM-002'), 75);
    expect(await ValvePositionStorage.load('LORA-UNKNOWN'), isNull);
  });

  test('invalid saved target values are ignored', () async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('municipal_last_target_pct_LORA-001', 150);

    expect(await ValvePositionStorage.load('LORA-001'), isNull);
  });
}
