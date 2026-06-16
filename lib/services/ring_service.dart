import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:volume_controller/volume_controller.dart';

/// Plays alert sounds at maximum volume.
///
/// [startRinging]/[stopRinging] loop a loud tone through whatever audio
/// output is currently active (e.g. the Bluetooth earbuds via the A2DP
/// profile), so the earbuds themselves "ring" and can be located by ear.
///
/// [playOutOfRangeWarning] instead plays a short, urgent tone on the
/// phone's own speaker to warn the user that an earbud just went out of
/// Bluetooth range.
class RingService {
  final AudioPlayer _player = AudioPlayer();
  bool _isRinging = false;

  bool get isRinging => _isRinging;

  Future<void> _maximizeVolume() async {
    VolumeController.instance.showSystemUI = false;
    await VolumeController.instance.setVolume(1.0);
  }

  Future<void> startRinging() async {
    if (_isRinging) return;
    _isRinging = true;
    await _maximizeVolume();
    await _player.setReleaseMode(ReleaseMode.loop);
    await _player.setVolume(1.0);
    await _player.play(AssetSource('sounds/alert.wav'));
  }

  Future<void> stopRinging() async {
    if (!_isRinging) return;
    _isRinging = false;
    await _player.stop();
  }

  Future<void> playOutOfRangeWarning() async {
    await _maximizeVolume();
    final warningPlayer = AudioPlayer();
    await warningPlayer.setVolume(1.0);
    await warningPlayer.play(AssetSource('sounds/warning.wav'));
    unawaited(warningPlayer.onPlayerComplete.first
        .then((_) => warningPlayer.dispose()));
  }

  void dispose() {
    _player.dispose();
  }
}
