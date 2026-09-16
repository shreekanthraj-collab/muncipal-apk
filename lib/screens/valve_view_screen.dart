import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';

import '../models/valve_command.dart';
import '../models/valve_data.dart';
import '../services/aws_service.dart';

class ValveViewScreen extends StatefulWidget {
  final bool isLora;

  const ValveViewScreen({super.key, required this.isLora});

  @override
  State<ValveViewScreen> createState() => _ValveViewScreenState();
}

class _ValveViewScreenState extends State<ValveViewScreen> {
  static const valveIds = <String>['GSM-001', 'GSM-002', 'LORA-001', 'LORA-002'];
  static const mqttHost = String.fromEnvironment('MQTT_HOST', defaultValue: '');

  late final AwsService mqtt;
  StreamSubscription<ValveData>? statusSubscription;
  String selectedValveId = 'GSM-001';
  int selectedPosition = 0;
  String status = 'STOPPED';
  String calibration = 'IDLE';
  bool sleepBypass = false;
  double voltageThreshold = 11.50;
  double ocTrip = 5.0;
  double ocReset = 6.0;

  TimeOfDay _scheduleStart = const TimeOfDay(hour: 6, minute: 0);
  TimeOfDay _scheduleStop = const TimeOfDay(hour: 18, minute: 0);
  DateTime _clockDate = DateTime.now();
  final Set<int> _scheduleDays = <int>{1, 2, 3, 4, 5, 6, 7};
  bool _scheduleEnabled = true;

  static const List<String> _dayNames = <String>[
    'Mon',
    'Tue',
    'Wed',
    'Thu',
    'Fri',
    'Sat',
    'Sun',
  ];

  @override
  void initState() {
    super.initState();
    mqtt = AwsService(host: mqttHost, clientId: 'ORBI-APP', valveId: selectedValveId);
    statusSubscription = mqtt.valveStatusStream.listen(_applyStatus);
    if (mqttHost.isNotEmpty) unawaited(_connect());
  }

  Future<void> _connect() async {
    try {
      await mqtt.connect();
    } catch (_) {
      if (mounted) setState(() => status = 'MQTT OFFLINE');
    }
  }

  void _applyStatus(ValveData data) {
    if (!mounted) return;
    setState(() {
      status = data.status;
      selectedPosition = data.actual.clamp(0, 100).toInt();
    });
  }

  Future<void> send(String command, {int value = 0}) async {
    final packet = ValveCommand(valveId: selectedValveId, command: command, value: value);
    debugPrint(const JsonEncoder.withIndent('  ').convert(packet.toJson()));
    if (!mqtt.connected) return;
    try {
      await mqtt.sendCommand(packet);
    } catch (_) {
      if (mounted) setState(() => status = 'TRANSPORT ERROR');
    }
  }

  Future<void> _sendPacket(ValveCommand packet) async {
    debugPrint(const JsonEncoder.withIndent('  ').convert(packet.toJson()));
    if (!mqtt.connected) return;
    try {
      await mqtt.sendCommand(packet);
    } catch (_) {
      if (mounted) setState(() => status = 'TRANSPORT ERROR');
    }
  }

  void chooseValve(String? value) {
    if (value == null) return;
    setState(() => selectedValveId = value);
  }

  Future<void> setValve() async {
    await send('SET_POSITION', value: selectedPosition);
    if (mounted) setState(() => status = 'POSITION ${selectedPosition}%');
  }

  Future<void> rebindOwner() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('OWNER REBIND'),
        content: Text('Rebind selected valve $selectedValveId to this owner?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('CANCEL')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('REBIND')),
        ],
      ),
    );
    if (confirmed == true) {
      await send('REBIND_OWNER');
      if (mounted) setState(() => status = 'REBIND REQUESTED');
    }
  }

  @override
  void dispose() {
    statusSubscription?.cancel();
    mqtt.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.isLora ? 'LoRa VALVE VIEW' : 'GSM / LTE VALVE VIEW';
    return Scaffold(
      appBar: AppBar(title: Text(title), centerTitle: true),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 24),
        children: [
          Card(child: Padding(padding: const EdgeInsets.all(14), child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Row(children: [const Expanded(child: Text('ADD NEW VALVE', style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold))), FilledButton.icon(onPressed: _addValve, icon: const Icon(Icons.add), label: const Text('ADD VALVE'))]),
            const SizedBox(height: 12),
            const Text('VALVE ID', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            DropdownButtonFormField<String>(initialValue: selectedValveId, decoration: const InputDecoration(border: OutlineInputBorder()), items: valveIds.map((id) => DropdownMenuItem(value: id, child: Text(id))).toList(), onChanged: chooseValve),
            const SizedBox(height: 12),
            Row(children: [const Expanded(child: Text('FW VERSION', style: TextStyle(fontWeight: FontWeight.bold))), Text(widget.isLora ? 'LoRa FW 1.0.0' : 'GSM FW 1.0.0')]),
          ]))),
          if (!widget.isLora) _gsmStatusCard() else _loraStatusCard(),
          _positionCard(),
          _calibrationCard(),
          _voltageCard(),
          _currentCard(),
          _scheduleCard(),
          const SizedBox(height: 10),
          SizedBox(height: 54, child: FilledButton.tonal(onPressed: rebindOwner, style: FilledButton.styleFrom(foregroundColor: Colors.deepPurple), child: const Text('OWNER REBIND', style: TextStyle(fontWeight: FontWeight.bold)))),
        ],
      ),
    );
  }

  Widget _gsmStatusCard() => Card(child: Padding(padding: const EdgeInsets.all(14), child: Column(children: [
    const Text('SLEEP BYPASS / ACTIVE', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
    SwitchListTile(contentPadding: EdgeInsets.zero, title: Text(sleepBypass ? 'ACTIVE' : 'SLEEP BYPASS'), subtitle: Text(sleepBypass ? 'Bypass active' : 'Normal sleep operation'), value: sleepBypass, onChanged: (value) async { setState(() => sleepBypass = value); await send(value ? 'VOLTAGE_BYPASS' : 'VOLTAGE_CANCEL'); }),
    _statusLine(),
  ])));

  Widget _loraStatusCard() => Card(child: Padding(padding: const EdgeInsets.all(14), child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
    const Text('LoRa STATUS', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
    const SizedBox(height: 10),
    Row(children: [const Expanded(child: Text('RSSI')), _rssiBars(3)]),
    const SizedBox(height: 8),
    const Row(children: [Expanded(child: Text('SF')), Text('SF9')]),
    const SizedBox(height: 8),
    _statusLine(),
  ])));

  Widget _rssiBars(int level) => Row(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.end, children: List.generate(3, (index) => Container(width: 7, height: 8 + (index * 5), margin: const EdgeInsets.only(left: 3), color: index < level ? Colors.green : Colors.grey.shade300)));

  Widget _statusLine() => Row(children: [const Expanded(child: Text('STATUS')), Text(status, style: const TextStyle(fontWeight: FontWeight.bold))]);

  Widget _positionCard() => _card('VALVE CONTROL', Column(children: [
    Text('SET POINT: $selectedPosition%', style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
    Slider(value: selectedPosition.toDouble(), min: 0, max: 100, divisions: 100, label: '$selectedPosition%', onChanged: (v) => setState(() => selectedPosition = v.round())),
    Wrap(spacing: 6, alignment: WrapAlignment.center, children: [0, 25, 50, 75, 100].map((v) => ChoiceChip(label: Text('$v%'), selected: selectedPosition == v, onSelected: (_) => setState(() => selectedPosition = v))).toList()),
    const SizedBox(height: 12),
    SizedBox(height: 48, width: double.infinity, child: FilledButton(onPressed: setValve, child: Text('SET % OPEN — $selectedPosition%'))),
    const SizedBox(height: 8),
    Row(children: [Expanded(child: FilledButton(onPressed: () async { await send('OPEN'); if (mounted) setState(() => status = 'OPENING'); }, child: const Text('OPEN'))), const SizedBox(width: 8), Expanded(child: FilledButton(onPressed: () async { await send('CLOSE'); if (mounted) setState(() => status = 'CLOSING'); }, child: const Text('CLOSE')))]),
    const SizedBox(height: 8),
    Row(children: [Expanded(child: FilledButton(onPressed: () async { await send('STOP'); if (mounted) setState(() => status = 'STOPPED'); }, child: const Text('STOP'))), const SizedBox(width: 8), Expanded(child: FilledButton.tonal(onPressed: () async { await send('ESTOP'); if (mounted) setState(() => status = 'E-STOP'); }, child: const Text('E-STOP')))]),
  ]));

  Widget _calibrationCard() => _card('VALVE CALIBRATION', Column(children: [
    Align(alignment: Alignment.centerLeft, child: Text('State: $calibration')),
    const SizedBox(height: 8),
    Row(children: [Expanded(child: _small('START', () async { await send('CALIBRATE'); if (mounted) setState(() => calibration = 'STARTED'); })), const SizedBox(width: 8), Expanded(child: _small('OPEN', () async { await send('CAL_SET', value: 1); if (mounted) setState(() => calibration = 'OPEN'); }))]),
    const SizedBox(height: 8),
    Row(children: [Expanded(child: _small('CLOSE', () async { await send('CAL_SET', value: 0); if (mounted) setState(() => calibration = 'CLOSE'); })), const SizedBox(width: 8), Expanded(child: _small('CANCEL / SAVE', () async { await send('CAL_ABORT'); if (mounted) setState(() => calibration = 'SAVED'); }))]),
  ]));

  Widget _voltageCard() => _card('VOLTAGE / BYPASS', Column(children: [
    Row(children: [Expanded(child: Text('Threshold: ${voltageThreshold.toStringAsFixed(2)} V')), OutlinedButton(onPressed: () => send('SET_VOLTAGE_THRESHOLD', value: (voltageThreshold * 100).round()), child: const Text('SET'))]),
    Slider(value: voltageThreshold, min: 10, max: 14, divisions: 80, onChanged: (v) => setState(() => voltageThreshold = v)),
  ]));

  Widget _currentCard() => _card('CURRENT / OVER CURRENT', Column(children: [
    Row(children: [Expanded(child: Text('OC Trip: ${ocTrip.toStringAsFixed(1)} A')), OutlinedButton(onPressed: () => send('SET_CURRENT', value: (ocTrip * 100).round()), child: const Text('SET'))]),
    Slider(value: ocTrip, min: 0.5, max: 20, divisions: 39, onChanged: (v) => setState(() => ocTrip = v)),
    Row(children: [Expanded(child: Text('Reset: ${ocReset.toStringAsFixed(1)} A')), OutlinedButton(onPressed: () => send('SET_OC_RESET', value: (ocReset * 100).round()), child: const Text('SET'))]),
    Slider(value: ocReset, min: 0.5, max: 20, divisions: 39, onChanged: (v) => setState(() => ocReset = v)),
  ]));

  Widget _scheduleCard() => _card('SCHEDULING / CLOCK', Column(children: [
    Row(children: [Expanded(child: _small('VIEW SCHEDULE', () => send('GET_SCHEDULE'))), const SizedBox(width: 8), Expanded(child: _small('START', () => send('SCHEDULE_START')))]),
    const SizedBox(height: 8),
    Row(children: [Expanded(child: _small('SET SCHEDULE', _setSchedule)), const SizedBox(width: 8), Expanded(child: _small('CANCEL ALL', _clearSchedule))]),
    const Divider(height: 22),
    Row(children: [const Expanded(child: Text('Schedule')), Switch(value: _scheduleEnabled, onChanged: (v) => setState(() => _scheduleEnabled = v))]),
    Row(children: [Expanded(child: _timeButton('OPEN', _scheduleStart, () => _pickTime(true))), const SizedBox(width: 8), Expanded(child: _timeButton('CLOSE', _scheduleStop, () => _pickTime(false)))]),
    const SizedBox(height: 8),
    Align(alignment: Alignment.centerLeft, child: const Text('DAYS', style: TextStyle(fontWeight: FontWeight.bold))),
    const SizedBox(height: 4),
    Wrap(spacing: 4, children: List.generate(7, (index) {
      final day = index + 1;
      return FilterChip(label: Text(_dayNames[index]), selected: _scheduleDays.contains(day), onSelected: (selected) { setState(() { if (selected) { _scheduleDays.add(day); } else { _scheduleDays.remove(day); } }); });
    })),
    const SizedBox(height: 8),
    SizedBox(width: double.infinity, child: OutlinedButton.icon(onPressed: _setClock, icon: const Icon(Icons.schedule), label: Text('SET CLOCK — ${_formatDate(_clockDate)} ${_formatTime(TimeOfDay.fromDateTime(_clockDate))}'))),
    const SizedBox(height: 8),
    SizedBox(width: double.infinity, child: FilledButton.tonal(onPressed: () => send('GET_SCHEDULE'), child: const Text('READ CURRENT SCHEDULE'))),
  ]));

  Widget _timeButton(String label, TimeOfDay time, VoidCallback onPressed) => OutlinedButton(onPressed: onPressed, child: Text('$label\n${_formatTime(time)}', textAlign: TextAlign.center));

  String _formatTime(TimeOfDay time) => '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';

  String _formatDate(DateTime date) => '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

  Future<void> _pickTime(bool start) async {
    final picked = await showTimePicker(context: context, initialTime: start ? _scheduleStart : _scheduleStop);
    if (picked == null || !mounted) return;
    setState(() { if (start) { _scheduleStart = picked; } else { _scheduleStop = picked; } });
  }

  Future<void> _setClock() async {
    final picked = await showDatePicker(context: context, initialDate: _clockDate, firstDate: DateTime(2020), lastDate: DateTime(2099));
    if (picked == null || !mounted) return;
    final time = await showTimePicker(context: context, initialTime: TimeOfDay.fromDateTime(_clockDate));
    if (time == null || !mounted) return;
    _clockDate = DateTime(picked.year, picked.month, picked.day, time.hour, time.minute);
    final packet = ValveCommand(
      valveId: selectedValveId,
      command: 'SET_TIME',
      value: 0,
      year: _clockDate.year,
      month: _clockDate.month,
      day: _clockDate.day,
      hour: _clockDate.hour,
      minute: _clockDate.minute,
      second: 0,
      wday: _clockDate.weekday,
    );
    await _sendPacket(packet);
    if (mounted) setState(() {});
  }

  int _dayMask() {
    var mask = 0;
    for (final day in _scheduleDays) {
      mask |= 1 << (day - 1);
    }
    return mask;
  }

  Future<void> _setSchedule() async {
    if (_scheduleDays.isEmpty) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Select at least one day')));
      return;
    }
    final days = _dayMask();
    final enabled = _scheduleEnabled ? 1 : 0;
    await _sendPacket(ValveCommand(
      valveId: selectedValveId,
      command: 'SET_SCHEDULE',
      value: 0,
      slot: 0,
      enabled: enabled,
      action: 1,
      days: days,
      hour: _scheduleStart.hour,
      minute: _scheduleStart.minute,
    ));
    await _sendPacket(ValveCommand(
      valveId: selectedValveId,
      command: 'SET_SCHEDULE',
      value: 0,
      slot: 1,
      enabled: enabled,
      action: 0,
      days: days,
      hour: _scheduleStop.hour,
      minute: _scheduleStop.minute,
    ));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(_scheduleEnabled ? 'Schedule saved' : 'Schedule disabled')));
    }
  }

  Future<void> _clearSchedule() async {
    await send('CLR_SCHEDULE');
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('All schedules cleared')));
  }

  Widget _card(String title, Widget child) => Card(child: Padding(padding: const EdgeInsets.all(14), child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)), const SizedBox(height: 10), child])));

  Widget _small(String text, Future<void> Function() onPressed) => SizedBox(height: 46, child: OutlinedButton(onPressed: () => onPressed(), child: Text(text)));

  void _addValve() {
    showDialog<void>(context: context, builder: (context) => AlertDialog(title: const Text('ADD NEW VALVE'), content: const Text('New GSM and LoRa valves are registered through the device provisioning flow. The combined Valve ID list is used on this page.'), actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK'))]));
  }
}
