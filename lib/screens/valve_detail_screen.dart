import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';

import '../models/valve_data.dart';
import '../models/valve_command.dart';
import '../services/aws_service.dart';
import '../widgets/valve_position_control.dart';
import '../widgets/command_json_card.dart';
import '../widgets/valve_status_card.dart';
import '../widgets/valve_schedule_card.dart';

class ValveDetailScreen extends StatefulWidget {
  final String transport;
  final String valveId;

  const ValveDetailScreen({
    super.key,
    required this.transport,
    required this.valveId,
  });

  @override
  State<ValveDetailScreen> createState() => _ValveDetailScreenState();
}

class _ValveDetailScreenState extends State<ValveDetailScreen> {
  int selectedPosition = 0;
  late ValveData valveData;
  int requestedPosition = 0;
  int actualPosition = 0;
  String status = 'STOPPED';
  Timer? movementTimer;
  String lastCommandJson = '';

  bool scheduleEnabled = false;
  TimeOfDay? scheduleTime;
  int schedulePosition = 0;

  late final AwsService awsService;
  StreamSubscription<ValveData>? statusSubscription;

  void selectPosition(int value) {
    setState(() => selectedPosition = value);
  }

  Future<void> setValve() async {
    final command = ValveCommand(
      valveId: valveData.valveId,
      command: 'SET_POSITION',
      value: selectedPosition,
    );

    setState(() {
      lastCommandJson = const JsonEncoder.withIndent('  ').convert(command.toJson());
      requestedPosition = selectedPosition;
      status = actualPosition < requestedPosition
          ? 'OPENING'
          : actualPosition > requestedPosition
              ? 'CLOSING'
              : 'STOPPED';
    });

    if (awsService.connected) {
      try {
        await awsService.sendCommand(command);
      } catch (error) {
        debugPrint('MQTT SET_POSITION failed: $error');
      }
    }

    movementTimer?.cancel();
    if (actualPosition == requestedPosition) return;

    movementTimer = Timer.periodic(const Duration(milliseconds: 50), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        if (actualPosition < requestedPosition) actualPosition++;
        if (actualPosition > requestedPosition) actualPosition--;
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

    if (awsService.connected) {
      try {
        await awsService.sendCommand(command);
      } catch (error) {
        debugPrint('MQTT STOP failed: $error');
      }
    }
  }

  Color statusColor() {
    switch (status) {
      case 'OPENING': return Colors.blue;
      case 'CLOSING': return Colors.orange;
      default: return Colors.green;
    }
  }

  Future<void> editSchedule() async {
    final pickedTime = await showTimePicker(
      context: context,
      initialTime: scheduleTime ?? TimeOfDay.now(),
    );
    if (!mounted || pickedTime == null) return;

    setState(() {
      scheduleTime = pickedTime;
      schedulePosition = selectedPosition;
      scheduleEnabled = true;
    });
  }

  @override
  void initState() {
    super.initState();
    valveData = ValveData(
      valveId: widget.valveId,
      status: 'STOPPED',
      requested: 0,
      actual: 0,
      connected: false,
    );

    awsService = AwsService(
      host: 'YOUR_AWS_IOT_ENDPOINT',
      clientId: 'ORBI-APP',
      valveId: widget.valveId,
    );

    statusSubscription = awsService.valveStatusStream.listen((data) {
      if (!mounted) return;
      setState(() {
        valveData = data;
        status = data.status;
        requestedPosition = data.requested;
        actualPosition = data.actual;
        selectedPosition = data.requested;
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
        title: Text('ORBI Valve  ${widget.transport}', style: const TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Text(widget.valveId, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 15),
            ValveStatusCard(
              status: status,
              requestedPosition: requestedPosition,
              actualPosition: actualPosition,
              statusColor: statusColor(),
              connected: valveData.connected,
              rssi: valveData.rssi,
              firmwareVersion: valveData.firmwareVersion,
              batteryVoltage: valveData.batteryVoltage,
              batteryLowBypass: valveData.batteryLowBypass,
              overCurrent: valveData.overCurrent,
              overCurrentThresholdA: valveData.overCurrentThresholdA,
            ),
            const SizedBox(height: 20),
            ValvePositionControl(
              selectedPosition: selectedPosition,
              selectPosition: selectPosition,
              setValve: setValve,
              stopValve: stopValve,
            ),
            const SizedBox(height: 20),
            ValveScheduleCard(
              enabled: scheduleEnabled,
              time: scheduleTime,
              position: schedulePosition,
              onPressed: editSchedule,
              onEnabledChanged: (value) => setState(() => scheduleEnabled = value),
            ),
            const SizedBox(height: 20),
            if (lastCommandJson.isNotEmpty) CommandJsonCard(commandJson: lastCommandJson),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.circle, size: 10, color: valveData.connected ? Colors.green : Colors.grey),
                const SizedBox(width: 8),
                Text(valveData.connected ? 'Controller connected' : 'Controller not connected', style: const TextStyle(color: Colors.grey)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
