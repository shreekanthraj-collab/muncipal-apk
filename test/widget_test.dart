import 'package:flutter_test/flutter_test.dart';
import 'package:orb_valve_app/main.dart';

void main() {
  testWidgets('Admin valve app loads', (WidgetTester tester) async {
    await tester.pumpWidget(const OrbiValveApp());
    await tester.pumpAndSettle();

    expect(find.text('Smart Valve Management'), findsOneWidget);
    expect(find.text('Login'), findsOneWidget);

    await tester.tap(find.text('LOGIN'));
    await tester.pumpAndSettle();

    expect(find.text('ZONE / WARD'), findsOneWidget);
    expect(find.text('GSM / LTE VALVE VIEW'), findsOneWidget);
    expect(find.text('LoRa VALVE VIEW'), findsOneWidget);
    expect(find.text('MAP VIEW'), findsOneWidget);
    expect(find.text('RS485 VIEW'), findsOneWidget);
  });
}
