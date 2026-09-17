import 'package:flutter/material.dart';

class Rs485ModbusPage extends StatefulWidget {
  const Rs485ModbusPage({super.key});

  @override
  State<Rs485ModbusPage> createState() => _Rs485ModbusPageState();
}

class _Rs485ModbusPageState extends State<Rs485ModbusPage> {
  String zone = '1';
  String ward = '3';
  String valve = 'ORBI-VALVE-001';
  bool scanning = false;
  DateTime? lastScan;

  final List<_Rs485Device> devices = [
    _Rs485Device('Flow Sensor 1', '1', 'FS-100', '12.5 FL/sec', true),
    _Rs485Device('Flow Sensor 2', '2', 'FS-100', '10.8 FL/sec', true),
    _Rs485Device('Overflow Tank', '3', 'LT-200', '75 %', true),
    _Rs485Device('Water Quality Sensor', '4', 'WQ-300', 'pH 7.2', true),
    _Rs485Device('Energy Meter', '5', 'EM-500', '230 V', false),
    _Rs485Device('Pressure Sensor', '6', '--', '--', null),
    _Rs485Device('Temperature', '7', '--', '--', null),
    _Rs485Device('Custom Device', '8', '--', '--', null),
  ];

  Future<void> _scan() async {
    setState(() => scanning = true);
    await Future<void>.delayed(const Duration(milliseconds: 700));
    if (!mounted) return;
    setState(() {
      scanning = false;
      lastScan = DateTime.now();
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('RS485 scan completed — 5 configured devices found.')),
    );
  }

  void _showAddDevice() {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('ADD MODBUS DEVICE'),
        content: const Text('Enter the device Slave ID, manufacturer, model and driver information here. The selected slot will be configured after confirmation.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('CANCEL')),
          FilledButton(onPressed: () => Navigator.pop(context), child: const Text('CONTINUE')),
        ],
      ),
    );
  }

  void _showConfig(_Rs485Device device, int slot) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Text('SLOT $slot — ${device.name}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
            const SizedBox(height: 14),
            Text('Slave ID: ${device.slaveId}'),
            Text('Model: ${device.model}'),
            Text('Current value: ${device.value}'),
            const SizedBox(height: 18),
            FilledButton.icon(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.save_outlined), label: const Text('SAVE CONFIGURATION')),
          ]),
        ),
      ),
    );
  }

  void _openDriverFlow() {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => const _DriverSearchPage()));
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 24),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        _TopSelectionCard(
          zone: zone,
          ward: ward,
          valve: valve,
          onZoneChanged: (v) => setState(() => zone = v),
          onWardChanged: (v) => setState(() => ward = v),
          onValveChanged: (v) => setState(() => valve = v),
          onAddValve: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Add Valve is available from the valve management flow.'))),
        ),
        const SizedBox(height: 14),
        _BusStatusCard(deviceCount: devices.where((d) => d.online != null).length, lastScan: lastScan),
        const SizedBox(height: 14),
        _SectionCard(
          title: 'DEVICE SLOTS (8)',
          trailing: const Text('Modbus RTU', style: TextStyle(fontWeight: FontWeight.w700)),
          child: Column(children: List.generate(devices.length, (i) {
            final d = devices[i];
            return Padding(
              padding: EdgeInsets.only(bottom: i == devices.length - 1 ? 0 : 8),
              child: _DeviceSlotCard(slot: i + 1, device: d, onPressed: () => _showConfig(d, i + 1)),
            );
          })),
        ),
        const SizedBox(height: 14),
        Row(children: [
          Expanded(child: _LargeActionButton(icon: Icons.search, title: scanning ? 'SCANNING…' : 'SCAN FOR DEVICES', subtitle: 'Search new Modbus devices', filled: true, onPressed: scanning ? null : _scan)),
          const SizedBox(width: 10),
          Expanded(child: _LargeActionButton(icon: Icons.add, title: 'ADD DEVICE MANUALLY', subtitle: 'Enter device details', onPressed: _showAddDevice)),
        ]),
        const SizedBox(height: 14),
        _SectionCard(
          title: 'DRIVER MANAGEMENT',
          child: Row(children: [
            Expanded(child: _DriverTile(icon: Icons.manage_search, title: 'SEARCH DRIVERS', subtitle: 'Find compatible drivers', onTap: _openDriverFlow)),
            const SizedBox(width: 8),
            Expanded(child: _DriverTile(icon: Icons.list_alt, title: 'CANDIDATE DRIVERS', subtitle: 'View matching drivers', onTap: _openDriverFlow)),
            const SizedBox(width: 8),
            Expanded(child: _DriverTile(icon: Icons.download_for_offline_outlined, title: 'INSTALL DRIVER', subtitle: 'Configure & install', onTap: _openDriverFlow)),
          ]),
        ),
        const SizedBox(height: 14),
        Card(child: Padding(padding: const EdgeInsets.all(14), child: Row(children: const [Icon(Icons.info_outline), SizedBox(width: 10), Expanded(child: Text('Supports Modbus RTU devices — flow sensors, level sensors, water quality, meters, and other compatible devices.'))]))),
      ]),
    );
  }
}

class _TopSelectionCard extends StatelessWidget {
  final String zone, ward, valve;
  final ValueChanged<String> onZoneChanged, onWardChanged, onValveChanged;
  final VoidCallback onAddValve;
  const _TopSelectionCard({required this.zone, required this.ward, required this.valve, required this.onZoneChanged, required this.onWardChanged, required this.onValveChanged, required this.onAddValve});

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Row(children: [
        Expanded(child: _DropdownField(label: 'ZONE NO', value: zone, values: const ['1','2','3','4','5'], onChanged: onZoneChanged)),
        const SizedBox(width: 10),
        Expanded(child: _DropdownField(label: 'WARD NO', value: ward, values: const ['1','2','3','4','5'], onChanged: onWardChanged)),
      ]),
      const SizedBox(height: 12),
      Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
        Expanded(child: _DropdownField(label: 'VALVE ID (GSM + LoRa)', value: valve, values: const ['ORBI-VALVE-001','ORBI-VALVE-002','ORBI-VALVE-003'], onChanged: onValveChanged)),
        const SizedBox(width: 10),
        FilledButton.icon(onPressed: onAddValve, icon: const Icon(Icons.add), label: const Text('ADD VALVE')),
      ]),
    ]),
  );
}

class _DropdownField extends StatelessWidget {
  final String label, value;
  final List<String> values;
  final ValueChanged<String> onChanged;
  const _DropdownField({required this.label, required this.value, required this.values, required this.onChanged});
  @override
  Widget build(BuildContext context) => DropdownButtonFormField<String>(
    value: value,
    decoration: InputDecoration(labelText: label, border: const OutlineInputBorder()),
    items: values.map((v) => DropdownMenuItem(value: v, child: Text(v))).toList(),
    onChanged: (v) { if (v != null) onChanged(v); },
  );
}

class _BusStatusCard extends StatelessWidget {
  final int deviceCount;
  final DateTime? lastScan;
  const _BusStatusCard({required this.deviceCount, required this.lastScan});
  @override
  Widget build(BuildContext context) => _SectionCard(
    title: 'RS485 BUS STATUS',
    trailing: const Chip(avatar: Icon(Icons.circle, size: 10), label: Text('ONLINE')),
    child: Row(children: [
      Expanded(child: _Metric(icon: Icons.speed, label: 'BAUD RATE', value: '9600')),
      Expanded(child: _Metric(icon: Icons.hub_outlined, label: 'DEVICES FOUND', value: '$deviceCount / 8')),
      Expanded(child: _Metric(icon: Icons.schedule, label: 'LAST SCAN', value: lastScan == null ? '--' : _format(lastScan!))),
    ]),
  );

  static String _format(DateTime t) => '${t.day.toString().padLeft(2,'0')}/${t.month.toString().padLeft(2,'0')} ${t.hour.toString().padLeft(2,'0')}:${t.minute.toString().padLeft(2,'0')}';
}

class _Metric extends StatelessWidget {
  final IconData icon; final String label, value;
  const _Metric({required this.icon, required this.label, required this.value});
  @override
  Widget build(BuildContext context) => Padding(padding: const EdgeInsets.symmetric(horizontal: 8), child: Row(children: [Icon(icon, size: 30), const SizedBox(width: 10), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700)), Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900))]))]));
}

class _DeviceSlotCard extends StatelessWidget {
  final int slot; final _Rs485Device device; final VoidCallback onPressed;
  const _DeviceSlotCard({required this.slot, required this.device, required this.onPressed});
  @override
  Widget build(BuildContext context) {
    final empty = device.online == null;
    return InkWell(onTap: onPressed, borderRadius: BorderRadius.circular(14), child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(border: Border.all(color: Colors.black12), borderRadius: BorderRadius.circular(14)),
      child: Row(children: [
        SizedBox(width: 34, child: Text('$slot', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900))),
        Icon(device.icon, size: 28),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(device.name, style: const TextStyle(fontWeight: FontWeight.w900)), Text('ID: ${device.slaveId}  |  Model: ${device.model}', style: const TextStyle(color: Colors.grey, fontSize: 12))])),
        SizedBox(width: 92, child: Text(device.value, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.w800))),
        Chip(label: Text(empty ? 'EMPTY' : (device.online! ? 'ONLINE' : 'OFFLINE'))),
        const SizedBox(width: 6),
        TextButton.icon(onPressed: onPressed, icon: Icon(empty ? Icons.add : Icons.settings_outlined, size: 18), label: Text(empty ? 'ADD' : 'CONFIG')),
        const Icon(Icons.chevron_right),
      ]),
    ));
  }
}

class _LargeActionButton extends StatelessWidget {
  final IconData icon; final String title, subtitle; final bool filled; final VoidCallback? onPressed;
  const _LargeActionButton({required this.icon, required this.title, required this.subtitle, this.filled = false, required this.onPressed});
  @override
  Widget build(BuildContext context) => SizedBox(height: 72, child: filled
    ? FilledButton.icon(onPressed: onPressed, icon: Icon(icon, size: 32), label: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(fontWeight: FontWeight.w900)), Text(subtitle, style: const TextStyle(fontSize: 11))]))
    : OutlinedButton.icon(onPressed: onPressed, icon: Icon(icon, size: 30), label: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(fontWeight: FontWeight.w900)), Text(subtitle, style: const TextStyle(fontSize: 11))])));
}

class _DriverTile extends StatelessWidget {
  final IconData icon; final String title, subtitle; final VoidCallback onTap;
  const _DriverTile({required this.icon, required this.title, required this.subtitle, required this.onTap});
  @override
  Widget build(BuildContext context) => Expanded(child: InkWell(onTap: onTap, borderRadius: BorderRadius.circular(14), child: Container(padding: const EdgeInsets.all(14), decoration: BoxDecoration(border: Border.all(color: Colors.black12), borderRadius: BorderRadius.circular(14)), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Icon(icon, size: 30), const SizedBox(height: 8), Text(title, style: const TextStyle(fontWeight: FontWeight.w900)), Text(subtitle, style: const TextStyle(fontSize: 11))])));
}

class _SectionCard extends StatelessWidget {
  final String title; final Widget child; final Widget? trailing;
  const _SectionCard({required this.title, required this.child, this.trailing});
  @override
  Widget build(BuildContext context) => Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(title, style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w900)), if (trailing != null) trailing!]), const SizedBox(height: 14), child])));
}

class _Rs485Device {
  final String name, slaveId, model, value;
  final bool? online;
  const _Rs485Device(this.name, this.slaveId, this.model, this.value, this.online);
  IconData get icon {
    if (name.contains('Flow')) return Icons.water_drop_outlined;
    if (name.contains('Overflow')) return Icons.water_damage_outlined;
    if (name.contains('Quality')) return Icons.science_outlined;
    if (name.contains('Energy')) return Icons.bolt_outlined;
    if (name.contains('Pressure')) return Icons.speed;
    if (name.contains('Temperature')) return Icons.thermostat_outlined;
    return Icons.devices_other_outlined;
  }
}

class _DriverSearchPage extends StatelessWidget {
  const _DriverSearchPage();
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('DRIVER DISCOVERY')),
    body: ListView(padding: const EdgeInsets.all(18), children: [
      const _SectionCard(title: 'NEW DEVICE FOUND', child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('ABC FLOW-X100', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900)), SizedBox(height: 8), Text('Manufacturer: ABC'), Text('Model: FLOW-X100'), Text('Device ID: ABC123456'), Text('Slave ID: 3')])),
      const SizedBox(height: 14),
      const _SectionCard(title: 'CANDIDATE DRIVERS', child: Column(children: [
        ListTile(leading: Icon(Icons.memory), title: Text('ABC FLOW-X100'), subtitle: Text('v1.0.0 • Function 03 • 98% match'), trailing: Icon(Icons.chevron_right)),
        Divider(),
        ListTile(leading: Icon(Icons.memory), title: Text('ABC FLOW-X100 Legacy'), subtitle: Text('v0.9.2 • Function 03 • 84% match'), trailing: Icon(Icons.chevron_right)),
      ])),
      const SizedBox(height: 14),
      FilledButton.icon(onPressed: () => showDialog<void>(context: context, builder: (c) => AlertDialog(title: const Text('INSTALL DRIVER'), content: const Text('Driver installation will send the selected driver configuration to the valve node when the node/backend transport is connected.'), actions: [TextButton(onPressed: () => Navigator.pop(c), child: const Text('OK'))])), icon: const Icon(Icons.download), label: const Text('INSTALL DRIVER')),
    ],
  );
}
