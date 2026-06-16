import 'dart:async';

import 'package:flutter/material.dart';

import '../models/saved_device.dart';
import '../services/bluetooth_finder_service.dart';
import '../services/ring_service.dart';
import '../widgets/signal_strength_indicator.dart';

class FinderScreen extends StatefulWidget {
  final SavedDevice device;

  const FinderScreen({super.key, required this.device});

  @override
  State<FinderScreen> createState() => _FinderScreenState();
}

class _FinderScreenState extends State<FinderScreen> {
  final _bluetooth = BluetoothFinderService();
  final _ring = RingService();
  StreamSubscription<int?>? _rssiSub;
  int? _rssi;

  @override
  void initState() {
    super.initState();
    _startTracking();
  }

  Future<void> _startTracking() async {
    await _bluetooth.requestPermissions();
    _rssiSub = _bluetooth.trackRssi(widget.device.remoteId).listen((rssi) {
      if (mounted) setState(() => _rssi = rssi);
    });
  }

  Future<void> _toggleRing() async {
    if (_ring.isRinging) {
      await _ring.stopRinging();
    } else {
      await _ring.startRinging();
    }
    setState(() {});
  }

  @override
  void dispose() {
    _rssiSub?.cancel();
    _bluetooth.dispose();
    _ring.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.device.name)),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SignalStrengthIndicator(rssi: _rssi),
              const SizedBox(height: 40),
              FilledButton.icon(
                onPressed: _toggleRing,
                icon: Icon(_ring.isRinging ? Icons.volume_off : Icons.volume_up),
                label: Text(
                  _ring.isRinging ? 'Ferma lo squillo' : 'Fai squillare',
                ),
                style: FilledButton.styleFrom(
                  minimumSize: const Size(220, 56),
                  backgroundColor: _ring.isRinging ? Colors.red : null,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Assicurati che gli auricolari siano connessi via '
                'audio Bluetooth per sentirli squillare. La barra sopra '
                'indica quanto sei vicino in base al segnale Bluetooth.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
