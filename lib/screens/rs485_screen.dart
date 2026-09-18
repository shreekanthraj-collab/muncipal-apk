import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../services/valve_storage.dart';

class Rs485Screen extends StatefulWidget {
  const Rs485Screen({super.key});

  @override
  State<Rs485Screen> createState() => _Rs485ScreenState();
}

class _Rs485ScreenState extends State<Rs485Screen> {
  List<String> valveIds = const [];
  String? selectedValveId;
  bool sensor1Added = true;
  bool sensor2Added = true;
  bool overflowAdded = true;
  bool waterQualityAdded = true;

  // Set this to the production driver portal when the web backend URL is supplied.
  static final Uri driverPortal = Uri.parse('https://YOUR_DRIVER_PORTAL_URL');

  Future<void> openDriverPortal() async {
    if (driverPortal.host == 'YOUR_DRIVER_PORTAL_URL') {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Driver portal URL is not configured yet.')),
        );
      }
      return;
    }
    await launchUrl(driverPortal, mode: LaunchMode.externalApplication);
  }

  void addSensor() => setState(() => sensor1Added = true);
  void removeSensor() => setState(() => sensor2Added = false);

  @override
  void initState() {
    super.initState();
    _loadValveIds();
  }

  Future<void> _loadValveIds() async {
    final ids = await ValveStorage.loadValveIds();

    if (!mounted) return;

    setState(() {
      valveIds = ids;

      if (selectedValveId != null &&
          !valveIds.contains(selectedValveId)) {
        selectedValveId = null;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('RS485 / MODBUS'), centerTitle: true),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'VALVE ID',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 7),
                  DropdownButtonFormField<String>(
                    initialValue: selectedValveId,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                    ),
                    hint: const Text('Select a valve saved on MAP'),
                    items: valveIds
                        .map(
                          (id) => DropdownMenuItem<String>(
                            value: id,
                            child: Text(id),
                          ),
                        )
                        .toList(),
                    onChanged: valveIds.isEmpty
                        ? null
                        : (v) {
                            if (v != null) {
                              setState(() => selectedValveId = v);
                            }
                          },
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
          ),
          _sensorCard(
            'Flow Sensor 1',
            sensor1Added ? '12.5 FL/sec' : 'Not configured',
            Icons.water_drop,
          ),
          _sensorCard(
            'Flow Sensor 2',
            sensor2Added ? '10.8 FL/sec' : 'Not configured',
            Icons.water_drop,
          ),
          _sensorCard(
            'Overflow Tank',
            overflowAdded ? 'FULL / EMPTY' : 'Not configured',
            Icons.storage,
          ),
          _sensorCard(
            'Water Quality Sensor',
            waterQualityAdded ? '% / contents' : 'Not configured',
            Icons.science,
          ),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'SENSOR MANAGEMENT',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: addSensor,
                          icon: const Icon(Icons.add),
                          label: const Text('ADD NEW SENSOR'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: FilledButton.tonal(
                          onPressed: removeSensor,
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.delete),
                              SizedBox(width: 6),
                              Text('REMOVE SENSOR'),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'DEVICE DRIVERS',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  FilledButton.icon(
                    onPressed: openDriverPortal,
                    icon: const Icon(Icons.open_in_new),
                    label: const Text('SEARCH FOR NEW DEVICE DRIVERS'),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Opens the driver web page in Chrome for manufacturer/model selection and direct-to-device driver download.',
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sensorCard(String title, String value, IconData icon) => Card(
        child: ListTile(
          leading: Icon(icon),
          title: Text(title),
          trailing: Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
      );

}
