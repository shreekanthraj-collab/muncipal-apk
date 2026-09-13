import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';

import '../models/valve_data.dart';
import '../models/valve_command.dart';
import '../services/aws_service.dart';
import '../widgets/valve_position_control.dart';
import '../widgets/command_json_card.dart';
import '../widgets/valve_status_card.dart';

class ValveDetailScreen extends StatefulWidget {
  const ValveDetailScreen({super.key});

  @override
  State<ValveDetailScreen> createState() => _ValveDetailScreenState();
}

class _ValveDetailScreenState extends State<ValveDetailScreen> {
  int selectedPosition = 0;
  bool statusRequested = false;
  bool statusRequestInProgress = false;

  ValveData valveData = const ValveData(
    valveId: 'ORBI-001',
    status: 'STOPPED',
    requested: 0,
    actual: 0,
    connected: false,
  );

  int requestedPosition = 0;
  int actualPosition = 0;
  String status = 'STOPPED';
  Timer? movementTimer;
  String lastCommandJson = '';

  late final AwsService awsService;
  StreamSubscription<ValveData>? statusSubscription;

  void selectPosition(int value) {
    setState(() => selectedPosition = value);
  }

  Future<bool> _ensureConnected() async {
    if (awsService.connected) {
      return true;
    }

    try {
      await awsService.connect();
      return awsService.connected;
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('MQTT connection failed: $error')),
        );
      }
      return false;
    }
  }

  Future<void> setValve() async {
    final command = ValveCommand(
      valveId: valveData.valveId,
      command: 'SET_POSITION',
      value: selectedPosition,
    );

    setState(() {
      lastCommandJson = const JsonEncoder.withIndent('  ').convert(command.toJson());
    });

    if (!await _ensureConnected()) {
      return;
    }

    try {
      await awsService.sendCommand(command);
    } catch (error) {
      debugPrint('MQTT SET_POSITION failed: $error');
    }

    movementTimer?.cancel();
    setState(() {
      requestedPosition = selectedPosition;
      if (actualPosition < requestedPosition) {
        status = 'OPENING';
      } else if (actualPosition > requestedPosition) {
        status = 'CLOSING';
      } else {
        status = 'STOPPED';
      }
    });

    if (actualPosition == requestedPosition) return;

    movementTimer = Timer.periodic(const Duration(milliseconds: 50), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        if (actualPosition < requestedPosition) {
          actualPosition++;
        } else if (actualPosition > requestedPosition) {
          actualPosition--;
        }
        if (actualPosition == requestedPosition) {
          status = 'STOPPED';
          timer.cancel();
        }
      });
    });
  }

  Future<void> stopValve() async {
    movementTimer?.cancel();
    movementTimer = null;

    final command = ValveCommand(
      valveId: valveData.valveId,
      command: 'STOP',
      value: 0,
    );

    setState(() {
      status = 'STOPPED';
      lastCommandJson = const JsonEncoder.withIndent('  ').convert(command.toJson());
    });

    if (!await _ensureConnected()) {
      return;
    }

    try {
      await awsService.sendCommand(command);
    } catch (error) {
      debugPrint('MQTT STOP failed: $error');
    }
  }

  Future<void> getValveStatus() async {
    if (statusRequestInProgress) {
      return;
    }

    setState(() {
      statusRequested = true;
      statusRequestInProgress = true;
    });

    if (!await _ensureConnected()) {
      if (mounted) {
        setState(() => statusRequestInProgress = false);
      }
      return;
    }

    try {
      await awsService.requestValveStatus();
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('GET STATUS failed: $error')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => statusRequestInProgress = false);
      }
    }
  }

  Color statusColor() {
    switch (status) {
      case 'OPENING':
        return Colors.blue;
      case 'CLOSING':
        return Colors.orange;
      default:
        return Colors.green;
    }
  }

  @override
  void initState() {
    super.initState();

    awsService = AwsService(
      host: 'YOUR_AWS_IOT_ENDPOINT',
      clientId: 'ORBI-APP',
      valveId: valveData.valveId,
    );

    statusSubscription = awsService.valveStatusStream.listen((data) {
      if (!mounted) return;

      setState(() {
        valveData = data;
        status = data.status;
        requestedPosition = data.requested;
        actualPosition = data.actual;
      });
    });
  }

  @override
  void dispose() {
    movementTimer?.cancel();
    statusSubscription?.cancel();
    awsService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ORBI Valve', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: statusRequestInProgress ? null : getValveStatus,
                icon: statusRequestInProgress
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.refresh),
                label: const Text('GET VALVE STATUS'),
              ),
            ),
            const SizedBox(height: 16),
            if (statusRequested) ...[
              ValveStatusCard(
                status: status,
                requestedPosition: requestedPosition,
                actualPosition: actualPosition,
                statusColor: statusColor(),
                rssi: valveData.rssi,
              ),
              const SizedBox(height: 25),
            ],
            ValvePositionControl(
              selectedPosition: selectedPosition,
              selectPosition: selectPosition,
              setValve: setValve,
              stopValve: stopValve,
            ),
            const SizedBox(height: 20),
            if (lastCommandJson.isNotEmpty)
              CommandJsonCard(commandJson: lastCommandJson),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.circle,
                  size: 10,
                  color: valveData.connected ? Colors.green : Colors.grey,
                ),
                const SizedBox(width: 8),
                Text(
                  valveData.connected ? 'Controller connected' : 'Controller not connected',
                  style: const TextStyle(color: Colors.grey),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
