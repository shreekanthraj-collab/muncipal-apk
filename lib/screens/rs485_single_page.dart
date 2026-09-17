import 'package:flutter/material.dart';

class Rs485SinglePage extends StatefulWidget {
  const Rs485SinglePage({super.key});

  @override
  State<Rs485SinglePage> createState() => _Rs485SinglePageState();
}

class _Rs485SinglePageState extends State<Rs485SinglePage> {
  String zone = 'Zone 01';
  String ward = 'Ward 01';
  String valve = 'GSM-001';
  bool scanning = false;
  DateTime? lastScan;

  final List<_Device> devices = [
    _Device('Flow Sensor 1', '1', 'FS-100', '12.5 FL/sec', true),
    _Device('Flow Sensor 2', '2', 'FS-100', '10.8 FL/sec', true),
    _Device('Overflow Tank', '3', 'LT-200', '75 %', true),
    _Device('Water Quality Sensor', '4', 'WQ-300', 'pH 7.2', true),
    _Device('Energy Meter', '5', 'EM-500', '230 V', false),
    _Device('Pressure Sensor', '6', 'PS-100', '--', null),
    _Device('Temperature', '7', 'TT-100', '--', null),
    _Device('Custom Device', '8', '--', '--', null),
  ];

  Future<void> scan() async {
    setState(() => scanning = true);
    await Future<void>.delayed(const Duration(milliseconds: 700));
    if (!mounted) return;
    setState(() {
      scanning = false;
      lastScan = DateTime.now();
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('RS485 scan completed.')),
    );
  }

  void addDevice() {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('ADD MODBUS DEVICE'),
        content: const Text(
          'Enter Slave ID, manufacturer, model and driver information for the selected slot.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('CANCEL')),
          FilledButton(onPressed: () => Navigator.pop(context), child: const Text('CONTINUE')),
        ],
      ),
    );
  }

  void configure(_Device device, int slot) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('SLOT $slot — ${device.name}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
              const SizedBox(height: 12),
              Text('Slave ID: ${device.slaveId}'),
              Text('Model: ${device.model}'),
              Text('Current value: ${device.value}'),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.save_outlined),
                label: const Text('SAVE CONFIGURATION'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void openDrivers() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const _DriverFlow()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('RS485 / MODBUS'),
        centerTitle: true,
        actions: [
          IconButton(onPressed: scan, tooltip: 'SCAN', icon: const Icon(Icons.refresh)),
          IconButton(onPressed: () {}, tooltip: 'SETTINGS', icon: const Icon(Icons.settings_outlined)),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  Expanded(child: _drop('Zone No', zone, const ['Zone 01', 'Zone 02', 'Zone 03'], (v) => setState(() => zone = v))),
                  const SizedBox(width: 8),
                  Expanded(child: _drop('Ward No', ward, const ['Ward 01', 'Ward 02', 'Ward 03'], (v) => setState(() => ward = v))),
                  const SizedBox(width: 8),
                  Expanded(child: _drop('VALVE ID (GSM + LoRa)', valve, const ['GSM-001', 'GSM-002', 'LoRa-001', 'LoRa-002'], (v) => setState(() => valve = v))),
                  const SizedBox(width: 8),
                  FilledButton.icon(onPressed: () {}, icon: const Icon(Icons.add), label: const Text('ADD VALVE')),
                ],
              ),
            ),
          ),
          _section(
            'RS485 BUS STATUS',
            Row(children: [
              Expanded(child: _metric(Icons.memory, 'Baud Rate', '9600')),
              Expanded(child: _metric(Icons.hub_outlined, 'Devices Found', '${devices.where((d) => d.online != null).length} / 8')),
              Expanded(child: _metric(Icons.schedule, 'Last Scan', lastScan == null ? '--' : _format(lastScan!))),
              const Chip(avatar: Icon(Icons.circle, size: 10), label: Text('ONLINE')),
            ]),
          ),
          _section(
            'DEVICE SLOTS (8)',
            Column(
              children: List.generate(devices.length, (i) {
                final d = devices[i];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 7),
                  child: _deviceTile(i + 1, d),
                );
              }),
            ),
          ),
          Row(children: [
            Expanded(child: FilledButton.icon(onPressed: scanning ? null : scan, icon: const Icon(Icons.search), label: Text(scanning ? 'SCANNING…' : 'SCAN FOR DEVICES'))),
            const SizedBox(width: 8),
            Expanded(child: OutlinedButton.icon(onPressed: addDevice, icon: const Icon(Icons.add), label: const Text('ADD DEVICE MANUALLY'))),
          ]),
          _section(
            'DRIVER MANAGEMENT',
            Row(children: [
              Expanded(child: _driver('SEARCH DRIVERS', 'Find compatible drivers', Icons.manage_search)),
              const SizedBox(width: 8),
              Expanded(child: _driver('CANDIDATE DRIVERS', 'View matching drivers', Icons.list_alt)),
              const SizedBox(width: 8),
              Expanded(child: _driver('INSTALL DRIVER', 'Configure & install', Icons.download_outlined)),
            ]),
          ),
          Card(
            child: const Padding(
              padding: EdgeInsets.all(14),
              child: Row(children: [Icon(Icons.info_outline), SizedBox(width: 10), Expanded(child: Text('Supports Modbus RTU devices — flow sensors, level sensors, water quality, meters, and other compatible devices.'))]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _drop(String label, String value, List<String> values, ValueChanged<String> onChanged) {
    return DropdownButtonFormField<String>(
      initialValue: value,
      isExpanded: true,
      decoration: InputDecoration(labelText: label, border: const OutlineInputBorder()),
      items: values.map((v) => DropdownMenuItem(value: v, child: Text(v))).toList(),
      onChanged: (v) { if (v != null) onChanged(v); },
    );
  }

  Widget _section(String title, Widget child) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
          const SizedBox(height: 12),
          child,
        ]),
      ),
    );
  }

  Widget _metric(IconData icon, String label, String value) => Expanded(
        child: Row(children: [
          Icon(icon, size: 30),
          const SizedBox(width: 8),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700)), Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900))])),
        ]),
      );

  Widget _deviceTile(int slot, _Device d) {
    final status = d.online == null ? 'EMPTY' : (d.online! ? 'ONLINE' : 'OFFLINE');
    return InkWell(
      onTap: () => configure(d, slot),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
        decoration: BoxDecoration(border: Border.all(color: Colors.black12), borderRadius: BorderRadius.circular(12)),
        child: Row(children: [
          SizedBox(width: 28, child: Text('$slot', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900))),
          Icon(_icon(d.name), size: 27),
          const SizedBox(width: 10),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(d.name, style: const TextStyle(fontWeight: FontWeight.w900)), Text('ID: ${d.slaveId}  |  Model: ${d.model}', style: const TextStyle(fontSize: 12, color: Colors.grey))])),
          SizedBox(width: 90, child: Text(d.value, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.w800))),
          Chip(label: Text(status)),
          const SizedBox(width: 4),
          TextButton.icon(onPressed: () => configure(d, slot), icon: Icon(status == 'EMPTY' ? Icons.add : Icons.settings_outlined, size: 17), label: Text(status == 'EMPTY' ? 'ADD' : 'CONFIG')),
          const Icon(Icons.chevron_right),
        ]),
      ),
    );
  }

  Widget _driver(String title, String subtitle, IconData icon) => InkWell(
        onTap: openDrivers,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(13),
          decoration: BoxDecoration(border: Border.all(color: Colors.black12), borderRadius: BorderRadius.circular(12)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Icon(icon, size: 30), const SizedBox(height: 8), Text(title, style: const TextStyle(fontWeight: FontWeight.w900)), Text(subtitle, style: const TextStyle(fontSize: 11))]),
        ),
      );

  static IconData _icon(String name) {
    if (name.contains('Flow')) return Icons.water_drop_outlined;
    if (name.contains('Overflow')) return Icons.water_damage_outlined;
    if (name.contains('Quality')) return Icons.science_outlined;
    if (name.contains('Energy')) return Icons.bolt_outlined;
    if (name.contains('Pressure')) return Icons.speed;
    if (name.contains('Temperature')) return Icons.thermostat_outlined;
    return Icons.devices_other_outlined;
  }

  static String _format(DateTime t) => '${t.day.toString().padLeft(2, '0')}/${t.month.toString().padLeft(2, '0')} ${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
}

class _Device {
  _Device(this.name, this.slaveId, this.model, this.value, this.online);
  final String name;
  final String slaveId;
  final String model;
  final String value;
  final bool? online;
}

class _DriverFlow extends StatelessWidget {
  const _DriverFlow();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('DRIVER DISCOVERY')),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        Card(child: const ListTile(title: Text('NEW DEVICE FOUND', style: TextStyle(fontWeight: FontWeight.w900)), subtitle: Text('ABC FLOW-X100\nManufacturer: ABC\nModel: FLOW-X100\nDevice ID: ABC123456\nSlave ID: 3'))),
        const SizedBox(height: 10),
        Card(child: Column(children: [
          const ListTile(title: Text('CANDIDATE DRIVERS', style: TextStyle(fontWeight: FontWeight.w900))),
          ListTile(leading: const Icon(Icons.memory), title: const Text('ABC FLOW-X100'), subtitle: const Text('v1.0.0 • Function 03 • 98% match'), onTap: () {}),
          const Divider(height: 1),
          ListTile(leading: const Icon(Icons.memory), title: const Text('ABC FLOW-X100 Legacy'), subtitle: const Text('v0.9.2 • Function 03 • 84% match'), onTap: () {}),
        ])),
        const SizedBox(height: 10),
        FilledButton.icon(
          onPressed: () => showDialog<void>(context: context, builder: (c) => AlertDialog(title: const Text('INSTALL DRIVER'), content: const Text('Selected driver is ready for node installation when backend transport is connected.'), actions: [TextButton(onPressed: () => Navigator.pop(c), child: const Text('OK'))])),
          icon: const Icon(Icons.download),
          label: const Text('INSTALL DRIVER'),
        ),
      ]),
    );
  }
}
