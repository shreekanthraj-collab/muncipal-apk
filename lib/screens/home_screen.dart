import 'package:flutter/material.dart';

import 'valve_list_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  void openTransport(BuildContext context, String transport) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ValveListScreen(
          transport: transport,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'ORBI Valve',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 30),
            const Text(
              'SELECT CONNECTION',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 30),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: double.infinity,
                    height: 110,
                    child: ElevatedButton.icon(
                      onPressed: () => openTransport(
                        context,
                        'GSM/LTE',
                      ),
                      icon: const Icon(
                        Icons.cell_tower,
                        size: 32,
                      ),
                      label: const Text(
                        'GSM / LTE',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 25),
                  SizedBox(
                    width: double.infinity,
                    height: 110,
                    child: OutlinedButton.icon(
                      onPressed: () => openTransport(
                        context,
                        'LoRa',
                      ),
                      icon: const Icon(
                        Icons.settings_input_antenna,
                        size: 32,
                      ),
                      label: const Text(
                        'LoRa',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
