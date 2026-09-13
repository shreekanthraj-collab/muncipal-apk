import 'dart:async';
import 'dart:convert';

import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';

import '../models/valve_command.dart';
import '../models/valve_data.dart';

class AwsService {
  final String host;
  final int port;
  final String clientId;
  final String valveId;

  late final MqttServerClient _client;

  final StreamController<ValveData> _statusController =
      StreamController<ValveData>.broadcast();

  StreamSubscription<List<MqttReceivedMessage<MqttMessage>>>? _updatesSubscription;
  Timer? _statusRequestTimeout;
  bool _connected = false;
  bool _statusSubscribed = false;

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
    _client.resubscribeOnAutoReconnect = false;

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
    _statusRequestTimeout?.cancel();
    _unsubscribeStatus();
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

  /// Request one fresh status snapshot.
  ///
  /// The status topic is subscribed only while this request is pending and is
  /// automatically unsubscribed after the first response or timeout. This
  /// keeps the normal app session from receiving continuous valve telemetry.
  Future<void> requestValveStatus() async {
    if (!_connected) {
      throw StateError('AWS/MQTT not connected');
    }

    _statusRequestTimeout?.cancel();

    if (!_statusSubscribed) {
      _client.subscribe(statusTopic, MqttQos.atLeastOnce);
      _statusSubscribed = true;
    }

    await sendCommand(
      ValveCommand(
        valveId: valveId,
        command: 'GET_STATUS',
        value: 0,
      ),
    );

    _statusRequestTimeout = Timer(const Duration(seconds: 5), () {
      _unsubscribeStatus();
    });
  }

  void _onConnected() {
    _connected = true;

    _updatesSubscription?.cancel();
    _updatesSubscription = _client.updates?.listen(_handleMessages);
  }

  void _onDisconnected() {
    _connected = false;
    _statusSubscribed = false;
    _statusRequestTimeout?.cancel();
  }

  void _onSubscribed(String topic) {
    // Subscription is intentionally short-lived and request-driven.
  }

  void _unsubscribeStatus() {
    _statusRequestTimeout?.cancel();
    _statusRequestTimeout = null;

    if (_statusSubscribed) {
      _client.unsubscribe(statusTopic);
      _statusSubscribed = false;
    }
  }

  void _handleMessages(List<MqttReceivedMessage<MqttMessage>> messages) {
    for (final message in messages) {
      if (message.topic != statusTopic) {
        continue;
      }

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
          _statusController.add(ValveData.fromJson(decoded));
          _unsubscribeStatus();
        }
      } catch (_) {
        // Ignore malformed status messages.
      }
    }
  }

  void dispose() {
    _statusRequestTimeout?.cancel();
    _updatesSubscription?.cancel();
    _unsubscribeStatus();
    _client.disconnect();
    _statusController.close();
  }
}
