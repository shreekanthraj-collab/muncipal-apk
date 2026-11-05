import 'package:flutter_test/flutter_test.dart';
import 'package:orb_valve_app/main.dart';

void main() {
  testWidgets('Admin valve app loads and opens zone/ward home',
      (WidgetTester tester) async {
    await tester.pumpWidget(const OrbiValveApp());
    await tester.pumpAndSettle();

    expect(find.text('Smart Valve Management'), findsOneWidget);
    expect(find.text('Login'), findsOneWidget);
    expect(find.text('REQUEST OTP'), findsOneWidget);

    // The current login screen defaults to Agent / Operator (OTP flow).
    // Select the Admin role to exercise the existing password-login route.
    await tester.tap(find.text('Admin'));
    await tester.pumpAndSettle();
    expect(find.text('LOGIN'), findsOneWidget);

    await tester.tap(find.text('LOGIN'));
    await tester.pumpAndSettle();

    expect(find.text('ZONE / WARD'), findsOneWidget);
    expect(find.text('GSM / LTE VALVE VIEW'), findsOneWidget);
    expect(find.text('LoRa VALVE VIEW'), findsOneWidget);
    expect(find.text('MAP VIEW'), findsOneWidget);
    expect(find.text('RS485 VIEW'), findsOneWidget);
  });
}
