import 'dart:convert';

import 'package:flutter/material.dart';

import '../models/valve_command.dart';
import '../services/aws_service.dart';

class ValveViewScreen extends StatefulWidget {
  final bool isLora;

  const ValveViewScreen({super.key, required this.isLora});

  @override
  State<ValveViewScreen> createState() => _ValveViewScreenState();
}

class _ValveViewScreenState extends State<ValveViewScreen> {
  static const valveIds = <String>['GSM-001', 'GSM-002', 'LORA-001', 'LORA-002'];

  late AwsService mqtt;
  String selectedValveId = 'GSM-001';
  int selectedPosition = 0;
  String status = 'STOPPED';
  String lastCommand = '';
  String calibration = 'IDLE';
  bool sleepBypass = false;
  double voltageThreshold = 11.50;
  double ocTrip = 5.0;
  double ocReset = 6.0;

  @override
  void initState() {
    super.initState();
    mqtt = AwsService(host: 'YOUR_AWS_IOT_ENDPOINT', clientId: 'ORBI-APP', valveId: selectedValveId);
  }

  Future<void> send(String command, {int value = 0}) async {
    final packet = ValveCommand(valveId: selectedValveId, command: command, value: value);
    setState(() => lastCommand = const JsonEncoder.withIndent('  ').convert(packet.toJson()));
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
          Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                Row(children: [
                  const Expanded(child: Text('ADD NEW VALVE', style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold))),
                  FilledButton.icon(onPressed: _addValve, icon: const Icon(Icons.add), label: const Text('ADD VALVE')),
                ]),
                const SizedBox(height: 12),
                const Text('VALVE ID', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                DropdownButtonFormField<String>(
                  value: selectedValveId,
                  decoration: const InputDecoration(border: OutlineInputBorder()),
                  items: valveIds.map((id) => DropdownMenuItem(value: id, child: Text(id))).toList(),
                  onChanged: chooseValve,
                ),
                const SizedBox(height: 12),
                Row(children: [
                  const Expanded(child: Text('FW VERSION', style: TextStyle(fontWeight: FontWeight.bold))),
                  Text(widget.isLora ? 'LoRa FW 1.0.0' : 'GSM FW 1.0.0'),
                ]),
              ]),
            ),
          ),
          if (!widget.isLora) _gsmStatusCard() else _loraStatusCard(),
          _positionCard(),
          _calibrationCard(),
          _voltageCard(),
          _currentCard(),
          _scheduleCard(),
          const SizedBox(height: 10),
          SizedBox(
            height: 54,
            child: FilledButton.tonal(
              onPressed: rebindOwner,
              style: FilledButton.styleFrom(foregroundColor: Colors.deepPurple),
              child: const Text('OWNER REBIND', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _gsmStatusCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(children: [
          const Text('SLEEP BYPASS / ACTIVE', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(sleepBypass ? 'ACTIVE' : 'SLEEP BYPASS'),
            subtitle: Text(sleepBypass ? 'Bypass active' : 'Normal sleep operation'),
            value: sleepBypass,
            onChanged: (value) async {
              setState(() => sleepBypass = value);
              await send(value ? 'VOLTAGE_BYPASS' : 'VOLTAGE_CANCEL');
            },
          ),
          _statusLine(),
        ]),
      ),
    );
  }

  Widget _loraStatusCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          const Text('LoRa STATUS', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          Row(children: [
            const Expanded(child: Text('RSSI')),
            _rssiBars(3),
          ]),
          const SizedBox(height: 8),
          const Row(children: [Expanded(child: Text('SF')), Text('SF9')]),
          const SizedBox(height: 8),
          _statusLine(),
        ]),
      ),
    );
  }

  Widget _rssiBars(int level) {
    return Row(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.end, children: List.generate(3, (index) {
      return Container(width: 7, height: 8 + (index * 5), margin: const EdgeInsets.only(left: 3), color: index < level ? Colors.green : Colors.grey.shade300);
    }));
  }

  Widget _statusLine() => Row(children: [const Expanded(child: Text('STATUS')), Text(status, style: const TextStyle(fontWeight: FontWeight.bold))]);

  Widget _positionCard() {
    return _card('VALVE CONTROL', Column(children: [
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
  }

  Widget _calibrationCard() {
    return _card('VALVE CALIBRATION', Column(children: [
      Align(alignment: Alignment.centerLeft, child: Text('State: $calibration')),
      const SizedBox(height: 8),
      Row(children: [Expanded(child: _small('START', () async { await send('CALIBRATE'); setState(() => calibration = 'STARTED'); })), const SizedBox(width: 8), Expanded(child: _small('OPEN', () async { await send('CAL_SET', value: 1); setState(() => calibration = 'OPEN'); }))]),
      const SizedBox(height: 8),
      Row(children: [Expanded(child: _small('CLOSE', () async { await send('CAL_SET', value: 0); setState(() => calibration = 'CLOSE'); })), const SizedBox(width: 8), Expanded(child: _small('CANCEL / SAVE', () async { await send('CAL_ABORT'); setState(() => calibration = 'SAVED'); }))]),
    ]));
  }

  Widget _voltageCard() {
    return _card('VOLTAGE / BYPASS', Column(children: [
      Row(children: [Expanded(child: Text('Threshold: ${voltageThreshold.toStringAsFixed(2)} V')), OutlinedButton(onPressed: () => send('SET_VOLTAGE_THRESHOLD', value: (voltageThreshold * 100).round()), child: const Text('SET'))]),
      Slider(value: voltageThreshold, min: 10, max: 14, divisions: 80, onChanged: (v) => setState(() => voltageThreshold = v)),
    ]));
  }

  Widget _currentCard() {
    return _card('CURRENT / OVER CURRENT', Column(children: [
      Row(children: [Expanded(child: Text('OC Trip: ${ocTrip.toStringAsFixed(1)} A')), OutlinedButton(onPressed: () => send('SET_CURRENT', value: (ocTrip * 100).round()), child: const Text('SET'))]),
      Slider(value: ocTrip, min: 0.5, max: 20, divisions: 39, onChanged: (v) => setState(() => ocTrip = v)),
      Row(children: [Expanded(child: Text('Reset: ${ocReset.toStringAsFixed(1)} A')), OutlinedButton(onPressed: () => send('SET_OC_RESET', value: (ocReset * 100).round()), child: const Text('SET'))]),
      Slider(value: ocReset, min: 0.5, max: 20, divisions: 39, onChanged: (v) => setState(() => ocReset = v)),
    ]));
  }

  Widget _scheduleCard() {
    return _card('SCHEDULING / CLOCK', Column(children: [
      Row(children: [Expanded(child: _small('VIEW SCHEDULE', () => send('GET_SCHEDULE'))), const SizedBox(width: 8), Expanded(child: _small('START', () => send('SCHEDULE_START')))]),
      const SizedBox(height: 8),
      Row(children: [Expanded(child: _small('SET SCHEDULE', _setSchedule)), const SizedBox(width: 8), Expanded(child: _small('CANCEL ALL', () => send('CLR_SCHEDULE')))]),
      const Divider(height: 22),
      Row(children: [Expanded(child: _small('CLOCK VIEW', () => send('CLOCK_VIEW'))), const SizedBox(width: 8), Expanded(child: _small('START TIME', () => send('START_TIME')))]),
      const SizedBox(height: 8),
      Row(children: [Expanded(child: _small('STOP TIME', () => send('STOP_TIME'))), const SizedBox(width: 8), Expanded(child: _small('DATE SET', () => send('SET_TIME')))]),
      const SizedBox(height: 8),
      SizedBox(width: double.infinity, child: OutlinedButton(onPressed: () => send('WEEK'), child: const Text('WEEK'))),
    ]));
  }

  Future<void> _setSchedule() async {
    await showDialog<void>(context: context, builder: (context) => AlertDialog(title: const Text('Set Schedule'), content: const Text('Use the device schedule editor to select date, start time and stop time.'), actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('CANCEL')), FilledButton(onPressed: () { Navigator.pop(context); send('SET_SCHEDULE'); }, child: const Text('SAVE'))]));
  }

  Widget _card(String title, Widget child) => Card(child: Padding(padding: const EdgeInsets.all(14), child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)), const SizedBox(height: 10), child])));

  Widget _small(String text, Future<void> Function() onPressed) => SizedBox(height: 46, child: OutlinedButton(onPressed: () => onPressed(), child: Text(text)));

  void _addValve() {
    showDialog<void>(context: context, builder: (context) => AlertDialog(title: const Text('ADD NEW VALVE'), content: const Text('New GSM and LoRa valves are registered through the device provisioning flow. The combined Valve ID list is used on this page.'), actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK'))]));
  }
}
