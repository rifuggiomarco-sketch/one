import 'dart:typed_data';

/// A location broadcast carried inside a BLE advertisement's
/// manufacturer-specific data. Every device periodically advertises its
/// own packet, and relays other devices' packets (decrementing [ttl]) to
/// flood the mesh beyond direct Bluetooth range.
///
/// Wire format (16 bytes), all multi-byte fields big-endian:
///   byte 0      version
///   byte 1-4    senderId (uint32)
///   byte 5      ttl (0-15)
///   byte 6-9    lat, as round(lat * 1e6) (int32)
///   byte 10-13  lon, as round(lon * 1e6) (int32)
///   byte 14-15  seq (uint16), rolls over per sender
class MeshPacket {
  static const int wireVersion = 1;
  static const int byteLength = 16;

  /// Not registered with the Bluetooth SIG - 0xFFFF is reserved by spec
  /// for development/testing use and is fine for a small indie app, but
  /// should be swapped for a real registered Company ID before any
  /// large-scale commercial release.
  static const int companyId = 0xFFFF;

  final int senderId;
  final int ttl;
  final double lat;
  final double lon;
  final int seq;

  const MeshPacket({
    required this.senderId,
    required this.ttl,
    required this.lat,
    required this.lon,
    required this.seq,
  });

  MeshPacket relayed() => MeshPacket(
        senderId: senderId,
        ttl: ttl - 1,
        lat: lat,
        lon: lon,
        seq: seq,
      );

  Uint8List toBytes() {
    final data = ByteData(byteLength);
    data.setUint8(0, wireVersion);
    data.setUint32(1, senderId, Endian.big);
    data.setUint8(5, ttl.clamp(0, 15));
    data.setInt32(6, (lat * 1e6).round(), Endian.big);
    data.setInt32(10, (lon * 1e6).round(), Endian.big);
    data.setUint16(14, seq & 0xFFFF, Endian.big);
    return data.buffer.asUint8List();
  }

  static MeshPacket? tryParse(Uint8List bytes) {
    if (bytes.length < byteLength) return null;
    final data = ByteData.sublistView(bytes);
    if (data.getUint8(0) != wireVersion) return null;
    return MeshPacket(
      senderId: data.getUint32(1, Endian.big),
      ttl: data.getUint8(5) & 0x0F,
      lat: data.getInt32(6, Endian.big) / 1e6,
      lon: data.getInt32(10, Endian.big) / 1e6,
      seq: data.getUint16(14, Endian.big),
    );
  }

  /// Key used to deduplicate a packet as it floods through the mesh:
  /// the same (sender, seq) pair arriving via multiple hops is one event.
  String get dedupeKey => '$senderId:$seq';
}
