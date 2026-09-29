import 'package:flutter_test/flutter_test.dart';
import 'package:orb_valve_app/admin_app.dart';
import 'package:orb_valve_app/services/apk_access_contract.dart';
import 'package:orb_valve_app/services/apk_access_publisher.dart';

void main() {
  test('AdminStore builds a complete APK access snapshot', () {
    final store = AdminStore();
    store.addApkAccessGrant(
      phone: '9876543210',
      zones: ['Zone 01', 'Zone 03'],
    );

    final snapshot = store.apkAccessSnapshot;

    expect(snapshot.grants, hasLength(1));
    expect(snapshot.grants.first.phone, '9876543210');
    expect(snapshot.grants.first.zones, ['Zone 01', 'Zone 03']);
    expect(snapshot.grants.first.enabled, isTrue);
  });

  test('AdminStore replaces existing phone grant and can disable/remove it', () {
    final store = AdminStore();
    store.addApkAccessGrant(
      phone: '9876543210',
      zones: ['Zone 01'],
    );
    store.addApkAccessGrant(
      phone: '9876543210',
      zones: ['Zone 02', 'Zone 03'],
    );

    expect(store.apkAccessSnapshot.grants, hasLength(1));
    expect(store.apkAccessSnapshot.grants.first.zones, ['Zone 02', 'Zone 03']);

    store.setApkAccessEnabled('9876543210', false);
    expect(store.apkAccessSnapshot.grants.first.enabled, isFalse);

    store.removeApkAccessGrant('9876543210');
    expect(store.apkAccessSnapshot.grants, isEmpty);
  });

  test('publisher uses the frozen access topic and snapshot JSON', () async {
    String? publishedTopic;
    String? publishedPayload;

    final publisher = ApkAccessPublisher(
      publish: ({required String topic, required String payload}) async {
        publishedTopic = topic;
        publishedPayload = payload;
      },
    );

    const snapshot = ApkAccessSnapshot(
      grants: [
        ApkAccessGrant(
          phone: '9876543210',
          zones: ['Zone 01'],
          enabled: true,
        ),
      ],
    );

    await publisher.publishSnapshot(snapshot);

    expect(publishedTopic, apkAccessSnapshotTopic);
    expect(publishedPayload, snapshot.encode());
  });
}
