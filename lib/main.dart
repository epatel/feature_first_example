import 'package:flutter/material.dart';
import 'demo_page.dart';

void main() {
  runApp(const FeatureFirstApp());
}

class FeatureFirstApp extends StatelessWidget {
  const FeatureFirstApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Feature-First Structured',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.indigo,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      home: const DemoPage(),
    );
  }
}
