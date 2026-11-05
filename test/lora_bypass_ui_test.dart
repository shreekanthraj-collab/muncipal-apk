import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:orb_valve_app/screens/gsm_screen.dart';
import 'package:orb_valve_app/screens/lora_screen.dart';
import 'package:orb_valve_app/models/valve_data.dart';

void main() {
  test('bypass field distinguishes an explicit inactive state from missing data', () {
    final inactive = ValveData.fromJson({
      'valve_id': 'LORA-001',
      'low_voltage_bypass': false,
    });
    final missing = ValveData.fromJson({
      'valve_id': 'LORA-001',
    });

    expect(inactive.lowVoltageBypassKnown, isTrue);
    expect(inactive.lowVoltageBypass, isFalse);
    expect(missing.lowVoltageBypassKnown, isFalse);
  });

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('LoRa page shows bypass and actual position as read-only status',
      (tester) async {
    await tester.pumpWidget(const MaterialApp(home: LoraScreen()));
    await tester.pumpAndSettle();

    expect(find.text('LOW-VOLTAGE BYPASS'), findsOneWidget);
    expect(find.text('UNKNOWN'), findsNWidgets(2));
    expect(find.text('ACTUAL VALVE POSITION'), findsOneWidget);
    expect(find.textContaining('CLOSED'), findsNothing);
    expect(find.text('TEST LOW VOLTAGE'), findsNothing);
    expect(find.text('CANCEL BYPASS'), findsNothing);
  });

  testWidgets('GSM/LTE page retains its existing bypass controls',
      (tester) async {
    await tester.pumpWidget(const MaterialApp(home: GsmScreen()));
    await tester.pumpAndSettle();

    expect(find.text('SLEEP BYPASS / ACTIVE'), findsOneWidget);

    // The additive valve identity and telemetry rows make the list taller;
    // scroll the existing test card into the widget tree before asserting it.
    await tester.scrollUntilVisible(
      find.text('TEST LOW VOLTAGE'),
      400,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('TEST LOW VOLTAGE'), findsOneWidget);
    expect(find.text('CANCEL BYPASS'), findsOneWidget);
  });
}
