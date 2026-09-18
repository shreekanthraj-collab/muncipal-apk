import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';

import '../models/valve_command.dart';
import '../models/valve_data.dart';
import '../services/aws_service.dart';
import '../services/valve_storage.dart';

class ValveViewScreen extends StatefulWidget {
  final bool isLora;

  const ValveViewScreen({super.key, required this.isLora});

  @override
  State<ValveViewScreen> createState() => _ValveViewScreenState();
}

class _ValveViewScreenState extends State<ValveViewScreen> {
  List<String> valveIds = const [];
  static const mqttHost = String.fromEnvironment('MQTT_HOST', defaultValue: '');

  late final AwsService mqtt;
  StreamSubscription<ValveData>? statusSubscription;
  String? selectedValveId;
  int selectedPosition = 0;
  String status = 'STOPPED';
  String calibration = 'IDLE';
  bool sleepBypass = false;
  double voltageThreshold = 11.50;
  double ocTrip = 5.0;
  double ocReset = 6.0;

  @override
  void initState() {
    super.initState();
    mqtt = AwsService(host: mqttHost, clientId: 'ORBI-APP', valveId: '');
    statusSubscription = mqtt.valveStatusStream.listen(_applyStatus);
    unawaited(_loadValveIds());
    if (mqttHost.isNotEmpty) unawaited(_connect());
  }

  Future<void> _loadValveIds() async {
    final ids = await ValveStorage.loadValveIds();
    if (!mounted) return;
    setState(() {
      valveIds = ids;
      if (selectedValveId == null || !ids.contains(selectedValveId)) {
        selectedValveId = ids.isEmpty ? null : ids.first;
      }
    });
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

  Future<void> send(
    String command, {
    int value = 0,
    Map<String, int>? fields,
  }) async {
    final packet = ValveCommand(
      valveId: selectedValveId ?? '',
      command: command,
      value: value,
      year: fields?['year'],
      month: fields?['month'],
      day: fields?['day'],
      hour: fields?['hour'],
      minute: fields?['minute'],
      second: fields?['second'],
      wday: fields?['wday'],
      slot: fields?['slot'],
      enabled: fields?['enabled'],
      action: fields?['action'],
      days: fields?['days'],
    );
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
            const Text('VALVE ID', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            DropdownButtonFormField<String>(
              initialValue: selectedValveId,
              decoration: const InputDecoration(border: OutlineInputBorder()),
              hint: const Text('Select a valve saved on MAP'),
              items: valveIds.map((id) => DropdownMenuItem(value: id, child: Text(id))).toList(),
              onChanged: valveIds.isEmpty ? null : chooseValve,
            ),
            if (valveIds.isEmpty) ...[
              const SizedBox(height: 8),
              const Text('No valves saved on MAP. Add the valve from MAP VIEW first.'),
            ],
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
    Row(children: [Expanded(child: FilledButton(onPressed: () async { await send('OPEN'); setState(() => status = 'OPENING'); }, child: const Text('OPEN'))), const SizedBox(width: 8), Expanded(child: FilledButton(onPressed: () async { await send('CLOSE'); setState(() => status = 'CLOSING'); }, child: const Text('CLOSE')))]),
    const SizedBox(height: 8),
    Row(children: [Expanded(child: FilledButton(onPressed: () async { await send('STOP'); setState(() => status = 'STOPPED'); }, child: const Text('STOP'))), const SizedBox(width: 8), Expanded(child: FilledButton.tonal(onPressed: () async { await send('ESTOP'); setState(() => status = 'E-STOP'); }, child: const Text('E-STOP')))]),
  ]));

  Widget _calibrationCard() => _card('VALVE CALIBRATION', Column(children: [
    Align(alignment: Alignment.centerLeft, child: Text('State: $calibration')),
    const SizedBox(height: 8),
    Row(children: [Expanded(child: _small('START', () async { await send('CALIBRATE'); setState(() => calibration = 'STARTED'); })), const SizedBox(width: 8), Expanded(child: _small('OPEN', () async { await send('CAL_SET', value: 1); setState(() => calibration = 'OPEN'); }))]),
    const SizedBox(height: 8),
    Row(children: [Expanded(child: _small('CLOSE', () async { await send('CAL_SET', value: 0); setState(() => calibration = 'CLOSE'); })), const SizedBox(width: 8), Expanded(child: _small('CANCEL / SAVE', () async { await send('CAL_ABORT'); setState(() => calibration = 'SAVED'); }))]),
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
    Row(children: [Expanded(child: _small('SET SCHEDULE', _setSchedule)), const SizedBox(width: 8), Expanded(child: _small('CANCEL ALL', () => send('CLR_SCHEDULE')))]),
    const Divider(height: 22),
    Row(children: [Expanded(child: _small('CLOCK VIEW', () => send('CLOCK_VIEW'))), const SizedBox(width: 8), Expanded(child: _small('START TIME', () => send('START_TIME')))]),
    const SizedBox(height: 8),
    Row(children: [Expanded(child: _small('STOP TIME', () => send('STOP_TIME'))), const SizedBox(width: 8), Expanded(child: _small('DATE SET', _setClock))]),
    const SizedBox(height: 8),
    SizedBox(width: double.infinity, child: OutlinedButton(onPressed: () => send('WEEK'), child: const Text('WEEK'))),
  ]));

  Future<void> _setClock() async {
    final now = DateTime.now();
    final date = await showDatePicker(context: context, initialDate: now, firstDate: DateTime(2020), lastDate: DateTime(2099));
    if (date == null || !mounted) return;
    final time = await showTimePicker(context: context, initialTime: TimeOfDay.fromDateTime(now));
    if (time == null || !mounted) return;
    final dt = DateTime(date.year, date.month, date.day, time.hour, time.minute);
    await send('SET_TIME', fields: {'year': dt.year, 'month': dt.month, 'day': dt.day, 'hour': dt.hour, 'minute': dt.minute, 'second': dt.second, 'wday': dt.weekday % 7});
  }

  Future<void> _setSchedule() async {
    int slot = 0;
    bool enabled = true;
    int action = 1;
    int days = 127;
    TimeOfDay start = const TimeOfDay(hour: 6, minute: 0);
    TimeOfDay stop = const TimeOfDay(hour: 18, minute: 0);

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('SET SCHEDULE'),
          content: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              DropdownButtonFormField<int>(initialValue: slot, decoration: const InputDecoration(labelText: 'Slot'), items: List.generate(8, (i) => DropdownMenuItem(value: i, child: Text('Slot $i'))), onChanged: (v) => setDialogState(() => slot = v ?? 0)),
              SwitchListTile(contentPadding: EdgeInsets.zero, title: const Text('Enabled'), value: enabled, onChanged: (v) => setDialogState(() => enabled = v)),
              DropdownButtonFormField<int>(initialValue: action, decoration: const InputDecoration(labelText: 'Action'), items: const [DropdownMenuItem(value: 1, child: Text('OPEN')), DropdownMenuItem(value: 0, child: Text('CLOSE'))], onChanged: (v) => setDialogState(() => action = v ?? 1)),
              ListTile(title: const Text('Start'), subtitle: Text(start.format(context)), trailing: const Icon(Icons.access_time), onTap: () async { final t = await showTimePicker(context: context, initialTime: start); if (t != null) setDialogState(() => start = t); }),
              ListTile(title: const Text('Stop'), subtitle: Text(stop.format(context)), trailing: const Icon(Icons.access_time), onTap: () async { final t = await showTimePicker(context: context, initialTime: stop); if (t != null) setDialogState(() => stop = t); }),
              const SizedBox(height: 4),
              Wrap(spacing: 4, children: List.generate(7, (i) { final bit = 1 << i; const names = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat']; return FilterChip(label: Text(names[i]), selected: (days & bit) != 0, onSelected: (v) => setDialogState(() => days = v ? days | bit : days & ~bit)); })),
            ]),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('CANCEL')),
            FilledButton(
              onPressed: () async {
                final startSeconds = start.hour * 3600 + start.minute * 60;
                final stopSeconds = stop.hour * 3600 + stop.minute * 60;
                Navigator.pop(dialogContext);
                await send('SET_SCHEDULE', fields: {
                  'slot': slot,
                  'enabled': enabled ? 1 : 0,
                  'action': action,
                  'days': days,
                  'hour': start.hour,
                  'minute': start.minute,
                  'second': stopSeconds,
                  'wday': stopSeconds ~/ 60,
                  'year': startSeconds,
                  'month': stop.hour,
                  'day': stop.minute,
                });
              },
              child: const Text('SAVE'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _card(String title, Widget child) => Card(child: Padding(padding: const EdgeInsets.all(14), child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)), const SizedBox(height: 10), child])));

  Widget _small(String text, Future<void> Function() onPressed) => SizedBox(height: 46, child: OutlinedButton(onPressed: () => onPressed(), child: Text(text)));
}
