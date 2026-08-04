import 'package:flutter/material.dart';

import '../models/bonded_friend.dart';
import '../models/mesh_packet.dart';
import 'storage_service.dart';

/// Keeps the list of bonded friends in memory, persists it, and updates
/// each friend's live position as mesh packets arrive.
class BondingService extends ChangeNotifier {
  BondingService(this._storage);

  final StorageService _storage;
  final List<BondedFriend> _friends = [];

  List<BondedFriend> get friends => List.unmodifiable(_friends);

  bool get isEmpty => _friends.isEmpty;

  Future<void> load() async {
    _friends
      ..clear()
      ..addAll(await _storage.loadFriends());
    notifyListeners();
  }

  BondedFriend? byShortId(int shortId) {
    for (final friend in _friends) {
      if (friend.shortId == shortId) return friend;
    }
    return null;
  }

  Future<bool> addFriend({
    required int shortId,
    required String name,
    required Color color,
  }) async {
    if (byShortId(shortId) != null) return false;
    _friends.add(BondedFriend(shortId: shortId, name: name, color: color));
    await _storage.saveFriends(_friends);
    notifyListeners();
    return true;
  }

  Future<void> removeFriend(int shortId) async {
    _friends.removeWhere((friend) => friend.shortId == shortId);
    await _storage.saveFriends(_friends);
    notifyListeners();
  }

  /// Called for every packet the mesh receives, bonded sender or not;
  /// updates the matching friend's last-known position if this packet
  /// is newer than what we already have for them.
  void applyPacket(MeshPacket packet) {
    final friend = byShortId(packet.senderId);
    if (friend == null) return;
    if (friend.lastSeq != null && !_isNewer(friend.lastSeq!, packet.seq)) {
      return;
    }
    friend.lastLat = packet.lat;
    friend.lastLon = packet.lon;
    friend.lastSeq = packet.seq;
    friend.lastSeenAt = DateTime.now();
    notifyListeners();
  }

  /// uint16 sequence numbers wrap around, so "is this newer" needs a
  /// wraparound-aware comparison instead of plain `>`.
  bool _isNewer(int oldSeq, int newSeq) {
    final diff = (newSeq - oldSeq) & 0xFFFF;
    return diff != 0 && diff < 0x8000;
  }
}
