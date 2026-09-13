import 'package:flutter_test/flutter_test.dart';

import 'package:orb_valve_app/main.dart';

void main() {
  testWidgets('ORB Valve app starts', (WidgetTester tester) async {
    await tester.pumpWidget(const OrbiValveApp());

    expect(find.byType(OrbiValveApp), findsOneWidget);
  });
}
