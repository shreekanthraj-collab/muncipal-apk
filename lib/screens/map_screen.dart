import 'package:flutter/material.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _ValveMapItem {
  _ValveMapItem({
    required this.id,
    required this.latitude,
    required this.longitude,
    required this.isGsm,
    required this.dx,
    required this.dy,
  });

  final String id;
  final double latitude;
  final double longitude;
  final bool isGsm;
  final double dx;
  final double dy;
}

class _MapScreenState extends State<MapScreen> {
  final TextEditingController _mapNameController =
      TextEditingController(text: 'Farm A - North Field');

  final List<_ValveMapItem> _valves = [
    _ValveMapItem(
      id: 'GSM-001',
      latitude: 14.598001,
      longitude: 120.982331,
      isGsm: true,
      dx: .18,
      dy: .63,
    ),
    _ValveMapItem(
      id: 'LORA-001',
      latitude: 14.601210,
      longitude: 120.987654,
      isGsm: false,
      dx: .55,
      dy: .34,
    ),
    _ValveMapItem(
      id: 'GSM-002',
      latitude: 14.595678,
      longitude: 120.990123,
      isGsm: true,
      dx: .70,
      dy: .72,
    ),
  ];

  @override
  void dispose() {
    _mapNameController.dispose();
    super.dispose();
  }

  void _editMapName() {
    final controller = TextEditingController(text: _mapNameController.text);
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Map Name'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Map Name',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CANCEL'),
          ),
          FilledButton(
            onPressed: () {
              setState(() => _mapNameController.text = controller.text.trim());
              Navigator.pop(context);
            },
            child: const Text('SAVE'),
          ),
        ],
      ),
    );
  }

  Future<void> _addValve() async {
    final idController = TextEditingController(text: 'GSM-004');
    final latController = TextEditingController(text: '14.600321');
    final lngController = TextEditingController(text: '120.985432');

    final result = await showDialog<_ValveMapItem>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('ADD VALVE'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: idController,
                decoration: const InputDecoration(labelText: 'Valve ID'),
              ),
              TextField(
                controller: latController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(labelText: 'Latitude'),
              ),
              TextField(
                controller: lngController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(labelText: 'Longitude'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CANCEL'),
          ),
          FilledButton(
            onPressed: () {
              final id = idController.text.trim();
              final lat = double.tryParse(latController.text.trim());
              final lng = double.tryParse(lngController.text.trim());
              if (id.isEmpty || lat == null || lng == null) return;
              Navigator.pop(
                context,
                _ValveMapItem(
                  id: id,
                  latitude: lat,
                  longitude: lng,
                  isGsm: id.toUpperCase().startsWith('GSM'),
                  dx: .48,
                  dy: .48,
                ),
              );
            },
            child: const Text('ADD'),
          ),
        ],
      ),
    );

    if (!mounted || result == null) return;
    setState(() => _valves.add(result));
    _showAdded(result);
  }

  void _showAdded(_ValveMapItem valve) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.check_circle, color: Colors.green, size: 58),
        title: const Text('Valve Added Successfully'),
        content: Text(
          'Valve ID:  ${valve.id}\n'
          'Latitude:  ${valve.latitude.toStringAsFixed(6)}\n'
          'Longitude: ${valve.longitude.toStringAsFixed(6)}',
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ),
        ],
      ),
    );
  }

  void _removeValve(_ValveMapItem valve) {
    setState(() => _valves.removeWhere((item) => item.id == valve.id));
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.delete, color: Colors.red, size: 58),
        title: const Text('Valve Removed'),
        content: Text(
          'Valve ID:  ${valve.id}\n'
          'Latitude:  ${valve.latitude.toStringAsFixed(6)}\n'
          'Longitude: ${valve.longitude.toStringAsFixed(6)}',
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ),
        ],
      ),
    );
  }

  void _rebindValve(_ValveMapItem valve) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Rebind requested for ${valve.id}')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('MAP'),
        centerTitle: true,
        leading: const BackButton(),
        actions: [
          PopupMenuButton<String>(
            onSelected: (_) {},
            itemBuilder: (context) => const [
              PopupMenuItem(value: 'refresh', child: Text('Refresh map')),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _mapNameController,
                    readOnly: true,
                    decoration: const InputDecoration(
                      labelText: 'Map Name',
                      border: OutlineInputBorder(),
                      suffixIcon: Icon(Icons.edit),
                    ),
                    onTap: _editMapName,
                  ),
                ),
                const SizedBox(width: 10),
                FilledButton.icon(
                  onPressed: _addValve,
                  icon: const Icon(Icons.add),
                  label: const Text('ADD VALVE'),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 10),
              children: [
                _MapSurface(valves: _valves),
                const SizedBox(height: 10),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(10, 10, 10, 4),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'Valve List (${_valves.length})',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 6),
                        ..._valves.map(_valveTile),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: 3,
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.cell_tower), label: 'GSM'),
          NavigationDestination(icon: Icon(Icons.settings_input_antenna), label: 'LoRa'),
          NavigationDestination(icon: Icon(Icons.map), label: 'MAP'),
          NavigationDestination(icon: Icon(Icons.account_tree), label: 'RS485'),
        ],
      ),
    );
  }

  Widget _valveTile(_ValveMapItem valve) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Row(
          children: [
            Icon(
              Icons.plumbing,
              color: valve.isGsm ? Colors.red : Colors.blue,
              size: 34,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Valve ID: ${valve.id}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text('Lat: ${valve.latitude.toStringAsFixed(6)}'),
                  Text('Lng: ${valve.longitude.toStringAsFixed(6)}'),
                ],
              ),
            ),
            OutlinedButton.icon(
              onPressed: () => _removeValve(valve),
              icon: const Icon(Icons.delete_outline),
              label: const Text('REMOVE'),
            ),
            const SizedBox(width: 6),
            FilledButton.icon(
              onPressed: () => _rebindValve(valve),
              icon: const Icon(Icons.link),
              label: const Text('REBIND'),
            ),
          ],
        ),
      ),
    );
  }
}

class _MapSurface extends StatelessWidget {
  const _MapSurface({required this.valves});

  final List<_ValveMapItem> valves;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: AspectRatio(
        aspectRatio: 1.16,
        child: Stack(
          children: [
            CustomPaint(
              painter: _MapPainter(),
              child: const SizedBox.expand(),
            ),
            const Positioned(
              left: 12,
              top: 12,
              child: Card(
                child: Padding(
                  padding: EdgeInsets.all(10),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.my_location, color: Colors.blue, size: 30),
                      SizedBox(width: 8),
                      Text(
                        'My Location (GPS)\nLat: 14.599232\nLng: 120.984321',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const Positioned(
              left: 49,
              bottom: 43,
              child: _LocationDot(label: 'You'),
            ),
            ...valves.map(
              (valve) => Positioned(
                left: 0,
                top: 0,
                child: FractionallyPositioned(
                  left: valve.dx,
                  top: valve.dy,
                  child: _ValveMarker(label: valve.id),
                ),
              ),
            ),
            const Positioned(
              right: 12,
              bottom: 12,
              child: Column(
                children: [
                  _MapButton(icon: Icons.my_location),
                  SizedBox(height: 4),
                  _MapButton(icon: Icons.add),
                  _MapButton(icon: Icons.remove),
                ],
              ),
            ),
            const Positioned(
              left: 10,
              bottom: 8,
              child: Text('Google', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }
}

class FractionallyPositioned extends StatelessWidget {
  const FractionallyPositioned({
    super.key,
    required this.left,
    required this.top,
    required this.child,
  });

  final double left;
  final double top;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment(-1 + left * 2, -1 + top * 2),
      child: child,
    );
  }
}

class _MapPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();
    paint.color = const Color(0xffd9efd3);
    canvas.drawRect(Offset.zero & size, paint);

    paint
      ..color = const Color(0xffb7d7a8)
      ..strokeWidth = 1.4
      ..style = PaintingStyle.stroke;

    for (var i = 0; i < 7; i++) {
      final y = size.height * (i + 1) / 8;
      canvas.drawLine(Offset(0, y), Offset(size.width, y + 28), paint);
    }
    for (var i = 0; i < 6; i++) {
      final x = size.width * (i + 1) / 7;
      canvas.drawLine(Offset(x, 0), Offset(x - 45, size.height), paint);
    }

    paint
      ..color = const Color(0xff9ac5dc)
      ..strokeWidth = 7
      ..style = PaintingStyle.stroke;
    final river = Path()
      ..moveTo(0, size.height * .75)
      ..quadraticBezierTo(
        size.width * .28,
        size.height * .58,
        size.width * .52,
        size.height * .72,
      )
      ..quadraticBezierTo(
        size.width * .78,
        size.height * .88,
        size.width,
        size.height * .64,
      );
    canvas.drawPath(river, paint);

    paint
      ..color = const Color(0xfff4d47b)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;
    canvas.drawLine(
      Offset(0, size.height * .25),
      Offset(size.width, size.height * .42),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _MapButton extends StatelessWidget {
  const _MapButton({required this.icon});
  final IconData icon;

  @override
  Widget build(BuildContext context) => Material(
        color: Colors.white,
        elevation: 3,
        borderRadius: BorderRadius.circular(8),
        child: SizedBox(
          width: 48,
          height: 44,
          child: Icon(icon),
        ),
      );
}

class _LocationDot extends StatelessWidget {
  const _LocationDot({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) => Column(
        children: [
          const CircleAvatar(
            radius: 15,
            backgroundColor: Colors.blue,
            child: Icon(Icons.circle, color: Colors.white, size: 11),
          ),
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      );
}

class _ValveMarker extends StatelessWidget {
  const _ValveMarker({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) => Column(
        children: [
          const Icon(Icons.location_on, color: Colors.red, size: 38),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(5),
              boxShadow: const [BoxShadow(blurRadius: 4)],
            ),
            child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      );
}
