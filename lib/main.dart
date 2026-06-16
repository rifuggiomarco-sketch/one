import 'package:flutter/material.dart';

import 'screens/home_screen.dart';

void main() {
  runApp(const FindMyEarbudsApp());
}

class FindMyEarbudsApp extends StatelessWidget {
  const FindMyEarbudsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Trova i tuoi auricolari',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}
