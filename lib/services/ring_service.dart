import 'package:audioplayers/audioplayers.dart';

/// Plays a loud alert tone on a loop. Since audio playback is routed
/// through whatever output device is currently connected (e.g. the
/// Bluetooth earbuds via the A2DP profile), this makes the earbuds
/// themselves "ring" so they can be located by ear.
class RingService {
  final AudioPlayer _player = AudioPlayer();
  bool _isRinging = false;

  bool get isRinging => _isRinging;

  Future<void> startRinging() async {
    if (_isRinging) return;
    _isRinging = true;
    await _player.setReleaseMode(ReleaseMode.loop);
    await _player.setVolume(1.0);
    await _player.play(AssetSource('sounds/alert.wav'));
  }

  Future<void> stopRinging() async {
    if (!_isRinging) return;
    _isRinging = false;
    await _player.stop();
  }

  void dispose() {
    _player.dispose();
  }
}
