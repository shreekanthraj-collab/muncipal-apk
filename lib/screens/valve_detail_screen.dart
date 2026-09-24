import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';

import '../models/valve_data.dart';
import '../models/valve_command.dart';
import '../services/aws_service.dart';

class ValveDetailScreen extends StatefulWidget {
  const ValveDetailScreen({super.key});

  @override
  State<ValveDetailScreen> createState() => _ValveDetailScreenState();
}

class _ValveDetailScreenState extends State<ValveDetailScreen> {
  final List<String> valveIds = const ['ORBI-001'];
  String selectedValveId = 'ORBI-001';

  int selectedPosition = 0;
  int requestedPosition = 0;
  int actualPosition = 0;
  String status = 'STOPPED';
  String lastCommandJson = '';
  String calibrationState = 'IDLE';

  double voltageThreshold = 11.50;
  double ocTrip = 5.0;
  double ocReset = 6.0;
  bool voltageBypass = false;

  Timer? movementTimer;
  late final AwsService awsService;
  StreamSubscription<ValveData>? statusSubscription;

  ValveData valveData = const ValveData(
    valveId: 'ORBI-001',
    status: 'STOPPED',
    requested: 0,
    actual: 0,
    connected: false,
    communicationId: '',
    ocFault: false,
    lowVoltageBypass: false,
    gwid: '',
  );

  void selectPosition(int value) {
    setState(() => selectedPosition = value);
  }

  Future<void> _sendCommand(String command, {int value = 0}) async {
    final packet = ValveCommand(
      valveId: selectedValveId,
      command: command,
      value: value,
    );

    setState(() {
      lastCommandJson = const JsonEncoder.withIndent('  ').convert(packet.toJson());
    });

    if (!awsService.connected) return;

    try {
      await awsService.sendCommand(packet);
    } catch (error) {
      debugPrint('$command failed: $error');
    }
  }

  Future<void> setValve() async {
    await _sendCommand('SET_POSITION', value: selectedPosition);

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

  Future<void> openValve() async {
    movementTimer?.cancel();
    await _sendCommand('OPEN');
    setState(() => status = 'OPENING');
  }

  Future<void> closeValve() async {
    movementTimer?.cancel();
    await _sendCommand('CLOSE');
    setState(() => status = 'CLOSING');
  }

  Future<void> stopValve() async {
    movementTimer?.cancel();
    movementTimer = null;
    await _sendCommand('STOP');
    if (mounted) setState(() => status = 'STOPPED');
  }

  Future<void> emergencyStop() async {
    movementTimer?.cancel();
    movementTimer = null;
    await _sendCommand('ESTOP');
    if (mounted) setState(() => status = 'E-STOP');
  }

  Future<void> calibrationStart() async {
    await _sendCommand('CALIBRATE_START');
    setState(() => calibrationState = 'STARTED');
  }

  Future<void> calibrationOpen() async {
    await _sendCommand('CALIBRATE_OPEN');
    setState(() => calibrationState = 'OPEN');
  }

  Future<void> calibrationClose() async {
    await _sendCommand('CALIBRATE_CLOSE');
    setState(() => calibrationState = 'CLOSE');
  }

  Future<void> calibrationComplete() async {
    await _sendCommand('CALIBRATE_COMPLETE');
    setState(() => calibrationState = 'SAVED TO NVS');
  }

  Future<void> setVoltageThreshold() async {
    await _sendCommand('SET_VOLTAGE_THRESHOLD', value: (voltageThreshold * 100).round());
  }

  Future<void> setOcTrip() async {
    await _sendCommand('SET_OC_TRIP', value: (ocTrip * 100).round());
  }

  Future<void> setOcReset() async {
    await _sendCommand('SET_OC_RESET', value: (ocReset * 100).round());
  }

  Future<void> toggleVoltageBypass(bool value) async {
    setState(() => voltageBypass = value);
    await _sendCommand(value ? 'VOLTAGE_BYPASS' : 'VOLTAGE_BYPASS_CANCEL');
  }

  Future<void> confirmVoltageBypass() async {
    setState(() => voltageBypass = true);
    await _sendCommand('VOLTAGE_BYPASS');
  }

  Future<void> cancelVoltageBypass() async {
    setState(() => voltageBypass = false);
    await _sendCommand('VOLTAGE_BYPASS_CANCEL');
  }

  void previewOcTrip() {
    setState(() {
      valveData = ValveData(
        valveId: valveData.valveId,
        status: 'OC TRIP',
        requested: valveData.requested,
        actual: valveData.actual,
        connected: valveData.connected,
        communicationId: valveData.communicationId,
        ocFault: true,
        lowVoltageBypass: valveData.lowVoltageBypass,
        gwid: valveData.gwid,
      );
      status = 'OC TRIP';
    });
  }

  void clearPreviewFaults() {
    setState(() {
      valveData = ValveData(
        valveId: valveData.valveId,
        status: 'STOPPED',
        requested: valveData.requested,
        actual: valveData.actual,
        connected: valveData.connected,
        communicationId: valveData.communicationId,
        ocFault: false,
        lowVoltageBypass: false,
        gwid: valveData.gwid,
      );
      status = 'STOPPED';
      voltageBypass = false;
    });
  }

  Future<void> showScheduleDialog() async {
    DateTime selectedDate = DateTime.now();
    TimeOfDay startTime = const TimeOfDay(hour: 6, minute: 0);
    TimeOfDay stopTime = const TimeOfDay(hour: 18, minute: 0);

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Set Schedule'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Date'),
                subtitle: Text(
                  '${selectedDate.year.toString().padLeft(4, '0')}-'
                  '${selectedDate.month.toString().padLeft(2, '0')}-'
                  '${selectedDate.day.toString().padLeft(2, '0')}',
                ),
                trailing: const Icon(Icons.calendar_today),
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: selectedDate,
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 3650)),
                  );
                  if (picked != null) setDialogState(() => selectedDate = picked);
                },
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Start time'),
                subtitle: Text(startTime.format(context)),
                trailing: const Icon(Icons.access_time),
                onTap: () async {
                  final picked = await showTimePicker(context: context, initialTime: startTime);
                  if (picked != null) setDialogState(() => startTime = picked);
                },
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Stop time'),
                subtitle: Text(stopTime.format(context)),
                trailing: const Icon(Icons.access_time),
                onTap: () async {
                  final picked = await showTimePicker(context: context, initialTime: stopTime);
                  if (picked != null) setDialogState(() => stopTime = picked);
                },
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('CANCEL')),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(dialogContext);
                _sendCommand('SCHEDULE_SET');
              },
              child: const Text('SAVE'),
            ),
          ],
        ),
      ),
    );
  }
  Future<void> showClockSettingsDialog() async {
    DateTime selectedDate = DateTime.now();
    TimeOfDay startTime = const TimeOfDay(hour: 6, minute: 0);
    TimeOfDay stopTime = const TimeOfDay(hour: 18, minute: 0);

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('DATE SET'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Date'),
                subtitle: Text(
                  '${selectedDate.year.toString().padLeft(4, '0')}-'
                  '${selectedDate.month.toString().padLeft(2, '0')}-'
                  '${selectedDate.day.toString().padLeft(2, '0')}',
                ),
                trailing: const Icon(Icons.calendar_today),
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: selectedDate,
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 3650)),
                  );
                  if (picked != null) {
                    setDialogState(() => selectedDate = picked);
                  }
                },
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Start time'),
                subtitle: Text(startTime.format(context)),
                trailing: const Icon(Icons.access_time),
                onTap: () async {
                  final picked = await showTimePicker(
                    context: context,
                    initialTime: startTime,
                  );
                  if (picked != null) {
                    setDialogState(() => startTime = picked);
                  }
                },
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('End time'),
                subtitle: Text(stopTime.format(context)),
                trailing: const Icon(Icons.access_time),
                onTap: () async {
                  final picked = await showTimePicker(
                    context: context,
                    initialTime: stopTime,
                  );
                  if (picked != null) {
                    setDialogState(() => stopTime = picked);
                  }
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('CANCEL'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(dialogContext);
                _sendCommand('CLOCK_WORK_SET');
              },
              child: const Text('SAVE'),
            ),
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
      case 'E-STOP':
        return Colors.red;
      default:
        return Colors.green;
    }
  }

  Widget actionButton(String text, VoidCallback onPressed, {bool danger = false}) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: SizedBox(
          height: 48,
          child: danger
              ? FilledButton.tonal(
                  style: FilledButton.styleFrom(foregroundColor: Colors.red),
                  onPressed: onPressed,
                  child: Text(text),
                )
              : FilledButton(onPressed: onPressed, child: Text(text)),
        ),
      ),
    );
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
        selectedValveId = data.valveId;
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
        title: const Text('Add New Valve'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('VALVE ID', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: selectedValveId,
                      items: valveIds
                          .map((id) => DropdownMenuItem(value: id, child: Text(id)))
                          .toList(),
                      onChanged: (value) {
                        if (value != null) setState(() => selectedValveId = value);
                      },
                      decoration: const InputDecoration(border: OutlineInputBorder()),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        const Expanded(child: Text('FW VERSION', style: TextStyle(fontWeight: FontWeight.bold))),
                        const Text('1.0.0'),
                        const SizedBox(width: 12),
                        OutlinedButton(onPressed: () => _sendCommand('OTA_UPDATE'), child: const Text('OTA')),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Expanded(child: Text('GWID', style: TextStyle(fontWeight: FontWeight.bold))),
                        Text(valveData.gwid.isEmpty ? '—' : valveData.gwid),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text('VALVE', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    Text('SET POINT: $selectedPosition%', textAlign: TextAlign.center, style: const TextStyle(fontSize: 30, fontWeight: FontWeight.bold)),
                    Slider(
                      value: selectedPosition.toDouble(),
                      min: 0,
                      max: 100,
                      divisions: 100,
                      label: '$selectedPosition%',
                      onChanged: (v) => selectPosition(v.round()),
                    ),
                    Wrap(
                      alignment: WrapAlignment.spaceEvenly,
                      spacing: 8,
                      children: [0, 25, 50, 75, 100]
                          .map((v) => ChoiceChip(label: Text('$v%'), selected: selectedPosition == v, onSelected: (_) => selectPosition(v)))
                          .toList(),
                    ),
                    const SizedBox(height: 14),
                    SizedBox(height: 48, child: ElevatedButton(onPressed: setValve, child: Text('SET % OPEN  —  $selectedPosition%'))),
                    const SizedBox(height: 10),
                    Row(children: [
                      actionButton('OPEN', openValve),
                      actionButton('CLOSE', closeValve),
                    ]),
                    const SizedBox(height: 8),
                    Row(children: [
                      actionButton('STOP', stopValve),
                      actionButton('E-STOP', emergencyStop, danger: true),
                    ]),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text('VALVE CALIBRATION', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Text('State: $calibrationState'),
                    const SizedBox(height: 10),
                    Row(children: [
                      actionButton('START', calibrationStart),
                      actionButton('OPEN', calibrationOpen),
                    ]),
                    const SizedBox(height: 8),
                    Row(children: [
                      actionButton('CLOSE', calibrationClose),
                      actionButton('COMPLETE / SAVE', calibrationComplete),
                    ]),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text('VOLTAGE', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    if (valveData.lowVoltageBypass)
                      Container(
                        width: double.infinity,
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        decoration: BoxDecoration(
                          color: Colors.orange.shade50,
                          border: Border.all(color: Colors.orange, width: 2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.bolt, color: Colors.orange),
                            SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'LOW VOLTAGE BYPASS ACTIVE',
                                style: TextStyle(
                                  color: Colors.orange,
                                  fontSize: 17,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    if (!valveData.lowVoltageBypass)
                      Container(
                        width: double.infinity,
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        decoration: BoxDecoration(
                          color: Colors.orange.shade50,
                          border: Border.all(color: Colors.orange, width: 2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const Row(
                              children: [
                                Icon(Icons.warning_amber_rounded, color: Colors.orange),
                                SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    'LOW VOLTAGE — BYPASS PENDING',
                                    style: TextStyle(
                                      color: Colors.orange,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton(
                                    onPressed: cancelVoltageBypass,
                                    child: const Text('CANCEL'),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: FilledButton(
                                    onPressed: confirmVoltageBypass,
                                    child: const Text('CONFIRM'),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Bypass'),
                      subtitle: Text(voltageBypass ? 'BYPASS ACTIVE' : 'BYPASS OFF'),
                      value: voltageBypass,
                      onChanged: toggleVoltageBypass,
                    ),
                    Row(
                      children: [
                        Expanded(child: Text('Threshold: ${voltageThreshold.toStringAsFixed(2)} V')),
                        OutlinedButton(onPressed: setVoltageThreshold, child: const Text('SET')),
                      ],
                    ),
                    Slider(
                      value: voltageThreshold,
                      min: 10.0,
                      max: 14.0,
                      divisions: 80,
                      label: '${voltageThreshold.toStringAsFixed(2)} V',
                      onChanged: (v) => setState(() => voltageThreshold = v),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text('CURRENT / OVER CURRENT', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    Row(children: [
                      Expanded(child: Text('OC trip: ${ocTrip.toStringAsFixed(1)} A')),
                      OutlinedButton(onPressed: setOcTrip, child: const Text('SET')),
                    ]),
                    Slider(value: ocTrip, min: 0.5, max: 20, divisions: 39, onChanged: (v) => setState(() => ocTrip = v)),
                    Row(children: [
                      Expanded(child: Text('Reset: ${ocReset.toStringAsFixed(1)} A')),
                      OutlinedButton(onPressed: setOcReset, child: const Text('SET')),
                    ]),
                    Slider(value: ocReset, min: 0.5, max: 20, divisions: 39, onChanged: (v) => setState(() => ocReset = v)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text('SCHEDULING / CLOCK', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 10),
                    Row(children: [
                      actionButton('VIEW SCHEDULE', () => _sendCommand('SCHEDULE_VIEW')),
                      actionButton('START', () => _sendCommand('SCHEDULE_START')),
                    ]),
                    const SizedBox(height: 8),
                    Row(children: [
                      actionButton('SET SCHEDULE', showScheduleDialog),
                      actionButton('CANCEL ALL', () => _sendCommand('SCHEDULE_CANCEL_ALL'), danger: true),
                    ]),
                    const Divider(height: 24),
                    Row(children: [
                      actionButton('CLOCK VIEW', () => _sendCommand('CLOCK_VIEW')),
                      actionButton('DATE SET', showClockSettingsDialog),
                    ]),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 48,
                      child: OutlinedButton(
                        onPressed: () => _sendCommand('CLOCK_WORK_SET'),
                        child: const Text('WORK SET'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('STATUS', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: previewOcTrip,
                            child: const Text('TEST OC TRIP'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: OutlinedButton(
                            onPressed: clearPreviewFaults,
                            child: const Text('CLEAR TEST'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    if (valveData.ocFault)
                      Container(
                        width: double.infinity,
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          border: Border.all(color: Colors.red, width: 2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.warning_rounded, color: Colors.red),
                            SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'OC TRIP',
                                style: TextStyle(
                                  color: Colors.red,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    Text(status, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: statusColor())),
                    Text('Requested: $requestedPosition%   Actual: $actualPosition%'),
                    const SizedBox(height: 8),
                    const Text('Controller not connected', style: TextStyle(color: Colors.grey)),
                  ],
                ),
              ),
            ),
            if (lastCommandJson.isNotEmpty) ...[
              const SizedBox(height: 12),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('LAST COMMAND JSON', style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      SelectableText(lastCommandJson, style: const TextStyle(fontFamily: 'monospace', fontSize: 12)),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
