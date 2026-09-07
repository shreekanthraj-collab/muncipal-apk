import 'package:flutter/material.dart';

class WidgetStylePreviewScreen extends StatefulWidget {
  const WidgetStylePreviewScreen({super.key});
  @override
  State<WidgetStylePreviewScreen> createState() => _WidgetStylePreviewScreenState();
}

class _WidgetStylePreviewScreenState extends State<WidgetStylePreviewScreen> {
  int style = 0;
  final styles = const ['Standard', 'Compact', 'Tile'];
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('ORBI Widget Style')),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        SegmentedButton<int>(segments: [for (var i=0;i<styles.length;i++) ButtonSegment(value:i,label:Text(styles[i]))], selected:{style}, onSelectionChanged:(v)=>setState(()=>style=v.first)),
        const SizedBox(height: 16),
        _card('Gateway Status', style == 1 ? 'ONLINE  •  2 Gateways' : 'ONLINE', Icons.router),
        _card('Valve Status', 'OPEN  •  68%', Icons.tune),
        _card('Connectivity', 'RSSI  ▮▮▮', Icons.signal_cellular_alt),
        _card('Alerts', '0 Active', Icons.warning_amber),
      ]),
    );
  }
  Widget _card(String title, String value, IconData icon) {
    final radius = style == 2 ? 24.0 : style == 1 ? 10.0 : 16.0;
    return Card(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radius)), child: Padding(padding: EdgeInsets.all(style == 1 ? 10 : 16), child: Row(children: [Icon(icon), const SizedBox(width: 12), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: Theme.of(context).textTheme.labelLarge), const SizedBox(height: 4), Text(value, style: Theme.of(context).textTheme.titleMedium)]))])));
  }
}
