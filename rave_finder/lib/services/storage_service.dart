import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/bonded_friend.dart';

/// Persists the list of bonded friends (identity + name + color) across
/// app restarts. Live location fields on [BondedFriend] are runtime-only
/// and are not persisted, since they go stale the moment the app closes.
class StorageService {
  static const _prefsKey = 'rave_finder.bonded_friends';

  Future<List<BondedFriend>> loadFriends() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_prefsKey) ?? const [];
    return raw
        .map((s) => BondedFriend.fromJson(jsonDecode(s) as Map<String, dynamic>))
        .toList();
  }

  Future<void> saveFriends(List<BondedFriend> friends) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = friends.map((f) => jsonEncode(f.toJson())).toList();
    await prefs.setStringList(_prefsKey, raw);
  }
}
