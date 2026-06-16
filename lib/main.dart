import 'package:flutter/material.dart';

import 'screens/home_screen.dart';
import 'services/proximity_monitor_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await ProximityMonitorService.initialize();
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
