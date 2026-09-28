import 'apk_access_contract.dart';

class ApkAccessReceiver {
  ApkAccessSnapshot? _snapshot;

  ApkAccessSnapshot? get snapshot => _snapshot;

  ApkAccessSnapshot? ingest(String payload) {
    try {
      final decoded = ApkAccessSnapshot.decode(payload);
      _snapshot = decoded;
      return decoded;
    } on FormatException {
      return null;
    } on Object {
      return null;
    }
  }

  ApkAccessGrant? grantForPhone(String phone) {
    final normalized = phone.trim();
    final current = _snapshot;
    if (current == null) return null;

    for (final grant in current.grants) {
      if (grant.phone.trim() == normalized) return grant;
    }
    return null;
  }

  bool canOperate({
    required String phone,
    required String zone,
  }) {
    final grant = grantForPhone(phone);
    if (grant == null || !grant.enabled) return false;

    final requestedZone = zone.trim().toLowerCase();
    if (requestedZone.isEmpty) return false;

    return grant.zones.any(
      (allowed) => allowed.trim().toLowerCase() == requestedZone,
    );
  }
}
