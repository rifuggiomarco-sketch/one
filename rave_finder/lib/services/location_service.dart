import 'package:flutter_compass/flutter_compass.dart';
import 'package:geolocator/geolocator.dart';

/// Wraps GPS position and device compass heading, and the geometry to
/// turn "my position + a friend's last known position" into a
/// direction-and-distance readout - the same math a phone's built-in
/// maps app uses, no dedicated hardware required. GPS itself needs a
/// clear view of the sky, not cell signal, so this keeps working in
/// dead zones exactly like the necklace devices do.
class LocationService {
  /// Requests both the OS location permission and makes sure the
  /// location service (GPS radio) itself is turned on.
  Future<bool> ensureReady() async {
    if (!await Geolocator.isLocationServiceEnabled()) return false;
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    return permission == LocationPermission.always ||
        permission == LocationPermission.whileInUse;
  }

  Stream<Position> get positionStream => Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 1,
        ),
      );

  /// Degrees clockwise from true north the top of the phone is pointing,
  /// null while the sensor hasn't produced a reading yet.
  Stream<double?> get headingStream =>
      FlutterCompass.events?.map((event) => event.heading) ?? const Stream.empty();

  static double distanceMeters(double lat1, double lon1, double lat2, double lon2) {
    return Geolocator.distanceBetween(lat1, lon1, lat2, lon2);
  }

  /// Compass bearing (0-360, clockwise from true north) from point 1 to
  /// point 2.
  static double bearingDegrees(double lat1, double lon1, double lat2, double lon2) {
    final bearing = Geolocator.bearingBetween(lat1, lon1, lat2, lon2);
    return (bearing + 360) % 360;
  }

  /// Angle (0-360) to rotate an on-screen arrow so it points at the
  /// friend regardless of which way the phone is currently facing.
  static double arrowAngleDegrees({
    required double myLat,
    required double myLon,
    required double friendLat,
    required double friendLon,
    required double deviceHeading,
  }) {
    final bearing = bearingDegrees(myLat, myLon, friendLat, friendLon);
    return (bearing - deviceHeading + 360) % 360;
  }
}
