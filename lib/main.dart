import 'package:flutter/material.dart';

import 'screens/splash_screen.dart';

void main() {
  runApp(const OrbiValveApp());
}

class OrbiValveApp extends StatelessWidget {
  const OrbiValveApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'ORBI DRIVE Operator',
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.blue,
      ),
      home: const SplashScreen(),
    );
  }
}
