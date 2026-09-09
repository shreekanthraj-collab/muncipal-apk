import 'dart:async';
import 'package:flutter/material.dart';
import 'models/valve_data.dart';
import 'models/valve_command.dart';
import 'services/aws_service.dart';
import 'dart:convert';
void main() {
	runApp(const OrbiValveApp());
}

class OrbiValveApp extends StatelessWidget {
	const OrbiValveApp({super.key});

	@override
	Widget build(BuildContext context) {
		return MaterialApp(
			debugShowCheckedModeBanner: false,
			title: 'ORBI Valve',
			theme: ThemeData(
				useMaterial3: true,
				colorSchemeSeed: Colors.blue,
			),
			home: const OrbiValvePage(),
		);
	}
}

class OrbiValvePage extends StatefulWidget {
	const OrbiValvePage({super.key});

	@override
	State<OrbiValvePage> createState() => _OrbiValvePageState();
}

class _OrbiValvePageState extends State<OrbiValvePage> {
        int selectedPosition = 0;

        ValveData valveData = const ValveData(
                valveId: 'ORBI-001',
                status: 'STOPPED',
                requested: 0,
                actual: 0,
                connected: false,
        );

	int requestedPosition = 0;
	int actualPosition = 0;
	String status = 'STOPPED';
	Timer? movementTimer;
        String lastCommandJson = '';

        late final AwsService awsService;
        StreamSubscription<ValveData>? statusSubscription;

	void selectPosition(int value) {
		setState(() => selectedPosition = value);
	}

        Future<void> setValve() async {
                final command = ValveCommand(
                        valveId: valveData.valveId,
                        command: 'SET_POSITION',
                        value: selectedPosition,
                );

                setState(() {
                        lastCommandJson = const JsonEncoder.withIndent('  ').convert(command.toJson());
                });

                if (awsService.connected) {
                        try {
                                await awsService.sendCommand(command);
                        } catch (error) {
                                debugPrint('MQTT SET_POSITION failed: $error');
                        }
                }

                movementTimer?.cancel();
                setState(() {
                        requestedPosition = selectedPosition;
                        if (actualPosition < requestedPosition) {
                                status = 'OPENING';
                        } else if (actualPosition > requestedPosition) {
                                status = 'CLOSING';
                        } else {
                                status = 'STOPPED';
                        }
                });

                if (actualPosition == requestedPosition) return;

                movementTimer = Timer.periodic(const Duration(milliseconds: 50), (timer) {
                        if (!mounted) {
                                timer.cancel();
                                return;
                        }
                        setState(() {
                                if (actualPosition < requestedPosition) {
                                        actualPosition++;
                                } else if (actualPosition > requestedPosition) {
                                        actualPosition--;
                                }
                                if (actualPosition == requestedPosition) {
                                        status = 'STOPPED';
                                        timer.cancel();
                                }
                        });
                });
        }

        Future<void> stopValve() async {
                movementTimer?.cancel();
                movementTimer = null;

                final command = ValveCommand(
                        valveId: valveData.valveId,
                        command: 'STOP',
                        value: 0,
                );

                setState(() {
                        status = 'STOPPED';
                        lastCommandJson = const JsonEncoder.withIndent('  ').convert(command.toJson());
                });

                if (awsService.connected) {
                        try {
                                await awsService.sendCommand(command);
                        } catch (error) {
                                debugPrint('MQTT STOP failed: $error');
                        }
                }
        }

	Widget positionButton(int value) {
		final selected = selectedPosition == value;
		return GestureDetector(
			onTap: () => selectPosition(value),
			child: Column(
				children: [
					Icon(selected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
							size: 28, color: selected ? Colors.blue : Colors.grey),
					const SizedBox(height: 5),
					Text('$value%', style: TextStyle(fontWeight: selected ? FontWeight.bold : FontWeight.normal)),
				],
			),
		);
	}

	Color statusColor() {
		switch (status) {
			case 'OPENING': return Colors.blue;
			case 'CLOSING': return Colors.orange;
			default: return Colors.green;
		}
	}

	@override
        void initState() {
                super.initState();

                awsService = AwsService(
                        host: 'YOUR_AWS_IOT_ENDPOINT',
                        clientId: 'ORBI-APP',
                        valveId: valveData.valveId,
                );

                statusSubscription = awsService.valveStatusStream.listen((data) {
                        if (!mounted) return;

                        setState(() {
                                valveData = data;
                                status = data.status;
                                requestedPosition = data.requested;
                                actualPosition = data.actual;
                        });
                });
        }

        @override
        void dispose() {
                movementTimer?.cancel();
                statusSubscription?.cancel();
                awsService.dispose();
                super.dispose();
        }

	@override
	Widget build(BuildContext context) {
		return Scaffold(
			appBar: AppBar(title: const Text('ORBI Valve', style: TextStyle(fontWeight: FontWeight.bold)), centerTitle: true),
			body: SingleChildScrollView(
				padding: const EdgeInsets.all(20),
				child: Column(children: [
					Card(child: Padding(padding: const EdgeInsets.all(24), child: Column(children: [
						const Text('VALVE STATUS', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
						const SizedBox(height: 10),
						Text(status, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: statusColor())),
						const SizedBox(height: 25),
						Row(children: [
							Expanded(child: Column(children: [const Text('REQUESTED'), const SizedBox(height: 6), Text('$requestedPosition%', style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold))])),
							Container(width: 1, height: 50, color: Colors.grey),
							Expanded(child: Column(children: [const Text('ACTUAL'), const SizedBox(height: 6), Text('$actualPosition%', style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold))])),
						]),
					]))),
					const SizedBox(height: 25),
					Card(child: Padding(padding: const EdgeInsets.all(20), child: Column(children: [
						const Text('VALVE OPENING', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
						const SizedBox(height: 15),
						Text('$selectedPosition%', style: const TextStyle(fontSize: 46, fontWeight: FontWeight.bold)),
						const SizedBox(height: 15),
						Slider(value: selectedPosition.toDouble(), min: 0, max: 100, divisions: 4, label: '$selectedPosition%', onChanged: (value) => selectPosition(value.round())),
						const SizedBox(height: 5),
						Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [positionButton(0), positionButton(25), positionButton(50), positionButton(75), positionButton(100)]),
						const SizedBox(height: 25),
						SizedBox(width: double.infinity, height: 52, child: ElevatedButton(onPressed: setValve, child: Text('SET VALVE TO $selectedPosition%', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)))),
                                                const SizedBox(height: 10),
                                                SizedBox(width: double.infinity, height: 52, child: OutlinedButton(onPressed: stopValve, child: const Text('STOP VALVE', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)))),
					]))),
					const SizedBox(height: 20),
                                        if (lastCommandJson.isNotEmpty)
                                                Card(
                                                        child: Padding(
                                                                padding: const EdgeInsets.all(16),
                                                                child: Column(
                                                                        crossAxisAlignment: CrossAxisAlignment.start,
                                                                        children: [
                                                                                const Text(
                                                                                        'COMMAND JSON',
                                                                                        style: TextStyle(
                                                                                                fontSize: 16,
                                                                                                fontWeight: FontWeight.bold,
                                                                                        ),
                                                                                ),
                                                                                const SizedBox(height: 10),
                                                                                SelectableText(
                                                                                        lastCommandJson,
                                                                                        style: const TextStyle(
                                                                                                fontFamily: 'monospace',
                                                                                                fontSize: 13,
                                                                                        ),
                                                                                ),
                                                                        ],
                                                                ),
                                                        ),
                                                ),
                                        const SizedBox(height: 20),					const Row(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.circle, size: 10, color: Colors.grey), SizedBox(width: 8), Text('Controller not connected', style: TextStyle(color: Colors.grey))]),
				]),
			),
		);
	}
}
