import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';

import '../models/valve_command.dart';
import '../models/valve_data.dart';
import '../services/aws_service.dart';
import '../services/municipal_session.dart';
import '../services/server_api_service.dart';
import '../services/valve_fault_storage.dart';
import '../services/valve_position_storage.dart';

class ValveViewScreen extends StatefulWidget {
  final bool isLora;

  const ValveViewScreen({super.key, required this.isLora});

  @override
  State<ValveViewScreen> createState() => _ValveViewScreenState();
}

class _ValveViewScreenState extends State<ValveViewScreen> {
  List<String> valveIds = const [];
  Map<String, Map<String, String>> valveDetails = const {};
  static const mqttHost = String.fromEnvironment('MQTT_HOST', defaultValue: '');

  late final AwsService mqtt;
  StreamSubscription<ValveData>? statusSubscription;
  String? selectedValveId;
  int selectedPosition = 0;
  int actualPosition = 0;
  String status = 'STOPPED';
  String calibration = 'IDLE';
  bool sleepBypass = false;
  double voltageThreshold = 11.50;
  double ocTrip = 5.0;
  double ocReset = 6.0;
  String communicationId = '';
  String gwid = '';
  bool ocFault = false;
  bool lowVoltageBypass = false;
  bool lowVoltageBypassKnown = false;
  bool hasActualPosition = false;
  DateTime? _lastTelemetryAt;
  bool _telemetryConnected = false;
  Timer? _freshnessTimer;
  bool _registryLoading = true;
  String? _registryError;
  static const _serverUrl = String.fromEnvironment('ORB_SERVER_URL', defaultValue: 'http://10.0.2.2:8000');

  @override
  void initState() {
    super.initState();
    mqtt = AwsService(host: mqttHost, clientId: 'ORBI-APP', valveId: '');
    statusSubscription = mqtt.valveStatusStream.listen(_applyStatus);
    unawaited(_loadValveIds());
    _freshnessTimer = Timer.periodic(const Duration(seconds: 15), (_) { if (mounted) setState(() {}); });
    if (mqttHost.isNotEmpty) unawaited(_connect());
  }

  Future<void> _loadValveIds() async {
    try {
      final session = await MunicipalSessionStorage.load();
      if (session == null) throw const FormatException('Municipal login required. Sign in again.');
      final api = ServerApiService(baseUrl: _serverUrl, bearerToken: session.accessToken);
      final registered = await api.getRegisteredMunicipalValves();
      final details = <String, Map<String, String>>{};
      for (final valve in registered) {
        final id = (valve['valve_id'] ?? valve['id'] ?? '').toString().trim();
        if (id.isEmpty) continue;
        details[id] = {
          'zone': (valve['zone'] ?? valve['zone_id'] ?? '').toString(),
          'ward': (valve['ward'] ?? valve['ward_id'] ?? '').toString(),
          'zone_id': (valve['zone_id'] ?? '').toString(),
          'ward_id': (valve['ward_id'] ?? '').toString(),
        };
      }
      final ids = details.keys.toList(growable: false);
      if (!mounted) return;
      setState(() {
        valveDetails = details; valveIds = ids; _registryLoading = false; _registryError = null;
        if (selectedValveId == null || !ids.contains(selectedValveId)) selectedValveId = ids.isEmpty ? null : ids.first;
      });
      if (selectedValveId != null) {
        mqtt.subscribeValveStatus(selectedValveId!);
        unawaited(_loadSelectedFault(selectedValveId!));
        unawaited(_loadSavedPosition(selectedValveId!));
      }
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _registryLoading = false; _registryError = error.toString();
        valveIds = const []; valveDetails = const {}; selectedValveId = null;
      });
    }
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
    if (selectedValveId == null || data.valveId != selectedValveId) return;
    setState(() {
      _lastTelemetryAt = DateTime.now();
      _telemetryConnected = data.connected;
      status = data.status;
      actualPosition = data.actual.clamp(0, 100).toInt();
      communicationId = data.connected ? data.communicationId : '';
      gwid = data.gwid;
      ocFault = data.ocFault;
      lowVoltageBypass = data.lowVoltageBypass;
      lowVoltageBypassKnown = data.lowVoltageBypassKnown;
      hasActualPosition = true;
      unawaited(ValveFaultStorage.save(data.valveId, data.ocFault));
    });
  }

  Future<bool> send(
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
    if (!mqtt.connected) return false;
    try {
      await mqtt.sendCommand(packet);
      return true;
    } catch (_) {
      if (mounted) setState(() => status = 'TRANSPORT ERROR');
      return false;
    }
  }

  void chooseValve(String? value) {
    if (value == null) return;
    mqtt.subscribeValveStatus(value);
    setState(() {
      selectedValveId = value;
      selectedPosition = 0;
      status = 'STOPPED';
      communicationId = '';
      gwid = '';
      lowVoltageBypass = false;
      lowVoltageBypassKnown = false;
      hasActualPosition = false;
      _lastTelemetryAt = null;
      _telemetryConnected = false;
    });
    unawaited(_loadSelectedFault(value));
    unawaited(_loadSavedPosition(value));
  }

  Future<void> _loadSavedPosition(String valveId) async {
    final saved = await ValvePositionStorage.load(valveId);
    if (!mounted || selectedValveId != valveId || saved == null) return;
    setState(() => selectedPosition = saved);
  }

  Future<void> _loadSelectedFault(String valveId) async {
    final fault = await ValveFaultStorage.load(valveId);
    if (!mounted || selectedValveId != valveId) return;
    setState(() {
      ocFault = fault;
    });
  }

  Future<bool> setValve() async {
    final valveId = selectedValveId;
    if (valveId == null || valveId.isEmpty) return false;
    final target = selectedPosition.clamp(0, 100);
    final sent = await send('SET_POSITION', value: target);
    if (!sent) return false;
    await ValvePositionStorage.save(valveId, target);
    if (mounted && selectedValveId == valveId) {
      setState(() => status = 'POSITION $target%');
    }
    return true;
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
    _freshnessTimer?.cancel();
    mqtt.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.isLora ? 'LoRa VALVE VIEW' : 'GSM / LTE VALVE VIEW';
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(title, maxLines: 1),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 24),
        children: [
          Card(child: Padding(padding: const EdgeInsets.all(14), child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Row(
              children: [
                Expanded(
                  child: _infoField(
                    'ZONE NO',
                    valveDetails[selectedValveId]?['zone'] ?? '--',
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _infoField(
                    'WARD NO',
                    valveDetails[selectedValveId]?['ward'] ?? '--',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Text('VALVE ID', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            DropdownButtonFormField<String>(
              initialValue: selectedValveId,
              isExpanded: true,
              decoration: const InputDecoration(border: OutlineInputBorder()),
              hint: const Text('Select a valve saved on MAP'),
              items: valveIds.map((id) => DropdownMenuItem(value: id, child: Text(id))).toList(),
              onChanged: valveIds.isEmpty ? null : chooseValve,
            ),
            if (_registryLoading) ...[
              const SizedBox(height: 8),
              const LinearProgressIndicator(),
              const Text('Loading authorized valves…'),
            ],
            if (_registryError != null) ...[
              const SizedBox(height: 8),
              Text('Valve registry unavailable: $_registryError', style: const TextStyle(color: Colors.red)),
              OutlinedButton(onPressed: _loadValveIds, child: const Text('RETRY')),
            ],
            if (!_registryLoading && _registryError == null && valveIds.isEmpty) ...[
              const SizedBox(height: 8),
              const Text('No valves are assigned to this account.'),
            ],
            if (!widget.isLora) ...[
              const SizedBox(height: 12),
              _infoField(
                'AWS COMMUNICATION ID',
                communicationId.isEmpty ? '--' : communicationId,
              ),
            ],
            const SizedBox(height: 12),
            Row(children: [
              const Expanded(child: Text('FW VERSION', style: TextStyle(fontWeight: FontWeight.bold))),
              Flexible(
                child: Text(
                  widget.isLora ? 'LoRa FW 1.0.0' : 'GSM FW 1.0.0',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (!widget.isLora) ...[
                const SizedBox(width: 12),
                OutlinedButton(
                  onPressed: () => send('OTA_UPDATE'),
                  child: const Text('OTA'),
                ),
              ],
            ]),
            if (widget.isLora) ...[
              const SizedBox(height: 8),
              Row(children: [
                const Expanded(child: Text('GWID', style: TextStyle(fontWeight: FontWeight.bold))),
                Text(gwid.isEmpty ? '--' : gwid),
              ]),
            ],
          ]))),
          if (!widget.isLora) _gsmStatusCard() else _loraStatusCard(),
          if (_currentValveHasOcFault) _ocFaultBanner(),
          if (lowVoltageBypass && !widget.isLora) _voltageBypassBanner(),
          _testFaultCard(),
          _positionCard(),
          _calibrationCard(),
          _voltageCard(),
          _currentCard(),
          _scheduleCard(),
          if (widget.isLora) ...[
            const SizedBox(height: 10),
            SizedBox(height: 54, child: FilledButton.tonal(onPressed: rebindOwner, style: FilledButton.styleFrom(foregroundColor: Colors.deepPurple), child: const Text('OWNER REBIND / GW REBIND', style: TextStyle(fontWeight: FontWeight.bold)))),
          ],
        ],
      ),
    );
  }

  bool get _currentValveHasOcFault => ocFault || status.toUpperCase().contains('OC TRIP') || status.toUpperCase().contains('OVERCURRENT');

  Widget _testFaultCard() => Card(
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                widget.isLora ? 'FAULT TEST' : 'FAULT / BYPASS TEST',
                style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () async {
                        setState(() {
                          ocFault = true;
                          status = 'OC TRIP';
                        });
                        final valveId = selectedValveId;
                        if (valveId != null && valveId.isNotEmpty) {
                          await ValveFaultStorage.save(valveId, true);
                        }
                      },
                      child: const Text('TEST OC TRIP'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () async {
                        setState(() {
                          ocFault = false;
                          status = 'STOPPED';
                        });
                        final valveId = selectedValveId;
                        if (valveId != null && valveId.isNotEmpty) {
                          await ValveFaultStorage.save(valveId, false);
                        }
                      },
                      child: const Text('CLEAR OC'),
                    ),
                  ),
                ],
              ),
              if (!widget.isLora) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => setState(() => lowVoltageBypass = true),
                        child: const Text('TEST LOW VOLTAGE'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => setState(() => lowVoltageBypass = false),
                        child: const Text('CANCEL BYPASS'),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      );

  Widget _ocFaultBanner() => Card(
        color: Colors.red.shade50,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(children: [
            Container(width: 18, height: 18, decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle)),
            const SizedBox(width: 10),
            const Expanded(child: Text('OC TRIP / OVER-CURRENT FAULT', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold))),
          ]),
        ),
      );

  Widget _voltageBypassBanner() => Card(
        color: Colors.red.shade50,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(children: [
            Container(width: 18, height: 18, decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle)),
            const SizedBox(width: 10),
            const Expanded(child: Text('VOLTAGE BYPASS ACTIVE', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold))),
          ]),
        ),
      );

  Widget _infoField(String label, String value) => InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          filled: true,
        ),
        child: Text(
          value.isEmpty ? '--' : value,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
      );

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
    Row(
      children: [
        const Expanded(child: Text('LOW-VOLTAGE BYPASS')),
        Text(
          !lowVoltageBypassKnown
              ? 'UNKNOWN'
              : lowVoltageBypass
                  ? 'ACTIVE'
                  : 'INACTIVE',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: !lowVoltageBypassKnown
                ? Colors.grey
                : lowVoltageBypass
                    ? Colors.red
                    : Colors.green,
          ),
        ),
      ],
    ),
    const SizedBox(height: 8),
    Row(
      children: [
        const Expanded(child: Text('ACTUAL VALVE POSITION')),
        Text(
          hasActualPosition
              ? '$actualPosition% • ${_actualValvePositionLabel()}'
              : 'UNKNOWN',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ],
    ),
    const SizedBox(height: 8),
    _statusLine(),
  ])));

  String _actualValvePositionLabel() {
    if (actualPosition <= 0) return 'CLOSED';
    if (actualPosition >= 100) return 'OPEN';
    return 'PARTIALLY OPEN';
  }

  Widget _rssiBars(int level) => Row(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.end, children: List.generate(3, (index) => Container(width: 7, height: 8 + (index * 5), margin: const EdgeInsets.only(left: 3), color: index < level ? Colors.green : Colors.grey.shade300)));

  String get _telemetryState {
    if (_lastTelemetryAt == null) return 'UNKNOWN / NO TELEMETRY';
    if (!_telemetryConnected || DateTime.now().difference(_lastTelemetryAt!) > const Duration(seconds: 90)) return 'OFFLINE / STALE';
    return 'ONLINE';
  }

  Widget _statusLine() => Column(children: [
    Row(children: [const Expanded(child: Text('STATUS')), Text(status, style: const TextStyle(fontWeight: FontWeight.bold))]),
    const SizedBox(height: 6),
    Row(children: [
      const Expanded(child: Text('TELEMETRY')),
      Text(_telemetryState, style: TextStyle(fontWeight: FontWeight.bold, color: _telemetryState == 'ONLINE' ? Colors.green : Colors.red)),
    ]),
    if (_lastTelemetryAt != null)
      Align(alignment: Alignment.centerRight, child: Text('Last update: ${_lastTelemetryAt!.toLocal().toString().substring(0, 19)}', style: Theme.of(context).textTheme.bodySmall)),
  ]);

  Widget _positionCard() => _card('VALVE CONTROL', Column(children: [
    Text('SET POINT: $selectedPosition%', style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
    Slider(value: selectedPosition.toDouble(), min: 0, max: 100, divisions: 100, label: '$selectedPosition%', onChanged: (v) => setState(() => selectedPosition = v.round())),
    Wrap(spacing: 6, alignment: WrapAlignment.center, children: [0, 25, 50, 75, 100].map((v) => ChoiceChip(label: Text('$v%'), selected: selectedPosition == v, onSelected: (_) => setState(() => selectedPosition = v))).toList()),
    const SizedBox(height: 12),
    SizedBox(height: 48, width: double.infinity, child: FilledButton(onPressed: setValve, child: Text('SET % OPEN — $selectedPosition%'))),
    const SizedBox(height: 8),
    Row(children: [Expanded(child: FilledButton(onPressed: () async { final sent = await setValve(); if (sent && mounted) setState(() => status = 'OPENING TO $selectedPosition%'); }, child: const Text('OPEN'))), const SizedBox(width: 8), Expanded(child: FilledButton(onPressed: () async { await send('CLOSE'); setState(() => status = 'CLOSING'); }, child: const Text('CLOSE')))]),
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

  Widget _scheduleCard() => _card('SCHEDULING', Column(children: [
    Row(children: [Expanded(child: _small('VIEW SCHEDULE', () => send('GET_SCHEDULE'))), const SizedBox(width: 8), Expanded(child: _small('START', () => send('SCHEDULE_START')))]),
    const SizedBox(height: 8),
    Row(children: [Expanded(child: _small('SET SCHEDULE', _setSchedule)), const SizedBox(width: 8), Expanded(child: _small('CANCEL ALL', () => send('CLR_SCHEDULE')))]),
    const SizedBox(height: 8),
    SizedBox(width: double.infinity, child: OutlinedButton(onPressed: _setClock, child: const Text('DATE SET'))),
  ]));

  Future<void> _setClock() async {
    DateTime selectedDate = DateTime.now();
    TimeOfDay startTime = TimeOfDay.fromDateTime(DateTime.now());
    TimeOfDay stopTime = const TimeOfDay(hour: 18, minute: 0);

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('DATE SET'),
          content: SingleChildScrollView(
            child: Column(
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
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2099),
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
                  title: const Text('Stop time'),
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
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('CANCEL'),
            ),
            FilledButton(
              onPressed: () async {
                Navigator.pop(dialogContext);
                final dt = DateTime(
                  selectedDate.year,
                  selectedDate.month,
                  selectedDate.day,
                  startTime.hour,
                  startTime.minute,
                );
                await send('SET_TIME', fields: {
                  'year': dt.year,
                  'month': dt.month,
                  'day': dt.day,
                  'hour': dt.hour,
                  'minute': dt.minute,
                  'second': 0,
                  'wday': dt.weekday % 7,
                });
              },
              child: const Text('SAVE'),
            ),
          ],
        ),
      ),
    );
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

  Widget _small(String text, Future<void> Function() onPressed) => SizedBox(
        height: 46,
        child: OutlinedButton(
          onPressed: () => onPressed(),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            visualDensity: VisualDensity.compact,
          ),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              text,
              maxLines: 1,
              style: const TextStyle(fontSize: 13),
            ),
          ),
        ),
      );
}
