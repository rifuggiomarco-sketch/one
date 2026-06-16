import 'dart:io';

import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

import '../models/saved_device.dart';
import '../services/proximity_monitor_service.dart';
import '../services/storage_service.dart';
import 'finder_screen.dart';
import 'scan_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _storage = StorageService();
  List<SavedDevice> _devices = [];
  bool _monitoring = false;

  @override
  void initState() {
    super.initState();
    _load();
    _loadMonitoringState();
  }

  Future<void> _load() async {
    final devices = await _storage.loadDevices();
    if (mounted) setState(() => _devices = devices);
  }

  Future<void> _loadMonitoringState() async {
    final running = await ProximityMonitorService.isRunning();
    if (mounted) setState(() => _monitoring = running);
  }

  Future<void> _addDevice() async {
    final device = await Navigator.push<SavedDevice>(
      context,
      MaterialPageRoute(builder: (_) => const ScanScreen()),
    );
    if (device != null) {
      await _storage.addDevice(device);
      await _load();
    }
  }

  Future<void> _removeDevice(SavedDevice device) async {
    await _storage.removeDevice(device.remoteId);
    await _load();
  }

  Future<void> _toggleMonitoring(bool value) async {
    if (value) {
      await [
        Permission.bluetoothScan,
        Permission.bluetoothConnect,
        Permission.locationWhenInUse,
        Permission.notification,
      ].request();
      await ProximityMonitorService.start();
    } else {
      ProximityMonitorService.stop();
    }
    setState(() => _monitoring = value);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Trova i tuoi auricolari')),
      body: Column(
        children: [
          SwitchListTile(
            value: _monitoring,
            onChanged: (_devices.isEmpty || !ProximityMonitorService.isSupported)
                ? null
                : _toggleMonitoring,
            title: const Text('Avvisami se un auricolare si allontana'),
            subtitle: Text(
              !ProximityMonitorService.isSupported
                  ? 'Non disponibile su questa piattaforma.'
                  : Platform.isIOS
                      ? 'Su iOS il monitoraggio funziona solo mentre l\'app è aperta.'
                      : 'Riproduce un avviso sul telefono quando un auricolare '
                          'esce dal raggio Bluetooth, anche ad app chiusa.',
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: _devices.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.headset_off,
                              size: 72, color: Colors.grey),
                          const SizedBox(height: 16),
                          const Text(
                            'Nessun auricolare salvato.\n'
                            'Aggiungi i tuoi auricolari per poterli ritrovare '
                            'e farli squillare quando li perdi.',
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  )
                : ListView.builder(
                    itemCount: _devices.length,
                    itemBuilder: (context, index) {
                      final device = _devices[index];
                      return ListTile(
                        leading: const Icon(Icons.headset),
                        title: Text(device.name),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete_outline),
                          onPressed: () => _removeDevice(device),
                        ),
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => FinderScreen(device: device),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addDevice,
        icon: const Icon(Icons.add),
        label: const Text('Aggiungi auricolari'),
      ),
    );
  }
}
