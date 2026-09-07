import 'package:flutter/material.dart';

class GatewayDetailScreen extends StatelessWidget {
  const GatewayDetailScreen({super.key, required this.gatewayId});
  final String gatewayId;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(gatewayId)),
    body: ListView(padding: const EdgeInsets.all(16), children: const [
      Card(child: ListTile(leading: Icon(Icons.check_circle_outline), title: Text('GATEWAY STATUS'), subtitle: Text('ONLINE • Healthy'))),
      Card(child: ListTile(leading: Icon(Icons.device_hub_outlined), title: Text('CONNECTED DEVICES'), subtitle: Text('24 valves • 24 registered • 23 responding'))),
      Card(child: ListTile(leading: Icon(Icons.signal_cellular_alt), title: Text('COMMUNICATION'), subtitle: Text('LTE connected • LoRa active • RSSI shown as bars'))),
      Card(child: ListTile(leading: Icon(Icons.memory_outlined), title: Text('FIRMWARE'), subtitle: Text('Municipal Gateway • gw-municipal-dual-1.5.2'))),
      Card(child: ListTile(leading: Icon(Icons.access_time), title: Text('LAST HEARTBEAT'), subtitle: Text('Just now • Demo data'))),
    ]),
  );
}
