import 'dart:async';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

class BleDiagnosticsPage extends StatefulWidget {
  const BleDiagnosticsPage({super.key});

  @override
  State<BleDiagnosticsPage> createState() => _BleDiagnosticsPageState();
}

class _BleDiagnosticsPageState extends State<BleDiagnosticsPage> {
  final List<String> _logs = [];
  StreamSubscription? _adapterSub;
  StreamSubscription? _scanSub;

  void _log(Object? o) {
    final s = DateTime.now().toIso8601String() + ' - ' + (o?.toString() ?? '');
    setState(() => _logs.insert(0, s));
    // Also print to console for adb logcat / CI
    // ignore: avoid_print
    print(s);
  }

  Future<void> _runAll() async {
    _log('--- START DIAGNOSTICS ---');

    // 1) Permissions (request and show statuses)
    try {
      final statuses = await [
        Permission.bluetoothScan,
        Permission.bluetoothConnect,
        Permission.location,
        Permission.bluetooth,
      ].request();
      _log('Permission statuses: $statuses');
    } catch (e) {
      _log('Permission request failed: $e');
    }

    // 2) Location services enabled?
    try {
      final locEnabled = await Geolocator.isLocationServiceEnabled();
      _log('Location service enabled: $locEnabled');
    } catch (e) {
      _log('Location service check failed: $e');
    }

    // 3) Adapter state
    try {
      final state = await FlutterBluePlus.adapterState.first;
      _log('Adapter state (first): $state');
      _adapterSub?.cancel();
      _adapterSub = FlutterBluePlus.adapterState.listen((s) => _log('Adapter state change: $s'));
    } catch (e) {
      _log('Adapter state read failed: $e');
    }

    // 4) Start BLE scan for 10s and collect results
    try {
      _log('Starting BLE scan for 10 seconds...');
      _scanSub?.cancel();
      _scanSub = FlutterBluePlus.scanResults.listen((results) {
        _log('SCAN_RESULTS count: ${results.length}');
        for (var i = 0; i < results.length && i < 20; i++) {
          final r = results[i];
          _log('  #$i name="${r.device.name}" id=${r.device.id} rssi=${r.rssi} advertised=${r.advertisementData}');
        }
      });

      await FlutterBluePlus.startScan(timeout: const Duration(seconds: 10));
      _log('Scan completed (startScan returned).');
      await Future.delayed(const Duration(seconds: 1));
      await FlutterBluePlus.stopScan();
      _log('Stopped scan.');
    } catch (e) {
      _log('Scan failed: $e');
    }

    _log('--- END DIAGNOSTICS ---');
  }

  @override
  void dispose() {
    _adapterSub?.cancel();
    _scanSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('BLE Diagnostics')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8),
            child: ElevatedButton(
              onPressed: _runAll,
              child: const Text('Run diagnostics'),
            ),
          ),
          Expanded(
            child: ListView(
              reverse: true,
              children: _logs.map((l) => Padding(padding: const EdgeInsets.all(4), child: Text(l))).toList(),
            ),
          ),
        ],
      ),
    );
  }
}
