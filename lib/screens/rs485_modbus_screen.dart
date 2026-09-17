import 'package:flutter/material.dart';

/// Single-page RS485 / Modbus management UI.
///
/// This page intentionally keeps Zone, Ward and Valve ID at the top and
/// combines live device data, eight Modbus slots, discovery and driver
/// management into one screen. Hardware/MQTT callbacks can be connected
/// without changing the visual layout.
class Rs485ModbusScreen extends StatefulWidget {
  const Rs485ModbusScreen({
    super.key,
    required this.zoneNo,
    required this.wardNo,
    required this.valveId,
    this.onScan,
    this.onAddDevice,
    this.onConfigureSlot,
    this.onSearchDrivers,
    this.onShowCandidates,
    this.onInstallDriver,
  });

  final String zoneNo;
  final String wardNo;
  final String valveId;
  final VoidCallback? onScan;
  final VoidCallback? onAddDevice;
  final ValueChanged<int>? onConfigureSlot;
  final VoidCallback? onSearchDrivers;
  final VoidCallback? onShowCandidates;
  final VoidCallback? onInstallDriver;

  @override
  State<Rs485ModbusScreen> createState() => _Rs485ModbusScreenState();
}

class _DeviceSlot {
  const _DeviceSlot({
    required this.name,
    required this.model,
    required this.value,
    required this.status,
    required this.icon,
  });

  final String name;
  final String model;
  final String value;
  final String status;
  final IconData icon;
}

class _Rs485ModbusScreenState extends State<Rs485ModbusScreen> {
  bool _scanning = false;

  final List<_DeviceSlot> _slots = const [
    _DeviceSlot(name: 'Flow Sensor 1', model: 'FS-100', value: '12.5 FL/sec', status: 'ONLINE', icon: Icons.water_drop),
    _DeviceSlot(name: 'Flow Sensor 2', model: 'FS-100', value: '10.8 FL/sec', status: 'ONLINE', icon: Icons.water_drop),
    _DeviceSlot(name: 'Overflow Tank', model: 'LT-200', value: '75 %', status: 'ONLINE', icon: Icons.water),
    _DeviceSlot(name: 'Water Quality', model: 'WQ-300', value: 'pH 7.2', status: 'ONLINE', icon: Icons.science),
    _DeviceSlot(name: 'Energy Meter', model: 'EM-500', value: '230 V', status: 'OFFLINE', icon: Icons.bolt),
    _DeviceSlot(name: 'Pressure Sensor', model: 'PS-100', value: '--', status: 'EMPTY', icon: Icons.speed),
    _DeviceSlot(name: 'Temperature', model: 'TT-100', value: '--', status: 'EMPTY', icon: Icons.thermostat),
    _DeviceSlot(name: 'Custom Device', model: '--', value: '--', status: 'EMPTY', icon: Icons.widgets),
  ];

  Future<void> _scan() async {
    if (_scanning) return;
    setState(() => _scanning = true);
    widget.onScan?.call();
    await Future<void>.delayed(const Duration(milliseconds: 900));
    if (mounted) setState(() => _scanning = false);
  }

  void _manualAdd() {
    widget.onAddDevice?.call();
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('ADD RS485 DEVICE'),
        content: const Text('Enter the Modbus device address, model and driver assignment. Hardware installation will be performed on the selected valve node.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('CANCEL')),
          FilledButton(onPressed: () => Navigator.pop(context), child: const Text('CONTINUE')),
        ],
      ),
    );
  }

  void _slotAction(int index) {
    widget.onConfigureSlot?.call(index + 1);
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('SLOT ${index + 1}'),
        content: Text(_slots[index].status == 'EMPTY'
            ? 'Add and configure a Modbus RTU device for this slot.'
            : '${_slots[index].name}\n\nModel: ${_slots[index].model}\nCurrent value: ${_slots[index].value}\nStatus: ${_slots[index].status}'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('CLOSE')),
          FilledButton(onPressed: () => Navigator.pop(context), child: Text(_slots[index].status == 'EMPTY' ? 'ADD' : 'CONFIG')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FC),
      appBar: AppBar(
        title: const Text('RS485 / MODBUS'),
        leading: const BackButton(),
        actions: [
          IconButton(
            tooltip: 'Scan',
            onPressed: _scan,
            icon: _scanning
                ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.sync),
          ),
          IconButton(
            tooltip: 'Settings',
            onPressed: () => _showSettings(context),
            icon: const Icon(Icons.settings),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
          children: [
            _HeaderSelectionCard(theme),
            const SizedBox(height: 12),
            _BusStatusCard(theme),
            const SizedBox(height: 12),
            _DeviceSlotsCard(theme),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: _PrimaryAction(icon: Icons.search, label: _scanning ? 'SCANNING…' : 'SCAN FOR DEVICES', sublabel: 'Search and detect Modbus devices', onPressed: _scanning ? null : _scan)),
                const SizedBox(width: 10),
                Expanded(child: _SecondaryAction(icon: Icons.add, label: 'ADD DEVICE MANUALLY', sublabel: 'Enter device details', onPressed: _manualAdd)),
              ],
            ),
            const SizedBox(height: 12),
            _DriverManagementCard(theme),
            const SizedBox(height: 12),
            _InfoCard(theme),
          ],
        ),
      ),
    );
  }

  Widget _HeaderSelectionCard(ThemeData theme) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(child: _Selection(label: 'Zone No', value: widget.zoneNo)),
                const SizedBox(width: 10),
                Expanded(child: _Selection(label: 'Ward No', value: widget.wardNo)),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: _Selection(label: 'VALVE ID (GSM + LoRa)', value: widget.valveId)),
                const SizedBox(width: 10),
                SizedBox(
                  height: 56,
                  child: FilledButton.icon(
                    onPressed: () => _showAddValve(context),
                    icon: const Icon(Icons.add),
                    label: const Text('ADD VALVE'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _Selection({required String label, required String value}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 15)),
        const SizedBox(height: 5),
        InputDecorator(
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 14),
          ),
          child: Row(
            children: [
              Expanded(child: Text(value, overflow: TextOverflow.ellipsis)),
              const Icon(Icons.arrow_drop_down),
            ],
          ),
        ),
      ],
    );
  }

  Widget _BusStatusCard(ThemeData theme) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Expanded(child: Text('RS485 BUS STATUS', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700))),
                _StatusChip('ONLINE'),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: const [
                Expanded(child: _Metric(icon: Icons.memory, label: 'Baud Rate', value: '9600')),
                Expanded(child: _Metric(icon: Icons.hub, label: 'Devices Found', value: '4 / 8')),
                Expanded(child: _Metric(icon: Icons.access_time, label: 'Last Scan', value: '--')),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _DeviceSlotsCard(ThemeData theme) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 14, 12, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 4),
              child: Row(
                children: [
                  Expanded(child: Text('DEVICE SLOTS (8)', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700))),
                  Flexible(child: Text('Modbus RTU Devices', textAlign: TextAlign.right)),
                ],
              ),
            ),
            const SizedBox(height: 8),
            for (var i = 0; i < _slots.length; i++) _DeviceSlotTile(slotNo: i + 1, device: _slots[i], onTap: () => _slotAction(i)),
          ],
        ),
      ),
    );
  }

  Widget _DeviceSlotTile({required int slotNo, required _DeviceSlot device, required VoidCallback onTap}) {
    final empty = device.status == 'EMPTY';
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 7),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
          child: Row(
            children: [
              SizedBox(width: 32, child: Text('$slotNo', style: const TextStyle(fontWeight: FontWeight.w700))),
              Icon(device.icon, size: 25),
              const SizedBox(width: 10),
              Expanded(
                flex: 3,
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(device.name, style: const TextStyle(fontWeight: FontWeight.w700)),
                  Text('ID: $slotNo  |  Model: ${device.model}', style: const TextStyle(fontSize: 12)),
                ]),
              ),
              Expanded(child: Text(device.value, textAlign: TextAlign.right)),
              const SizedBox(width: 8),
              _StatusChip(device.status),
              const SizedBox(width: 6),
              TextButton.icon(
                onPressed: onTap,
                icon: Icon(empty ? Icons.add : Icons.settings, size: 18),
                label: Text(empty ? 'ADD' : 'CONFIG'),
              ),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }

  Widget _DriverManagementCard(ThemeData theme) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('DRIVER MANAGEMENT', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(child: _DriverAction(icon: Icons.find_in_page, title: 'SEARCH DRIVERS', subtitle: 'Find compatible drivers', onPressed: widget.onSearchDrivers)),
                const SizedBox(width: 8),
                Expanded(child: _DriverAction(icon: Icons.format_list_bulleted, title: 'CANDIDATE DRIVERS', subtitle: 'View matching drivers', onPressed: widget.onShowCandidates)),
                const SizedBox(width: 8),
                Expanded(child: _DriverAction(icon: Icons.download, title: 'INSTALL DRIVER', subtitle: 'Configure & install', onPressed: widget.onInstallDriver)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _InfoCard(ThemeData theme) {
    return Card(
      margin: EdgeInsets.zero,
      child: const Padding(
        padding: EdgeInsets.all(14),
        child: Row(
          children: [
            Icon(Icons.info_outline),
            SizedBox(width: 10),
            Expanded(child: Text('Supports Modbus RTU devices — Flow sensors, Level sensors, Water quality, Meters, etc.')),
          ],
        ),
      ),
    );
  }

  Widget _StatusChip(String value) {
    final isOnline = value == 'ONLINE';
    final isOffline = value == 'OFFLINE';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: isOnline ? Colors.green.withValues(alpha: .12) : isOffline ? Colors.orange.withValues(alpha: .14) : Colors.grey.withValues(alpha: .16),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Text(value, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: isOnline ? Colors.green.shade800 : isOffline ? Colors.orange.shade900 : Colors.blueGrey.shade800)),
    );
  }

  Widget _PrimaryAction({required IconData icon, required String label, required String sublabel, required VoidCallback? onPressed}) {
    return FilledButton(
      style: FilledButton.styleFrom(padding: const EdgeInsets.all(14), alignment: Alignment.centerLeft),
      onPressed: onPressed,
      child: Row(children: [Icon(icon, size: 32), const SizedBox(width: 10), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(label, style: const TextStyle(fontWeight: FontWeight.w700)), Text(sublabel, style: const TextStyle(fontSize: 11))]))]),
    );
  }

  Widget _SecondaryAction({required IconData icon, required String label, required String sublabel, required VoidCallback onPressed}) {
    return OutlinedButton(
      style: OutlinedButton.styleFrom(padding: const EdgeInsets.all(14), alignment: Alignment.centerLeft),
      onPressed: onPressed,
      child: Row(children: [Icon(icon, size: 30), const SizedBox(width: 10), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(label, style: const TextStyle(fontWeight: FontWeight.w700)), Text(sublabel, style: const TextStyle(fontSize: 11))]))]),
    );
  }

  Widget _DriverAction({required IconData icon, required String title, required String subtitle, required VoidCallback? onPressed}) {
    return InkWell(
      onTap: onPressed ?? () {},
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(14), border: Border.all(color: Theme.of(context).dividerColor)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Icon(icon, size: 30), const SizedBox(height: 10), Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)), const SizedBox(height: 3), Text(subtitle, style: const TextStyle(fontSize: 11))]),
      ),
    );
  }

  void _showAddValve(BuildContext context) {
    showDialog<void>(context: context, builder: (_) => AlertDialog(title: const Text('ADD VALVE'), content: const Text('Valve selection remains shared with GSM + LoRa. Connect this action to the existing valve registry.'), actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('CLOSE'))]));
  }

  void _showSettings(BuildContext context) {
    showDialog<void>(context: context, builder: (_) => AlertDialog(title: const Text('RS485 SETTINGS'), content: const Text('Bus: Modbus RTU\nBaud: 9600\nDevice slots: 8\nConfiguration is applied to the selected valve node.'), actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('CLOSE'))]));
  }
}

class _Metric extends StatelessWidget {
  const _Metric({required this.icon, required this.label, required this.value});
  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(children: [Icon(icon, size: 25), const SizedBox(width: 7), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(label, style: const TextStyle(fontSize: 12)), Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700))]))]),
    );
  }
}
