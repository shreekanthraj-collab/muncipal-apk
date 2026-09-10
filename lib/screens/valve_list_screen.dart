import 'package:flutter/material.dart';

import 'valve_detail_screen.dart';

class ValveListScreen extends StatefulWidget {
  final String transport;

  const ValveListScreen({
    super.key,
    required this.transport,
  });

  @override
  State<ValveListScreen> createState() => _ValveListScreenState();
}

class _ValveListScreenState extends State<ValveListScreen> {
  final List<String> valves = [
    'ORBI-001',
  ];

  void addValve() {
    final controller = TextEditingController();

    showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('ADD VALVE'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(
              labelText: 'Valve ID',
              hintText: 'ORBI-002',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('CANCEL'),
            ),
            ElevatedButton(
              onPressed: () {
                final valveId = controller.text.trim();

                if (valveId.isEmpty || valves.contains(valveId)) {
                  return;
                }

                setState(() {
                  valves.add(valveId);
                });

                Navigator.pop(context);
              },
              child: const Text('ADD'),
            ),
          ],
        );
      },
    );
  }

  void removeValve(String valveId) {
    setState(() {
      valves.remove(valveId);
    });
  }

  void openValve(String valveId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ValveDetailScreen(
          transport: widget.transport,
          valveId: valveId,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          '${widget.transport} VALVES',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: valves.isEmpty
          ? const Center(
              child: Text(
                'No valves added',
                style: TextStyle(fontSize: 18),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: valves.length,
              itemBuilder: (context, index) {
                final valveId = valves[index];

                return Card(
                  child: ListTile(
                    leading: const Icon(
                      Icons.water_drop,
                      size: 32,
                    ),
                    title: Text(
                      valveId,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    subtitle: const Text('Controller not connected'),
                    trailing: PopupMenuButton<String>(
                      onSelected: (value) {
                        if (value == 'open') {
                          openValve(valveId);
                        } else if (value == 'remove') {
                          removeValve(valveId);
                        }
                      },
                      itemBuilder: (context) => const [
                        PopupMenuItem(
                          value: 'open',
                          child: Text('Open'),
                        ),
                        PopupMenuItem(
                          value: 'remove',
                          child: Text('Remove'),
                        ),
                      ],
                    ),
                    onTap: () => openValve(valveId),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: addValve,
        icon: const Icon(Icons.add),
        label: const Text('ADD VALVE'),
      ),
    );
  }
}

