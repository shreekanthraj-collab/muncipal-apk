import 'dart:async';
import 'dart:convert';

import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';

import '../valve_command.dart';
import '../valve_data.dart';

class AwsService {
  final String host;
  final int port;
  final String clientId;
  final String valveId;

  late final MqttServerClient _client;

  final StreamController<ValveData> _statusController =
      StreamController<ValveData>.broadcast();

  bool _connected = false;

  AwsService({
    required this.host,
    required this.clientId,
    required this.valveId,
    this.port = 8883,
  }) {
    _client = MqttServerClient(host, clientId);
    _client.port = port;
    _client.keepAlivePeriod = 30;
    _client.logging(on: false);
    _client.autoReconnect = true;
    _client.resubscribeOnAutoReconnect = true;

    _client.onConnected = _onConnected;
    _client.onDisconnected = _onDisconnected;
    _client.onSubscribed = _onSubscribed;
  }

  bool get connected => _connected;

  Stream<ValveData> get valveStatusStream => _statusController.stream;

  String get statusTopic => 'orb/node/$valveId/status';

  String get commandTopic => 'orb/node/$valveId/cmd';

  Future<void> connect() async {
    if (_connected) {
      return;
    }

    try {
      await _client.connect();
    } catch (_) {
      _client.disconnect();
      rethrow;
    }
  }

  Future<void> disconnect() async {
    _client.disconnect();
  }

  Future<void> sendCommand(ValveCommand command) async {
    if (!_connected) {
      throw StateError('AWS/MQTT not connected');
    }

    final builder = MqttClientPayloadBuilder();
    builder.addString(jsonEncode(command.toJson()));

    _client.publishMessage(
      'orb/node/${command.valveId}/cmd',
      MqttQos.atLeastOnce,
      builder.payload!,
    );
  }

  void _onConnected() {
    _connected = true;

    _client.subscribe(
      statusTopic,
      MqttQos.atLeastOnce,
    );

    _client.updates?.listen(_handleMessages);
  }

  void _onDisconnected() {
    _connected = false;
  }

  void _onSubscribed(String topic) {
    // Subscription confirmed by the MQTT broker.
  }

  void _handleMessages(List<MqttReceivedMessage<MqttMessage>> messages) {
    for (final message in messages) {
      final payload = message.payload;

      if (payload is! MqttPublishMessage) {
        continue;
      }

      final raw = MqttPublishPayload.bytesToStringAsString(
        payload.payload.message,
      );

      try {
        final decoded = jsonDecode(raw);

        if (decoded is Map<String, dynamic>) {
          _statusController.add(
            ValveData.fromJson(decoded),
          );
        }
      } catch (_) {
        // Ignore malformed status messages.
      }
    }
  }

  void dispose() {
    _client.disconnect();
    _statusController.close();
  }
}
