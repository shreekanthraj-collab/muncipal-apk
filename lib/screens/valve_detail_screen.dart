import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';

import '../models/gateway_command_codes.dart';
import '../models/transport_type.dart';
import '../models/valve_command.dart';
import '../models/valve_data.dart';
import '../services/aws_service.dart';
import '../widgets/command_json_card.dart';
import '../widgets/valve_position_control.dart';
import '../widgets/valve_status_card.dart';

class ValveDetailScreen extends StatefulWidget {
  final TransportType? transport;

  const ValveDetailScreen({super.key, this.transport});

  @override
  State<ValveDetailScreen> createState() => _ValveDetailScreenState();
}

class _ValveDetailScreenState extends State<ValveDetailScreen> {
  int selectedPosition = 0;
  int requestedPosition = 0;
  int actualPosition = 0;
  String status = 'STOPPED';
  String lastCommandJson = '';
  Timer? movementTimer;
  String otaStatus = 'Not checked';

  late final AwsService awsService;
  StreamSubscription<ValveData>? statusSubscription;

  ValveData valveData = const ValveData(
    valveId: 'ORBI-001',
    status: 'STOPPED',
    requested: 0,
    actual: 0,
    connected: false,
  );

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

  void selectPosition(int value) => setState(() => selectedPosition = value);

  Future<void> _sendCommand(String command, [int value = 0]) async {
    final request = ValveCommand(
      valveId: valveData.valveId,
      command: command,
      value: value,
    );
    setState(() {
      lastCommandJson = const JsonEncoder.withIndent('  ')
          .convert(request.toJson());
    });
    if (!awsService.connected) return;
    try {
      await awsService.sendCommand(request);
    } catch (error) {
      debugPrint('MQTT $command failed: $error');
    }
  }

  Future<void> setValve() async {
    await _sendCommand(GatewayCommandNames.setPosition, selectedPosition);
    movementTimer?.cancel();
    setState(() {
      requestedPosition = selectedPosition;
      status = actualPosition < requestedPosition
          ? 'OPENING'
          : actualPosition > requestedPosition
              ? 'CLOSING'
              : 'STOPPED';
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
    await _sendCommand(GatewayCommandNames.stop);
    if (mounted) setState(() => status = 'STOPPED');
  }

  Future<void> _requestStatus() async {
    await _sendCommand(GatewayCommandNames.getStatus);
  }

  Future<void> _numberCommand(String command, String title, int initial) async {
    final controller = TextEditingController(text: '$initial');
    final value = await showDialog<int>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(border: OutlineInputBorder()),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CANCEL'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(
              context,
              int.tryParse(controller.text),
            ),
            child: const Text('SEND'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (value != null) await _sendCommand(command, value);
  }

  Future<void> _scheduleDialog() async {
    int slot = 1;
    int hour = 8;
    int minute = 0;
    int action = 1;
    await showDialog<void>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('SET SCHEDULE'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<int>(
                initialValue: slot,
                decoration: const InputDecoration(labelText: 'Slot'),
                items: List.generate(
                  8,
                  (i) => DropdownMenuItem(
                    value: i + 1,
                    child: Text('Slot ${i + 1}'),
                  ),
                ),
                onChanged: (v) => setDialogState(() => slot = v ?? 1),
              ),
              TextField(
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Hour (0-23)'),
                onChanged: (v) => hour = int.tryParse(v) ?? hour,
              ),
              TextField(
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Minute (0-59)'),
                onChanged: (v) => minute = int.tryParse(v) ?? minute,
              ),
              DropdownButtonFormField<int>(
                initialValue: action,
                decoration: const InputDecoration(labelText: 'Action'),
                items: const [
                  DropdownMenuItem(value: 1, child: Text('OPEN')),
                  DropdownMenuItem(value: 2, child: Text('CLOSE')),
                ],
                onChanged: (v) => setDialogState(() => action = v ?? 1),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('CANCEL'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                final packed = ((slot & 0x0F) << 12) |
                    ((action & 0x03) << 10) |
                    ((hour & 0x1F) << 5) |
                    (minute & 0x1F);
                _sendCommand(GatewayCommandNames.setSchedule, packed);
              },
              child: const Text('SAVE'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _checkForOtaUpdate() async {
    setState(() => otaStatus = 'Update check requested');
    await _sendCommand('OTA_CHECK');
  }

  Future<void> _otaUpdate() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('OTA UPDATE'),
        content: const Text('Start firmware update for this GSM/LTE valve?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('CANCEL'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('UPDATE'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      setState(() => otaStatus = 'OTA update requested');
      await _sendCommand('OTA_UPDATE');
    }
  }

  Widget _actionButton({
    required String label,
    required IconData icon,
    required VoidCallback onPressed,
    bool primary = false,
  }) {
    final child = Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon),
        const SizedBox(width: 8),
        Text(label),
      ],
    );
    return SizedBox(
      height: 50,
      child: primary
          ? ElevatedButton(onPressed: onPressed, child: child)
          : OutlinedButton(onPressed: onPressed, child: child),
    );
  }

  Widget _section(String title, List<Widget> buttons) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            ...buttons
                .expand((button) => [button, const SizedBox(height: 8)])
                .toList()
              ..removeLast(),
          ],
        ),
      ),
    );
  }

  Color statusColor() {
    switch (status) {
      case 'OPENING':
        return Colors.blue;
      case 'CLOSING':
        return Colors.orange;
      case 'FAULT':
        return Colors.red;
      default:
        return Colors.green;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isGsm = widget.transport == TransportType.gsmLte;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.transport == null
              ? 'ORBI Valve'
              : '${widget.transport!.label} Valve',
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ValveStatusCard(
              status: status,
              requestedPosition: requestedPosition,
              actualPosition: actualPosition,
              statusColor: statusColor(),
              onRequestStatus: _requestStatus,
            ),
            const SizedBox(height: 16),
            ValvePositionControl(
              selectedPosition: selectedPosition,
              selectPosition: selectPosition,
              setValve: setValve,
              stopValve: stopValve,
            ),
            const SizedBox(height: 16),
            _section('VALVE CONTROL', [
              _actionButton(
                label: 'OPEN VALVE',
                icon: Icons.keyboard_arrow_up,
                onPressed: () => _sendCommand(GatewayCommandNames.open),
                primary: true,
              ),
              _actionButton(
                label: 'CLOSE VALVE',
                icon: Icons.keyboard_arrow_down,
                onPressed: () => _sendCommand(GatewayCommandNames.close),
              ),
              _actionButton(
                label: 'STOP VALVE',
                icon: Icons.stop_circle,
                onPressed: stopValve,
              ),
              _actionButton(
                label: 'GET STATUS',
                icon: Icons.refresh,
                onPressed: _requestStatus,
              ),
              _actionButton(
                label: 'CLEAR FAULT',
                icon: Icons.restart_alt,
                onPressed: () => _sendCommand(GatewayCommandNames.clearFault),
              ),
            ]),
            const SizedBox(height: 12),
            _section('VALVE SETTINGS', [
              _actionButton(
                label: 'SET TURNS',
                icon: Icons.rotate_right,
                onPressed: () => _numberCommand(
                  GatewayCommandNames.setTurns,
                  'SET TURNS',
                  0,
                ),
              ),
              _actionButton(
                label: 'SET CURRENT',
                icon: Icons.electric_bolt,
                onPressed: () => _numberCommand(
                  GatewayCommandNames.setCurrent,
                  'SET CURRENT',
                  0,
                ),
              ),
              _actionButton(
                label: 'SET DISENGAGE CURRENT',
                icon: Icons.power_settings_new,
                onPressed: () => _numberCommand(
                  GatewayCommandNames.setDisengageCurrent,
                  'SET DISENGAGE CURRENT',
                  0,
                ),
              ),
              _actionButton(
                label: 'SET CHANNEL',
                icon: Icons.settings_input_antenna,
                onPressed: () => _numberCommand(
                  GatewayCommandNames.setChannel,
                  'SET CHANNEL',
                  0,
                ),
              ),
            ]),
            const SizedBox(height: 12),
            _section('CALIBRATION', [
              _actionButton(
                label: 'START CALIBRATION',
                icon: Icons.settings,
                onPressed: () => _sendCommand(GatewayCommandNames.calibrate),
              ),
              _actionButton(
                label: 'CALIBRATION SET',
                icon: Icons.check_circle_outline,
                onPressed: () =>
                    _sendCommand(GatewayCommandNames.calibrationSet),
              ),
              _actionButton(
                label: 'CALIBRATION ABORT',
                icon: Icons.cancel_outlined,
                onPressed: () =>
                    _sendCommand(GatewayCommandNames.calibrationAbort),
              ),
            ]),
            const SizedBox(height: 12),
            _section('SCHEDULE', [
              _actionButton(
                label: 'SET SCHEDULE',
                icon: Icons.schedule,
                onPressed: _scheduleDialog,
              ),
              _actionButton(
                label: 'CLEAR SCHEDULE',
                icon: Icons.event_busy,
                onPressed: () =>
                    _sendCommand(GatewayCommandNames.clearSchedule),
              ),
              _actionButton(
                label: 'GET SCHEDULE',
                icon: Icons.event_note,
                onPressed: () =>
                    _sendCommand(GatewayCommandNames.getSchedule),
              ),
            ]),
            const SizedBox(height: 12),
            _section('POWER / TIME', [
              _actionButton(
                label: 'VOLTAGE BYPASS',
                icon: Icons.battery_alert,
                onPressed: () =>
                    _sendCommand(GatewayCommandNames.voltageBypass),
              ),
              _actionButton(
                label: 'VOLTAGE CANCEL',
                icon: Icons.battery_full,
                onPressed: () =>
                    _sendCommand(GatewayCommandNames.voltageCancel),
              ),
              _actionButton(
                label: 'SET TIME',
                icon: Icons.access_time,
                onPressed: () => _numberCommand(
                  GatewayCommandNames.setTime,
                  'SET TIME (UNIX)',
                  DateTime.now().millisecondsSinceEpoch ~/ 1000,
                ),
              ),
            ]),
            const SizedBox(height: 12),
            _section('GATEWAY / OWNERSHIP', [
              _actionButton(
                label: 'REBIND OWNER',
                icon: Icons.link,
                onPressed: () => _numberCommand(
                  GatewayCommandNames.rebindOwner,
                  'NEW GATEWAY ID',
                  0,
                ),
              ),
            ]),
            if (isGsm) ...[
              const SizedBox(height: 12),
              _section('FIRMWARE / OTA', [
                _actionButton(
                  label: 'CHECK FOR UPDATE',
                  icon: Icons.system_update_alt,
                  onPressed: _checkForOtaUpdate,
                ),
                _actionButton(
                  label: 'OTA UPDATE',
                  icon: Icons.download,
                  onPressed: _otaUpdate,
                  primary: true,
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text(
                    otaStatus,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 13),
                  ),
                ),
              ]),
            ],
            const SizedBox(height: 16),
            if (lastCommandJson.isNotEmpty)
              CommandJsonCard(commandJson: lastCommandJson),
            const SizedBox(height: 16),
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
                  valveData.connected
                      ? 'Controller connected'
                      : 'Controller not connected',
                  style: TextStyle(
                    color: valveData.connected ? Colors.green : Colors.grey,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
