enum TransportType {
  gsmLte,
  lora,
}

extension TransportTypeLabel on TransportType {
  String get label {
    switch (this) {
      case TransportType.gsmLte:
        return 'GSM / LTE';
      case TransportType.lora:
        return 'LoRa';
    }
  }

  bool get otaSupported => this == TransportType.gsmLte;
}
