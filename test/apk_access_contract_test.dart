import 'package:flutter_test/flutter_test.dart';
import 'package:orb_valve_app/services/apk_access_contract.dart';

void main() {
  test('APK access snapshot round-trips through JSON', () {
    const snapshot = ApkAccessSnapshot(
      grants: [
        ApkAccessGrant(
          phone: '9876543210',
          zones: ['Zone 01', 'Zone 03'],
          enabled: true,
        ),
      ],
    );

    final decoded = ApkAccessSnapshot.decode(snapshot.encode());

    expect(decoded.grants, hasLength(1));
    expect(decoded.grants.first.phone, '9876543210');
    expect(decoded.grants.first.zones, ['Zone 01', 'Zone 03']);
    expect(decoded.grants.first.enabled, isTrue);
  });

  test('unsupported schema is rejected', () {
    expect(
      () => ApkAccessSnapshot.decode(
        '{"schema":"orb.apk-access.v0","grants":[]}',
      ),
      throwsA(isA<FormatException>()),
    );
  });
}
