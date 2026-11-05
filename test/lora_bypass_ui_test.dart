import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:orb_valve_app/screens/gsm_screen.dart';
import 'package:orb_valve_app/screens/lora_screen.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('LoRa page shows bypass and actual position as read-only status',
      (tester) async {
    await tester.pumpWidget(const MaterialApp(home: LoraScreen()));
    await tester.pumpAndSettle();

    expect(find.text('LOW-VOLTAGE BYPASS'), findsOneWidget);
    expect(find.text('INACTIVE'), findsOneWidget);
    expect(find.text('ACTUAL VALVE POSITION'), findsOneWidget);
    expect(find.textContaining('CLOSED'), findsOneWidget);
    expect(find.text('TEST LOW VOLTAGE'), findsNothing);
    expect(find.text('CANCEL BYPASS'), findsNothing);
  });

  testWidgets('GSM/LTE page retains its existing bypass controls',
      (tester) async {
    await tester.pumpWidget(const MaterialApp(home: GsmScreen()));
    await tester.pumpAndSettle();

    expect(find.text('SLEEP BYPASS / ACTIVE'), findsOneWidget);
    expect(find.text('TEST LOW VOLTAGE'), findsOneWidget);
    expect(find.text('CANCEL BYPASS'), findsOneWidget);
  });
}
