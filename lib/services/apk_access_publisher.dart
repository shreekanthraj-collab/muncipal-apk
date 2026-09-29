import 'apk_access_contract.dart';

typedef ApkAccessPublish = Future<void> Function({
  required String topic,
  required String payload,
});

class ApkAccessPublisher {
  final ApkAccessPublish publish;

  const ApkAccessPublisher({required this.publish});

  Future<void> publishSnapshot(ApkAccessSnapshot snapshot) {
    return publish(
      topic: apkAccessSnapshotTopic,
      payload: snapshot.encode(),
    );
  }

  Future<void> publishStoreSnapshot(ApkAccessSnapshot Function() snapshot) {
    return publishSnapshot(snapshot());
  }
}
