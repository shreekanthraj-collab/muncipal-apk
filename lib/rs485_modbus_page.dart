import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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

  @override
  void initState() {
    super.initState();
    SystemChrome.setPreferredOrientations(const [
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
  }

  @override
  void dispose() {
    SystemChrome.setPreferredOrientations(const [
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    super.dispose();
  }

  Future<void> _scan() async {
    setState(() => scanning = true);
    await Future<void>.delayed(const Duration(milliseconds: 700));
    if (!mounted) return;
    setState(() {
      scanning = false;
      lastScan = DateTime.now();
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('RS485 scan completed — 5 configured devices found.'),
      ),
    );
  }

  void _showAddDevice() {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('ADD MODBUS DEVICE'),
        content: const Text(
          'Enter the device Slave ID, manufacturer, model and driver information here. The selected slot will be configured after confirmation.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CANCEL'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CONTINUE'),
          ),
        ],
      ),
    );
  }

  void _showConfig(_Rs485Device device, int slot) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'SLOT $slot — ${device.name}',
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 14),
              Text('Slave ID: ${device.slaveId}'),
              Text('Model: ${device.model}'),
              Text('Current value: ${device.value}'),
              const SizedBox(height: 18),
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

  void _openDriverFlow() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const _DriverSearchPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _TopSelectionCard(
              zone: zone,
              ward: ward,
              valve: valve,
              onZoneChanged: (v) => setState(() => zone = v),
              onWardChanged: (v) => setState(() => ward = v),
              onValveChanged: (v) => setState(() => valve = v),
              onAddValve: () => ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Add Valve is available from the valve management flow.'),
                ),
              ),
            ),
            const SizedBox(height: 14),
            _BusStatusCard(
              deviceCount: devices.where((d) => d.online != null).length,
              lastScan: lastScan,
            ),
            const SizedBox(height: 14),
            _SectionCard(
              title: 'DEVICE SLOTS (8)',
              trailing: const Text(
                'Modbus RTU',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
              ),
              child: Column(
                children: List.generate(devices.length, (i) {
                  final device = devices[i];
                  return Padding(
                    padding: EdgeInsets.only(
                      bottom: i == devices.length - 1 ? 0 : 10,
                    ),
                    child: _DeviceSlotCard(
                      slot: i + 1,
                      device: device,
                      onPressed: () => _showConfig(device, i + 1),
                    ),
                  );
                }),
              ),
            ),
            const SizedBox(height: 14),
            _ActionSection(
              scanning: scanning,
              onScan: scanning ? null : _scan,
              onAdd: _showAddDevice,
            ),
            const SizedBox(height: 14),
            _SectionCard(
              title: 'DRIVER MANAGEMENT',
              child: Column(
                children: [
                  _DriverTile(
                    icon: Icons.manage_search,
                    title: 'SEARCH DRIVERS',
                    subtitle: 'Find compatible drivers',
                    onTap: _openDriverFlow,
                  ),
                  const SizedBox(height: 8),
                  _DriverTile(
                    icon: Icons.list_alt,
                    title: 'CANDIDATE DRIVERS',
                    subtitle: 'View matching drivers',
                    onTap: _openDriverFlow,
                  ),
                  const SizedBox(height: 8),
                  _DriverTile(
                    icon: Icons.download_for_offline_outlined,
                    title: 'INSTALL DRIVER',
                    subtitle: 'Configure & install',
                    onTap: _openDriverFlow,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Icon(Icons.info_outline),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Supports Modbus RTU devices — flow sensors, level sensors, water quality, meters, and other compatible devices.',
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TopSelectionCard extends StatelessWidget {
  final String zone;
  final String ward;
  final String valve;
  final ValueChanged<String> onZoneChanged;
  final ValueChanged<String> onWardChanged;
  final ValueChanged<String> onValveChanged;
  final VoidCallback onAddValve;

  const _TopSelectionCard({
    required this.zone,
    required this.ward,
    required this.valve,
    required this.onZoneChanged,
    required this.onWardChanged,
    required this.onValveChanged,
    required this.onAddValve,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: _DropdownField(
                    label: 'ZONE NO',
                    value: zone,
                    values: const ['1', '2', '3', '4', '5'],
                    onChanged: onZoneChanged,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _DropdownField(
                    label: 'WARD NO',
                    value: ward,
                    values: const ['1', '2', '3', '4', '5'],
                    onChanged: onWardChanged,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _DropdownField(
              label: 'VALVE ID (GSM + LoRa)',
              value: valve,
              values: const [
                'ORBI-VALVE-001',
                'ORBI-VALVE-002',
                'ORBI-VALVE-003',
              ],
              onChanged: onValveChanged,
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: 52,
              child: FilledButton.icon(
                onPressed: onAddValve,
                icon: const Icon(Icons.add),
                label: const Text('ADD VALVE'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DropdownField extends StatelessWidget {
  final String label;
  final String value;
  final List<String> values;
  final ValueChanged<String> onChanged;

  const _DropdownField({
    required this.label,
    required this.value,
    required this.values,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      initialValue: value,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
      items: values
          .map(
            (v) => DropdownMenuItem<String>(
              value: v,
              child: Text(v, overflow: TextOverflow.ellipsis),
            ),
          )
          .toList(),
      onChanged: (v) {
        if (v != null) onChanged(v);
      },
    );
  }
}

class _BusStatusCard extends StatelessWidget {
  final int deviceCount;
  final DateTime? lastScan;

  const _BusStatusCard({required this.deviceCount, required this.lastScan});

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: 'RS485 BUS STATUS',
      trailing: const Chip(
        visualDensity: VisualDensity.compact,
        avatar: Icon(Icons.circle, size: 9),
        label: Text('ONLINE'),
      ),
      child: Column(
        children: [
          _Metric(
            icon: Icons.speed,
            label: 'BAUD RATE',
            value: '9600',
          ),
          const Divider(height: 20),
          _Metric(
            icon: Icons.hub_outlined,
            label: 'DEVICES FOUND',
            value: '$deviceCount / 8',
          ),
          const Divider(height: 20),
          _Metric(
            icon: Icons.schedule,
            label: 'LAST SCAN',
            value: lastScan == null ? '--' : _format(lastScan!),
          ),
        ],
      ),
    );
  }

  static String _format(DateTime t) {
    return '${t.day.toString().padLeft(2, '0')}/${t.month.toString().padLeft(2, '0')} ${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
  }
}

class _Metric extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _Metric({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 30),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _DeviceSlotCard extends StatelessWidget {
  final int slot;
  final _Rs485Device device;
  final VoidCallback onPressed;

  const _DeviceSlotCard({
    required this.slot,
    required this.device,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final empty = device.online == null;
    final status = empty ? 'EMPTY' : (device.online! ? 'ONLINE' : 'OFFLINE');

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.black12),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      color: Theme.of(context).colorScheme.surfaceContainerHighest,
                    ),
                    child: Text(
                      '$slot',
                      style: const TextStyle(fontWeight: FontWeight.w900),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Icon(device.icon, size: 28),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      device.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Chip(
                    visualDensity: VisualDensity.compact,
                    label: Text(status),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                'Slave ID: ${device.slaveId}   •   Model: ${device.model}',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Colors.grey, fontSize: 12),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  const Text('VALUE', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      device.value,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
                    ),
                  ),
                  TextButton.icon(
                    onPressed: onPressed,
                    icon: Icon(empty ? Icons.add : Icons.settings_outlined, size: 18),
                    label: Text(empty ? 'ADD' : 'CONFIG'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActionSection extends StatelessWidget {
  final bool scanning;
  final VoidCallback? onScan;
  final VoidCallback onAdd;

  const _ActionSection({
    required this.scanning,
    required this.onScan,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: 56,
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: onScan,
            icon: const Icon(Icons.search),
            label: Text(scanning ? 'SCANNING…' : 'SCAN FOR DEVICES'),
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 56,
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: onAdd,
            icon: const Icon(Icons.add),
            label: const Text('ADD DEVICE MANUALLY'),
          ),
        ),
      ],
    );
  }
}

class _DriverTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _DriverTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.black12),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Icon(icon, size: 30),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.w900)),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 11),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right),
          ],
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final Widget child;
  final Widget? trailing;

  const _SectionCard({
    required this.title,
    required this.child,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w900),
                  ),
                ),
                if (trailing != null) ...[
                  const SizedBox(width: 8),
                  Flexible(child: trailing!),
                ],
              ],
            ),
            const SizedBox(height: 14),
            child,
          ],
        ),
      ),
    );
  }
}

class _Rs485Device {
  final String name;
  final String slaveId;
  final String model;
  final String value;
  final bool? online;

  const _Rs485Device(
    this.name,
    this.slaveId,
    this.model,
    this.value,
    this.online,
  );

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
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('DRIVER DISCOVERY')),
      body: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          const _SectionCard(
            title: 'NEW DEVICE FOUND',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'ABC FLOW-X100',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
                ),
                SizedBox(height: 8),
                Text('Manufacturer: ABC'),
                Text('Model: FLOW-X100'),
                Text('Device ID: ABC123456'),
                Text('Slave ID: 3'),
              ],
            ),
          ),
          const SizedBox(height: 14),
          const _SectionCard(
            title: 'CANDIDATE DRIVERS',
            child: Column(
              children: [
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(Icons.memory),
                  title: Text('ABC FLOW-X100'),
                  subtitle: Text('v1.0.0 • Function 03 • 98% match'),
                  trailing: Icon(Icons.chevron_right),
                ),
                Divider(),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(Icons.memory),
                  title: Text('ABC FLOW-X100 Legacy'),
                  subtitle: Text('v0.9.2 • Function 03 • 84% match'),
                  trailing: Icon(Icons.chevron_right),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: () => showDialog<void>(
                context: context,
                builder: (c) => AlertDialog(
                  title: const Text('INSTALL DRIVER'),
                  content: const Text(
                    'Driver installation will send the selected driver configuration to the valve node when the node/backend transport is connected.',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(c),
                      child: const Text('OK'),
                    ),
                  ],
                ),
              ),
              icon: const Icon(Icons.download),
              label: const Text('INSTALL DRIVER'),
            ),
          ),
        ],
      ),
    );
  }
}
