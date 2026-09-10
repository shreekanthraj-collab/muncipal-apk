import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
  List<String> valves = [];
  bool loading = true;

  String get storageKey {
    return 'valves_${widget.transport.toLowerCase().replaceAll('/', '_')}';
  }

  @override
  void initState() {
    super.initState();
    loadValves();
  }

  Future<void> loadValves() async {
    final prefs = await SharedPreferences.getInstance();
    final savedValves = prefs.getStringList(storageKey);

    if (!mounted) return;

    setState(() {
      valves = savedValves ?? ['ORBI-001'];
      loading = false;
    });

    if (savedValves == null) {
      await prefs.setStringList(storageKey, valves);
    }
  }

  Future<void> saveValves() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(storageKey, valves);
  }

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
              onPressed: () async {
                final valveId = controller.text.trim();

                if (valveId.isEmpty || valves.contains(valveId)) {
                  return;
                }

                setState(() {
                  valves.add(valveId);
                });

                await saveValves();

                if (context.mounted) {
                  Navigator.pop(context);
                }
              },
              child: const Text('ADD'),
            ),
          ],
        );
      },
    );
  }

  Future<void> removeValve(String valveId) async {
    setState(() {
      valves.remove(valveId);
    });

    await saveValves();
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
    if (loading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

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
