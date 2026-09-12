import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

/// RS485 sensor configuration page.
///
/// A valve is selected at the top. Only the selected valve is shown below,
/// with exactly four sensor slots:
///   1. Flow Sensor 1
///   2. Flow Sensor 2
///   3. Tank Over Flow
///   4. Water Quality
///
/// Each sensor slot can have a device assigned independently.
class Rs485FlowScreen extends StatefulWidget {
  const Rs485FlowScreen({super.key});

  @override
  State<Rs485FlowScreen> createState() => _Rs485FlowScreenState();
}

class _Rs485FlowScreenState extends State<Rs485FlowScreen> {
  static const _valves = <_Rs485Valve>[
    _Rs485Valve('ORBI-001', 'Valve 001', 'GSM/LTE'),
    _Rs485Valve('ORBI-002', 'Valve 002', 'LoRa'),
    _Rs485Valve('ORBI-003', 'Valve 003', 'LoRa'),
    _Rs485Valve('ORBI-004', 'Valve 004', 'GSM/LTE'),
    _Rs485Valve('ORBI-005', 'Valve 005', 'LoRa'),
    _Rs485Valve('ORBI-006', 'Valve 006', 'GSM/LTE'),
    _Rs485Valve('ORBI-007', 'Valve 007', 'LoRa'),
    _Rs485Valve('ORBI-008', 'Valve 008', 'GSM/LTE'),
  ];

  String _selectedValveId = 'ORBI-001';
  late Map<String, _SensorDevice?> _devices;

  @override
  void initState() {
    super.initState();
    _devices = {
      for (final type in _sensorTypes) type.key: null,
    };
  }

  _Rs485Valve get _selectedValve =>
      _valves.firstWhere((valve) => valve.id == _selectedValveId);

  Future<void> _addDevice(_SensorType sensor) async {
    final nameController = TextEditingController();
    final addressController = TextEditingController(text: '1');

    final device = await showDialog<_SensorDevice>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('ADD ${sensor.title.toUpperCase()} DEVICE'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Assign a Modbus device to this sensor slot.',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: nameController,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'Device name',
                hintText: 'e.g. YF-DN50',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: addressController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Modbus address',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('CANCEL'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              final name = nameController.text.trim();
              final address = int.tryParse(addressController.text.trim());
              if (name.isEmpty || address == null || address < 1 || address > 247) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Enter a device name and Modbus address 1-247.'),
                  ),
                );
                return;
              }
              Navigator.pop(
                dialogContext,
                _SensorDevice(name: name, address: address),
              );
            },
            icon: const Icon(Icons.add),
            label: const Text('ADD TO SLOT'),
          ),
        ],
      ),
    );

    nameController.dispose();
    addressController.dispose();

    if (!mounted || device == null) return;

    setState(() {
      _devices[sensor.key] = device;
    });
  }

  Future<void> _searchDriver(_SensorType sensor) async {
    final query = Uri.encodeComponent(
      'RS485 Modbus ${sensor.title} ${_selectedValve.id}',
    );
    final uri = Uri.parse('https://www.google.com/search?q=$query');
    final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!opened && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to open Chrome for driver search.')),
      );
    }
  }

  void _installDriver() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Driver installation is performed on the connected host system.',
        ),
      ),
    );
  }

  void _removeDevice(_SensorType sensor) {
    setState(() {
      _devices[sensor.key] = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final valve = _selectedValve;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'RS485 VALVE MONITOR',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            tooltip: 'RS485 driver settings',
            onPressed: _installDriver,
            icon: const Icon(Icons.settings),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          const Text(
            'SELECT VALVE',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            initialValue: _selectedValveId,
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.settings_input_antenna),
              labelText: 'Valve',
              border: const OutlineInputBorder(),
              filled: true,
              fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
            ),
            items: [
              for (final item in _valves)
                DropdownMenuItem<String>(
                  value: item.id,
                  child: Text('${item.id}  •  ${item.name}'),
                ),
            ],
            onChanged: (value) {
              if (value == null) return;
              setState(() {
                _selectedValveId = value;
                _devices = {
                  for (final type in _sensorTypes) type.key: null,
                };
              });
            },
          ),
          const SizedBox(height: 14),
          Card(
            elevation: 0,
            child: ListTile(
              leading: const Icon(Icons.water_drop, size: 34),
              title: Text(
                valve.id,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text('${valve.name}  •  ${valve.transport}'),
              trailing: const Chip(
                avatar: Icon(Icons.circle, size: 12),
                label: Text('ONLINE'),
              ),
            ),
          ),
          const SizedBox(height: 14),
          const Text(
            'SENSOR SLOTS (4)',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
          ),
          const SizedBox(height: 10),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _sensorTypes.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 0.88,
            ),
            itemBuilder: (context, index) {
              final sensor = _sensorTypes[index];
              final device = _devices[sensor.key];
              return _sensorCard(sensor, device);
            },
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 58,
                  child: ElevatedButton.icon(
                    onPressed: () => _searchDriver(_sensorTypes[0]),
                    icon: const Icon(Icons.language),
                    label: const Text(
                      'SEARCH DRIVER\nIN CHROME',
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: SizedBox(
                  height: 58,
                  child: ElevatedButton.icon(
                    onPressed: _installDriver,
                    icon: const Icon(Icons.download),
                    label: const Text(
                      'INSTALL\nDRIVER',
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _sensorCard(_SensorType sensor, _SensorDevice? device) {
    final color = sensor.color;

    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: color.withValues(alpha: 0.65), width: 1.5),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(sensor.icon, color: color, size: 28),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    sensor.title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      device == null ? '--' : device.name,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: device == null ? 30 : 19,
                        fontWeight: FontWeight.bold,
                        color: device == null ? null : color,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      device == null
                          ? sensor.unit
                          : 'Modbus address ${device.address}',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: device == null
                  ? OutlinedButton.icon(
                      onPressed: () => _addDevice(sensor),
                      icon: const Icon(Icons.add),
                      label: const Text('ADD DEVICE'),
                    )
                  : OutlinedButton.icon(
                      onPressed: () => _removeDevice(sensor),
                      icon: const Icon(Icons.delete_outline),
                      label: const Text('REMOVE'),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Rs485Valve {
  final String id;
  final String name;
  final String transport;

  const _Rs485Valve(this.id, this.name, this.transport);
}

class _SensorDevice {
  final String name;
  final int address;

  const _SensorDevice({required this.name, required this.address});
}

class _SensorType {
  final String key;
  final String title;
  final String unit;
  final IconData icon;
  final Color color;

  const _SensorType({
    required this.key,
    required this.title,
    required this.unit,
    required this.icon,
    required this.color,
  });
}

const _sensorTypes = <_SensorType>[
  _SensorType(
    key: 'flow_1',
    title: 'Flow Sensor 1',
    unit: 'L/min',
    icon: Icons.water_drop,
    color: Colors.blue,
  ),
  _SensorType(
    key: 'flow_2',
    title: 'Flow Sensor 2',
    unit: 'L/min',
    icon: Icons.water_drop_outlined,
    color: Colors.green,
  ),
  _SensorType(
    key: 'tank_overflow',
    title: 'Tank Over Flow',
    unit: '%',
    icon: Icons.water_damage_outlined,
    color: Colors.orange,
  ),
  _SensorType(
    key: 'water_quality',
    title: 'Water Quality',
    unit: 'NTU',
    icon: Icons.science_outlined,
    color: Colors.purple,
  ),
];
