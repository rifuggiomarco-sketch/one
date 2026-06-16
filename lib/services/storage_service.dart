import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/saved_device.dart';

class StorageService {
  static const _kSavedDevicesKey = 'saved_devices';

  Future<List<SavedDevice>> loadDevices() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_kSavedDevicesKey) ?? [];
    return raw
        .map((e) => SavedDevice.fromJson(jsonDecode(e) as Map<String, dynamic>))
        .toList();
  }

  Future<void> saveDevices(List<SavedDevice> devices) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = devices.map((d) => jsonEncode(d.toJson())).toList();
    await prefs.setStringList(_kSavedDevicesKey, raw);
  }

  Future<void> addDevice(SavedDevice device) async {
    final devices = await loadDevices();
    devices.removeWhere((d) => d.remoteId == device.remoteId);
    devices.add(device);
    await saveDevices(devices);
  }

  Future<void> removeDevice(String remoteId) async {
    final devices = await loadDevices();
    devices.removeWhere((d) => d.remoteId == remoteId);
    await saveDevices(devices);
  }
}
