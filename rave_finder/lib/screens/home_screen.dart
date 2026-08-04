import 'dart:async';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

import '../models/bonded_friend.dart';
import '../services/bonding_service.dart';
import '../services/identity_service.dart';
import '../services/location_service.dart';
import '../services/mesh_service.dart';
import '../services/storage_service.dart';
import 'add_friend_screen.dart';
import 'compass_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _identity = IdentityService();
  final _bonding = BondingService(StorageService());
  final _location = LocationService();
  MeshService? _mesh;

  StreamSubscription<Position>? _positionSub;
  Position? _myPosition;
  int? _myShortId;
  String? _statusMessage;

  @override
  void initState() {
    super.initState();
    _bonding.addListener(_onBondingChanged);
    _init();
  }

  void _onBondingChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _init() async {
    await _bonding.load();

    final id = await _identity.getOrCreateMyShortId();
    final mesh = MeshService(myShortId: id, onPacket: _bonding.applyPacket);
    await mesh.requestPermissions();

    final locationReady = await _location.ensureReady();
    if (!locationReady) {
      if (mounted) {
        setState(() {
          _statusMessage =
              'Attiva il GPS e concedi il permesso di posizione per usare la bussola.';
        });
      }
    }

    await mesh.start();
    _positionSub = _location.positionStream.listen((position) {
      mesh.updateMyLocation(position.latitude, position.longitude);
      if (mounted) setState(() => _myPosition = position);
    });

    if (mounted) {
      setState(() {
        _mesh = mesh;
        _myShortId = id;
      });
    }
  }

  Future<void> _addFriend() async {
    if (_myShortId == null) return;
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AddFriendScreen(myShortId: _myShortId!, bonding: _bonding),
      ),
    );
  }

  void _openCompass(BondedFriend friend) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CompassScreen(friend: friend, location: _location, bonding: _bonding),
      ),
    );
  }

  String? _distanceLabel(BondedFriend friend) {
    if (_myPosition == null || !friend.hasLocation) return null;
    final meters = LocationService.distanceMeters(
      _myPosition!.latitude,
      _myPosition!.longitude,
      friend.lastLat!,
      friend.lastLon!,
    );
    return meters < 1000 ? '${meters.round()} m' : '${(meters / 1000).toStringAsFixed(1)} km';
  }

  String _lastSeenLabel(BondedFriend friend) {
    final seenAt = friend.lastSeenAt;
    if (seenAt == null) return 'Mai visto';
    final ago = DateTime.now().difference(seenAt);
    if (ago.inSeconds < 60) return 'visto ${ago.inSeconds}s fa';
    if (ago.inMinutes < 60) return 'visto ${ago.inMinutes}min fa';
    return 'visto ${ago.inHours}h fa';
  }

  @override
  void dispose() {
    _bonding.removeListener(_onBondingChanged);
    _positionSub?.cancel();
    _mesh?.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final friends = _bonding.friends;
    return Scaffold(
      appBar: AppBar(title: const Text('RaveFinder')),
      body: Column(
        children: [
          if (_statusMessage != null)
            Container(
              width: double.infinity,
              color: Theme.of(context).colorScheme.errorContainer,
              padding: const EdgeInsets.all(12),
              child: Text(
                _statusMessage!,
                style: TextStyle(color: Theme.of(context).colorScheme.onErrorContainer),
              ),
            ),
          Expanded(
            child: friends.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.groups_outlined, size: 72, color: Colors.grey),
                          const SizedBox(height: 16),
                          const Text(
                            'Nessun amico bondato.\n'
                            'Prima del festival, scambia il tuo codice con i tuoi amici '
                            'per poterli ritrovare nella folla.',
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  )
                : ListView.builder(
                    itemCount: friends.length,
                    itemBuilder: (context, index) {
                      final friend = friends[index];
                      final distance = _distanceLabel(friend);
                      return ListTile(
                        leading: CircleAvatar(backgroundColor: friend.color),
                        title: Text(friend.name),
                        subtitle: Text(
                          friend.hasLocation
                              ? '${distance ?? "distanza sconosciuta"} · ${_lastSeenLabel(friend)}'
                              : 'Ancora nessun segnale',
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete_outline),
                          onPressed: () => _bonding.removeFriend(friend.shortId),
                        ),
                        onTap: () => _openCompass(friend),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addFriend,
        icon: const Icon(Icons.person_add_alt),
        label: const Text('Aggiungi amico'),
      ),
    );
  }
}
