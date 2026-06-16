import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

import '../models/saved_device.dart';
import '../services/bluetooth_finder_service.dart';

/// Lets the user scan for nearby Bluetooth devices and pick the
/// earbuds they want to be able to find later.
class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key});

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> {
  final _bluetooth = BluetoothFinderService();
  StreamSubscription<List<ScanResult>>? _scanSub;
  List<ScanResult> _results = [];
  bool _scanning = false;

  @override
  void initState() {
    super.initState();
    _startScan();
  }

  Future<void> _startScan() async {
    final granted = await _bluetooth.requestPermissions();
    if (!granted) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                'Permessi Bluetooth necessari per cercare gli auricolari'),
          ),
        );
      }
      return;
    }
    setState(() {
      _scanning = true;
      _results = [];
    });
    _scanSub = _bluetooth.scanForDevices().listen((results) {
      results.sort((a, b) => b.rssi.compareTo(a.rssi));
      if (mounted) setState(() => _results = results);
    });
    Future.delayed(const Duration(seconds: 8), () {
      if (mounted) setState(() => _scanning = false);
    });
  }

  @override
  void dispose() {
    _scanSub?.cancel();
    _bluetooth.stopScan();
    _bluetooth.dispose();
    super.dispose();
  }

  String _nameFor(ScanResult r) {
    final name = r.device.platformName;
    return name.isNotEmpty ? name : r.device.remoteId.str;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Seleziona i tuoi auricolari'),
        actions: [
          if (_scanning)
            const Padding(
              padding: EdgeInsets.all(16),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _startScan,
            ),
        ],
      ),
      body: _results.isEmpty
          ? Center(
              child: Text(
                _scanning
                    ? 'Ricerca dispositivi Bluetooth in corso...'
                    : 'Nessun dispositivo trovato. Riprova.',
              ),
            )
          : ListView.builder(
              itemCount: _results.length,
              itemBuilder: (context, index) {
                final r = _results[index];
                return ListTile(
                  leading: const Icon(Icons.headset),
                  title: Text(_nameFor(r)),
                  subtitle: Text('${r.rssi} dBm'),
                  onTap: () {
                    Navigator.pop(
                      context,
                      SavedDevice(
                        remoteId: r.device.remoteId.str,
                        name: _nameFor(r),
                      ),
                    );
                  },
                );
              },
            ),
    );
  }
}
