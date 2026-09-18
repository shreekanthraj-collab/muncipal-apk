import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import 'services/valve_storage.dart';

class Rs485ModbusPage extends StatefulWidget {
  const Rs485ModbusPage({super.key});

  @override
  State<Rs485ModbusPage> createState() => _Rs485ModbusPageState();
}

class _Rs485ModbusPageState extends State<Rs485ModbusPage> {
  String valve = '';
  Map<String, Map<String, String>> valveDetails = const {};

  bool scanning = false;
  DateTime? lastScan;
  List<String> valveIds = const [];

  final List<_Rs485Device> devices = const [
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
    _loadValveIds();
  }

  @override
  void dispose() {
    SystemChrome.setPreferredOrientations(const [
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    super.dispose();
  }

  Future<void> _loadValveIds() async {
    final details = await ValveStorage.loadValveDetails();
    final ids = details.keys.toList();
    if (!mounted) return;
    setState(() {
      valveDetails = details;
      valveIds = ids;
      valve = ids.isEmpty ? '' : (ids.contains(valve) ? valve : ids.first);
    });
  }

  Future<void> _scan() async {
    if (scanning) return;
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

  Future<void> _openDriverSearch({String? model}) async {
    final query = Uri.encodeQueryComponent(
      'Modbus RTU ${model ?? 'device'} driver manufacturer model',
    );
    final uri = Uri.parse('https://www.google.com/search?q=$query');
    final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!launched && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to open the browser for driver search.')),
      );
    }
  }

  void _openDriverFlow() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => _DriverSearchPage(
          model: devices.firstWhere((d) => d.online == true).model,
          onSearch: _openDriverSearch,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _TopSelectionCard(
              valve: valve,
              valveIds: valveIds,
              valveDetails: valveDetails,
              onValveChanged: (v) => setState(() => valve = v),
            ),
            const SizedBox(height: 12),
            _BusStatusCard(
              deviceCount: devices.where((d) => d.online != null).length,
              lastScan: lastScan,
            ),
            const SizedBox(height: 12),
            _SectionCard(
              title: 'DEVICE SLOTS (8)',
              trailing: 'Modbus RTU',
              child: Column(
                children: List.generate(devices.length, (i) {
                  return Padding(
                    padding: EdgeInsets.only(
                      bottom: i == devices.length - 1 ? 0 : 10,
                    ),
                    child: _DeviceSlotCard(
                      slot: i + 1,
                      device: devices[i],
                      onPressed: () => _showConfig(devices[i], i + 1),
                    ),
                  );
                }),
              ),
            ),
            const SizedBox(height: 12),
            _ActionSection(
              scanning: scanning,
              onScan: _scan,
              onAdd: _showAddDevice,
            ),
            const SizedBox(height: 12),
            _SectionCard(
              title: 'DRIVER MANAGEMENT',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _DriverTile(
                    icon: Icons.manage_search,
                    title: 'SEARCH DRIVERS',
                    subtitle: 'Open Chrome / default browser',
                    onTap: () => _openDriverSearch(model: devices.first.model),
                  ),
                  const SizedBox(height: 8),
                  _DriverTile(
                    icon: Icons.list_alt,
                    title: 'CANDIDATE DRIVERS',
                    subtitle: 'View matching drivers in discovery',
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
            const SizedBox(height: 12),
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
  final String valve;
  final List<String> valveIds;
  final Map<String, Map<String, String>> valveDetails;
  final ValueChanged<String> onValveChanged;

  const _TopSelectionCard({
    required this.valve,
    required this.valveIds,
    required this.valveDetails,
    required this.onValveChanged,
  });

  @override
  Widget build(BuildContext context) {
    final details = valveDetails[valve];
    final zone = details?['zone'] ?? '--';
    final ward = details?['ward'] ?? '--';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(child: _InfoField(label: 'ZONE NO', value: zone)),
                const SizedBox(width: 10),
                Expanded(child: _InfoField(label: 'WARD NO', value: ward)),
              ],
            ),
            const SizedBox(height: 12),
            _DropdownField(
              label: 'VALVE ID (MAP SAVED)',
              value: valve,
              values: valveIds,
              onChanged: onValveChanged,
            ),
            if (valveIds.isEmpty) ...[
              const SizedBox(height: 8),
              const Text(
                'No valves saved on MAP. Add the valve from MAP VIEW first.',
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _InfoField extends StatelessWidget {
  final String label;
  final String value;

  const _InfoField({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return InputDecorator(
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
      initialValue: values.contains(value) ? value : null,
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
      trailing: 'ONLINE',
      child: Column(
        children: [
          _Metric(icon: Icons.speed, label: 'BAUD RATE', value: '9600'),
          const Divider(height: 18),
          _Metric(
            icon: Icons.hub_outlined,
            label: 'DEVICES FOUND',
            value: '$deviceCount / 8',
          ),
          const Divider(height: 18),
          _Metric(
            icon: Icons.schedule,
            label: 'LAST SCAN',
            value: lastScan == null ? '--' : _format(lastScan!),
          ),
        ],
      ),
    );
  }

  static String _format(DateTime t) =>
      '${t.day.toString().padLeft(2, '0')}/${t.month.toString().padLeft(2, '0')} ${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
}

class _Metric extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _Metric({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 28),
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
    final status = device.online == null
        ? 'EMPTY'
        : (device.online! ? 'ONLINE' : 'OFFLINE');
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
                  Icon(device.icon, size: 26),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      device.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: Chip(
                  visualDensity: VisualDensity.compact,
                  label: Text(status),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Slave ID: ${device.slaveId}  •  Model: ${device.model}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Colors.grey, fontSize: 12),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  const Text(
                    'VALUE',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      device.value,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  TextButton.icon(
                    onPressed: onPressed,
                    icon: Icon(
                      device.online == null
                          ? Icons.add
                          : Icons.settings_outlined,
                      size: 18,
                    ),
                    label: Text(device.online == null ? 'ADD' : 'CONFIG'),
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
  final VoidCallback onScan;
  final VoidCallback onAdd;

  const _ActionSection({
    required this.scanning,
    required this.onScan,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: 54,
          child: FilledButton.icon(
            onPressed: scanning ? null : onScan,
            icon: const Icon(Icons.search),
            label: Text(scanning ? 'SCANNING…' : 'SCAN FOR DEVICES'),
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 54,
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
        constraints: const BoxConstraints(minHeight: 72),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w900),
                  ),
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
            const SizedBox(width: 6),
            const Icon(Icons.chevron_right),
          ],
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final String? trailing;
  final Widget child;

  const _SectionCard({required this.title, this.trailing, required this.child});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w900),
            ),
            if (trailing != null) ...[
              const SizedBox(height: 4),
              Align(
                alignment: Alignment.centerLeft,
                child: Chip(
                  visualDensity: VisualDensity.compact,
                  label: Text(trailing!),
                ),
              ),
            ],
            const SizedBox(height: 12),
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
  final String model;
  final Future<void> Function({String? model}) onSearch;

  const _DriverSearchPage({required this.model, required this.onSearch});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('DRIVER DISCOVERY')),
      body: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          _SectionCard(
            title: 'NEW DEVICE FOUND',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Flow Sensor 1',
                  style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
                ),
                const SizedBox(height: 6),
                const Text('Slave ID: 1'),
                Text('Model: $model'),
                const SizedBox(height: 16),
                const Text('Compatible driver candidates can be searched online.'),
              ],
            ),
          ),
          const SizedBox(height: 14),
          _SectionCard(
            title: 'DRIVER ACTIONS',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _DriverAction(
                  icon: Icons.manage_search,
                  title: 'SEARCH DRIVERS',
                  subtitle: 'Open Chrome / default browser',
                  onTap: () => onSearch(model: model),
                ),
                const SizedBox(height: 8),
                _DriverAction(
                  icon: Icons.list_alt,
                  title: 'CANDIDATE DRIVERS',
                  subtitle: 'Search matching manufacturer/model drivers',
                  onTap: () => onSearch(model: model),
                ),
                const SizedBox(height: 8),
                _DriverAction(
                  icon: Icons.download_for_offline_outlined,
                  title: 'INSTALL DRIVER',
                  subtitle: 'Open driver source in browser',
                  onTap: () => onSearch(model: model),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DriverAction extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _DriverAction({
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
        constraints: const BoxConstraints(minHeight: 72),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.black12),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Icon(icon, size: 28),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 2),
                  Text(subtitle, style: const TextStyle(fontSize: 11)),
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

