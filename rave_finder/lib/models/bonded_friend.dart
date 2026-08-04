import 'package:flutter/material.dart';

/// Converts a 32-bit mesh identity into the human-friendly code shown on
/// the "add friend" screen (8 uppercase hex chars, e.g. "A1B2C3D4").
String shortIdToCode(int shortId) =>
    shortId.toRadixString(16).padLeft(8, '0').toUpperCase();

/// Parses a code entered by the user back into a mesh identity, or null
/// if it isn't a valid 8-hex-digit code.
int? codeToShortId(String code) {
  final cleaned = code.trim().toUpperCase();
  if (!RegExp(r'^[0-9A-F]{8}$').hasMatch(cleaned)) return null;
  return int.parse(cleaned, radix: 16);
}

/// A friend this device has been bonded with before the event. Location
/// fields are updated live as mesh packets from this friend's [shortId]
/// arrive, directly or relayed through other phones.
class BondedFriend {
  final int shortId;
  String name;
  final Color color;
  double? lastLat;
  double? lastLon;
  DateTime? lastSeenAt;
  int? lastSeq;
  int? lastHops;

  BondedFriend({
    required this.shortId,
    required this.name,
    required this.color,
    this.lastLat,
    this.lastLon,
    this.lastSeenAt,
    this.lastSeq,
    this.lastHops,
  });

  String get code => shortIdToCode(shortId);

  bool get hasLocation => lastLat != null && lastLon != null;

  Map<String, dynamic> toJson() => {
        'shortId': shortId,
        'name': name,
        'color': color.toARGB32(),
      };

  factory BondedFriend.fromJson(Map<String, dynamic> json) => BondedFriend(
        shortId: json['shortId'] as int,
        name: json['name'] as String,
        color: Color(json['color'] as int),
      );
}
