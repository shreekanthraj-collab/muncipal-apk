import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:orb_valve_app/screens/login_screen.dart';

void main() {
  testWidgets('municipal login does not allow client-selected roles', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: LoginScreen()),
    );

    expect(find.text('Registered mobile number'), findsOneWidget);
    expect(find.text('REQUEST OTP'), findsOneWidget);
    expect(find.text('Admin'), findsNothing);
    expect(find.text('Agent / Operator'), findsNothing);
    expect(find.text('Select your role to continue'), findsNothing);
    expect(find.text('LOGIN'), findsNothing);
  });
}
