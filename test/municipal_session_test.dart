import 'package:flutter_test/flutter_test.dart';
import 'package:orb_valve_app/services/municipal_session.dart';

void main() {
  Map<String, dynamic> payload({String role = 'ZONE_USER'}) => {
        'access_token': 'token',
        'operator_id': 'operator-1',
        'organization_id': 'org-1',
        'phone': '9876543210',
        'role': role,
        'ward_ids': ['ward-1'],
        'zone_ids': ['zone-2'],
        'valve_ids': ['valve-3'],
      };

  test('session parses server-authoritative operator claims', () {
    final session = MunicipalSession.fromJson(payload());
    expect(session.isLineOperator, isTrue);
    expect(session.isAdmin, isFalse);
    expect(session.zoneIds, ['zone-2']);
    expect(session.valveIds, ['valve-3']);
  });

  test('admin role is determined from server response', () {
    final session = MunicipalSession.fromJson(payload(role: 'SCADA_ADMIN'));
    expect(session.isAdmin, isTrue);
    expect(session.isLineOperator, isFalse);
  });

  test('unknown role is rejected closed', () {
    expect(
      () => MunicipalSession.fromJson(payload(role: 'UNKNOWN')),
      throwsA(isA<FormatException>()),
    );
  });

  test('required session identity fields cannot be empty', () {
    final invalid = payload()..['operator_id'] = '';
    expect(
      () => MunicipalSession.fromJson(invalid),
      throwsA(isA<FormatException>()),
    );
  });
}
