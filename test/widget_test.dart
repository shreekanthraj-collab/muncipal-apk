import 'package:flutter_test/flutter_test.dart';
import 'package:orb_valve_app/main.dart';

void main() {
  testWidgets('Municipal app shows server-verified OTP login',
      (WidgetTester tester) async {
    await tester.pumpWidget(const OrbiValveApp());
    await tester.pumpAndSettle();

    expect(find.text('Smart Valve Management'), findsOneWidget);
    expect(find.text('Municipal Login'), findsOneWidget);
    expect(find.text('REQUEST OTP'), findsOneWidget);
    expect(find.text('Server Authentication'), findsOneWidget);

    // Role selection and password login were intentionally removed.
    expect(find.text('Admin'), findsNothing);
    expect(find.text('Agent / Operator'), findsNothing);
    expect(find.text('LOGIN'), findsNothing);
  });
}
