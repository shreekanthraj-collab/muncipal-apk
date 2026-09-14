import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class Rs485Screen extends StatefulWidget {
  const Rs485Screen({super.key});

  @override
  State<Rs485Screen> createState() => _Rs485ScreenState();
}

class _Rs485ScreenState extends State<Rs485Screen> {
  static const valveIds = ['GSM-001', 'GSM-002', 'LORA-001', 'LORA-002'];
  String selectedValveId = valveIds.first;
  bool sensor1Added = true;
  bool sensor2Added = true;
  bool overflowAdded = true;
  bool waterQualityAdded = true;

  // Set this to the production driver portal when the web backend URL is supplied.
  static final Uri driverPortal = Uri.parse('https://YOUR_DRIVER_PORTAL_URL');

  Future<void> openDriverPortal() async {
    if (driverPortal.host == 'YOUR_DRIVER_PORTAL_URL') {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Driver portal URL is not configured yet.')));
      }
      return;
    }
    await launchUrl(driverPortal, mode: LaunchMode.externalApplication);
  }

  void addSensor() => setState(() => sensor1Added = true);
  void removeSensor() => setState(() => sensor2Added = false);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('RS485 / MODBUS'), centerTitle: true),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          Card(child: Padding(padding: const EdgeInsets.all(14), child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            const Text('VALVE ID (GSM + LoRa)', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 7),
            DropdownButtonFormField<String>(value: selectedValveId, decoration: const InputDecoration(border: OutlineInputBorder()), items: valveIds.map((id) => DropdownMenuItem(value: id, child: Text(id))).toList(), onChanged: (v) { if (v != null) setState(() => selectedValveId = v); }),
            const SizedBox(height: 12),
            FilledButton.icon(onPressed: () => _info('ADD VALVE'), icon: const Icon(Icons.add), label: const Text('ADD VALVE')),
          ]))),
          _sensorCard('Flow Sensor 1', sensor1Added ? '12.5 FL/sec' : 'Not configured', Icons.water_drop),
          _sensorCard('Flow Sensor 2', sensor2Added ? '10.8 FL/sec' : 'Not configured', Icons.water_drop),
          _sensorCard('Overflow Tank', overflowAdded ? 'FULL / EMPTY' : 'Not configured', Icons.storage),
          _sensorCard('Water Quality Sensor', waterQualityAdded ? '% / contents' : 'Not configured', Icons.science),
          Card(child: Padding(padding: const EdgeInsets.all(14), child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            const Text('SENSOR MANAGEMENT', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Row(children: [Expanded(child: FilledButton.icon(onPressed: addSensor, icon: const Icon(Icons.add), label: const Text('ADD NEW SENSOR'))), const SizedBox(width: 8), Expanded(child: FilledButton.tonal(onPressed: removeSensor, icon: const Icon(Icons.delete), label: const Text('REMOVE SENSOR')))]),
          ]))),
          Card(child: Padding(padding: const EdgeInsets.all(14), child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            const Text('DEVICE DRIVERS', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            FilledButton.icon(onPressed: openDriverPortal, icon: const Icon(Icons.open_in_new), label: const Text('SEARCH FOR NEW DEVICE DRIVERS')),
            const SizedBox(height: 6),
            const Text('Opens the driver web page in Chrome for manufacturer/model selection and direct-to-device driver download.', textAlign: TextAlign.center),
          ]))),
        ],
      ),
    );
  }

  Widget _sensorCard(String title, String value, IconData icon) => Card(child: ListTile(leading: Icon(icon), title: Text(title), trailing: Text(value, style: const TextStyle(fontWeight: FontWeight.bold))));

  void _info(String title) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$title for $selectedValveId')));
}
