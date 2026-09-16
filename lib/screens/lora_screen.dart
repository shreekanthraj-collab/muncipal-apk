import 'package:flutter/material.dart';

import 'valve_view_screen.dart';

class LoraScreen extends StatelessWidget {
  const LoraScreen({super.key});

  @override
  Widget build(BuildContext context) => const ValveViewScreen(isLora: true);
}
