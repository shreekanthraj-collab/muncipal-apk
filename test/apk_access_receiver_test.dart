import 'package:flutter_test/flutter_test.dart';

import '../../lib/services/apk_access_contract.dart';
import '../../lib/services/apk_access_receiver.dart';

void main() {
  test('receiver accepts a valid SCADA snapshot', () {
    final receiver = ApkAccessReceiver();

    final snapshot = ApkAccessSnapshot(
      grants: [
        const ApkAccessGrant(
          phone: '9876543210',
          zones: ['Zone 01', 'Zone 03'],
          enabled: true,
        ),
      ],
    );

    expect(receiver.ingest(snapshot.encode()), isNotNull);
    expect(receiver.grantForPhone('9876543210'), isNotNull);
    expect(
      receiver.canOperate(phone: '9876543210', zone: 'Zone 03'),
      isTrue,
    );
    expect(
      receiver.canOperate(phone: '9876543210', zone: 'Zone 02'),
      isFalse,
    );
  });

  test('receiver rejects malformed or unsupported snapshots', () {
    final receiver = ApkAccessReceiver();

    expect(receiver.ingest('not-json'), isNull);
    expect(receiver.ingest('{"schema":"wrong","grants":[]}'), isNull);
    expect(receiver.snapshot, isNull);
  });

  test('disabled grant cannot operate', () {
    final receiver = ApkAccessReceiver();

    final snapshot = ApkAccessSnapshot(
      grants: [
        const ApkAccessGrant(
          phone: '9876543210',
          zones: ['Zone 01'],
          enabled: false,
        ),
      ],
    );

    receiver.ingest(snapshot.encode());

    expect(
      receiver.canOperate(phone: '9876543210', zone: 'Zone 01'),
      isFalse,
    );
  });
}
