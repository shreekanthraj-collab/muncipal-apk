import 'package:flutter/material.dart';
import 'gateway_detail_screen.dart';

class GatewayListScreen extends StatelessWidget {
  const GatewayListScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Gateways')),
    body: ListView(padding: const EdgeInsets.all(16), children: [
      _gateway(context, 'GW-001', true, '24 valves', 3),
      _gateway(context, 'GW-002', true, '18 valves', 2),
      _gateway(context, 'GW-003', false, '12 valves', 0),
    ]),
  );

  Widget _gateway(BuildContext context, String id, bool online, String valves, int bars) => Card(
    child: ListTile(
      leading: Icon(online ? Icons.router : Icons.router_outlined),
      title: Text(id),
      subtitle: Text('${online ? 'ONLINE' : 'OFFLINE'} • $valves'),
      trailing: Row(mainAxisSize: MainAxisSize.min, children: [
        Row(children: List.generate(3, (i) => Padding(
          padding: const EdgeInsets.symmetric(horizontal: 1),
          child: Icon(Icons.signal_cellular_alt, size: 15, color: i < bars ? null : Theme.of(context).disabledColor),
        ))),
        const Icon(Icons.chevron_right),
      ]),
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => GatewayDetailScreen(gatewayId: id))),
    ),
  );
}
