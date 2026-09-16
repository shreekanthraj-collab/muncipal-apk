import 'package:flutter/material.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  static const ids = ['GSM-001', 'GSM-002', 'LORA-001', 'LORA-002'];
  String selectedId = ids.first;
  final List<String> registered = [...ids];

  void addValve() {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Use device provisioning to add a valve.')));
  }

  void removeValve() {
    if (registered.length <= 1) return;
    setState(() => registered.remove(selectedId));
    if (!registered.contains(selectedId)) selectedId = registered.first;
  }

  void rebindValve() {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Rebind requested for $selectedId')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('MAP'), centerTitle: true),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          Card(child: Padding(padding: const EdgeInsets.all(14), child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            const Text('VALVE ID (GSM + LoRa)', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 7),
            DropdownButtonFormField<String>(initialValue: selectedId, decoration: const InputDecoration(border: OutlineInputBorder()), items: registered.map((id) => DropdownMenuItem(value: id, child: Text(id))).toList(), onChanged: (v) { if (v != null) setState(() => selectedId = v); }),
            const SizedBox(height: 10),
            FilledButton.icon(onPressed: addValve, icon: const Icon(Icons.add), label: const Text('ADD VALVE')),
          ]))),
          Card(child: SizedBox(height: 280, child: Stack(children: [
            Container(decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xffeaf4e8), Color(0xffdbe9f7)]))),
            const Center(child: Icon(Icons.map, size: 74, color: Colors.blueGrey)),
            const Positioned(top: 14, left: 14, child: Chip(avatar: Icon(Icons.my_location), label: Text('PHONE GPS'))),
            Positioned(top: 70, left: 82, child: _marker('GSM-001')),
            Positioned(top: 140, right: 80, child: _marker('LORA-001')),
            Positioned(bottom: 36, left: 150, child: _marker('GSM-002')),
          ]))),
          Card(child: Padding(padding: const EdgeInsets.all(14), child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            const Text('VALVE LIST', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            ...registered.map((id) => ListTile(leading: Icon(id.startsWith('GSM') ? Icons.cell_tower : Icons.settings_input_antenna), title: Text(id), subtitle: const Text('Latitude / Longitude available from phone GPS'), selected: id == selectedId, onTap: () => setState(() => selectedId = id))),
            Row(children: [Expanded(child: OutlinedButton(onPressed: removeValve, child: const Text('REMOVE'))), const SizedBox(width: 8), Expanded(child: OutlinedButton(onPressed: rebindValve, child: const Text('REBIND')))]),
          ]))),
        ],
      ),
    );
  }

  Widget _marker(String label) => DecoratedBox(decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8), boxShadow: const [BoxShadow(blurRadius: 5)]), child: Padding(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5), child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold))));
}
