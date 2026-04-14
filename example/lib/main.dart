import 'package:flutter/material.dart';
import 'package:customflags_flutter/customflags_flutter.dart';

void main() {
  runApp(const ExampleApp());
}

class ExampleApp extends StatelessWidget {
  const ExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'customflags_flutter example',
      theme: ThemeData(
        colorSchemeSeed: Colors.deepPurple,
        useMaterial3: true,
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final calculator = Calculator();

    return Scaffold(
      appBar: AppBar(title: const Text('customflags_flutter')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Package wired up ✓'),
            const SizedBox(height: 16),
            Text('Calculator.addOne(1) = ${calculator.addOne(1)}'),
          ],
        ),
      ),
    );
  }
}
