import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'screens/home_screen.dart';
import 'services/proximity_monitor_service.dart';
import 'ble_diagnostics.dart';

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
      // In debug mode show a small launcher so you can open diagnostics easily.
      home: kDebugMode ? const _DebugLauncher() : const HomeScreen(),
      routes: {
        '/home': (_) => const HomeScreen(),
        '/ble_diagnostics': (_) => const BleDiagnosticsPage(),
      },
    );
  }
}

class _DebugLauncher extends StatelessWidget {
  const _DebugLauncher({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('App Launcher (debug)')),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ElevatedButton(
              onPressed: () => Navigator.pushNamed(context, '/home'),
              child: const Text('Open App'),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () => Navigator.pushNamed(context, '/ble_diagnostics'),
              child: const Text('Open BLE Diagnostics'),
            ),
          ],
        ),
      ),
    );
  }
}
