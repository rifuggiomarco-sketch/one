import 'dart:math';

import 'package:shared_preferences/shared_preferences.dart';

/// This device's persistent mesh identity: a random 32-bit id generated
/// once and reused for every packet this device ever advertises, so
/// friends can recognize it (and so relayed dedupe/seq tracking works).
class IdentityService {
  static const _prefsKey = 'rave_finder.my_short_id';

  int? _cachedId;

  Future<int> getOrCreateMyShortId() async {
    if (_cachedId != null) return _cachedId!;
    final prefs = await SharedPreferences.getInstance();
    final existing = prefs.getInt(_prefsKey);
    if (existing != null) {
      _cachedId = existing;
      return existing;
    }
    final generated = Random.secure().nextInt(0xFFFFFFFF);
    await prefs.setInt(_prefsKey, generated);
    _cachedId = generated;
    return generated;
  }
}
