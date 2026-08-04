import 'dart:async';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

import '../models/bonded_friend.dart';
import '../services/bonding_service.dart';
import '../services/location_service.dart';
import '../widgets/compass_arrow.dart';

/// Full-screen "point at your friend" view: an arrow rotated using this
/// phone's live GPS position + compass heading against the friend's
/// last known position received over the mesh, plus the distance
/// between the two - the software equivalent of the necklaces'
/// Compass Mode.
class CompassScreen extends StatefulWidget {
  final BondedFriend friend;
  final LocationService location;
  final BondingService bonding;

  const CompassScreen({
    super.key,
    required this.friend,
    required this.location,
    required this.bonding,
  });

  @override
  State<CompassScreen> createState() => _CompassScreenState();
}

class _CompassScreenState extends State<CompassScreen> {
  StreamSubscription<Position>? _positionSub;
  StreamSubscription<double?>? _headingSub;
  Position? _myPosition;
  double? _heading;

  @override
  void initState() {
    super.initState();
    widget.bonding.addListener(_onFriendUpdated);
    _positionSub = widget.location.positionStream.listen((position) {
      if (mounted) setState(() => _myPosition = position);
    });
    _headingSub = widget.location.headingStream.listen((heading) {
      if (mounted) setState(() => _heading = heading);
    });
  }

  void _onFriendUpdated() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    widget.bonding.removeListener(_onFriendUpdated);
    _positionSub?.cancel();
    _headingSub?.cancel();
    super.dispose();
  }

  String _lastSeenLabel() {
    final seenAt = widget.friend.lastSeenAt;
    if (seenAt == null) return '';
    final ago = DateTime.now().difference(seenAt);
    if (ago.inSeconds < 60) return 'Aggiornato ${ago.inSeconds}s fa';
    if (ago.inMinutes < 60) return 'Aggiornato ${ago.inMinutes}min fa';
    return 'Aggiornato ${ago.inHours}h fa';
  }

  @override
  Widget build(BuildContext context) {
    final friend = widget.friend;
    final myPosition = _myPosition;

    double angle = 0;
    double? distanceMeters;
    if (myPosition != null && friend.hasLocation) {
      distanceMeters = LocationService.distanceMeters(
        myPosition.latitude,
        myPosition.longitude,
        friend.lastLat!,
        friend.lastLon!,
      );
      if (_heading != null) {
        angle = LocationService.arrowAngleDegrees(
          myLat: myPosition.latitude,
          myLon: myPosition.longitude,
          friendLat: friend.lastLat!,
          friendLon: friend.lastLon!,
          deviceHeading: _heading!,
        );
      }
    }

    return Scaffold(
      appBar: AppBar(title: Text(friend.name)),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CompassArrow(angleDegrees: angle, color: friend.color),
              const SizedBox(height: 32),
              if (!friend.hasLocation)
                const Text(
                  'In attesa del segnale del tuo amico...\n'
                  'Deve avere l\'app aperta ed essere entro la portata '
                  'Bluetooth, diretta o tramite la rete mesh.',
                  textAlign: TextAlign.center,
                )
              else if (myPosition == null)
                const Text('In attesa della tua posizione GPS...', textAlign: TextAlign.center)
              else if (_heading == null)
                const Text('Bussola non disponibile su questo dispositivo.', textAlign: TextAlign.center)
              else ...[
                Text(
                  distanceMeters! < 1000
                      ? '${distanceMeters.round()} m'
                      : '${(distanceMeters / 1000).toStringAsFixed(1)} km',
                  style: Theme.of(context)
                      .textTheme
                      .displaySmall
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(_lastSeenLabel(), style: Theme.of(context).textTheme.bodyMedium),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
