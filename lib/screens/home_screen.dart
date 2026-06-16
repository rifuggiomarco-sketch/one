import 'package:flutter/material.dart';

import '../models/saved_device.dart';
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

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final devices = await _storage.loadDevices();
    if (mounted) setState(() => _devices = devices);
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Trova i tuoi auricolari')),
      body: _devices.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.headset_off, size: 72, color: Colors.grey),
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
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addDevice,
        icon: const Icon(Icons.add),
        label: const Text('Aggiungi auricolari'),
      ),
    );
  }
}
