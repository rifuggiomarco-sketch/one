class SavedDevice {
  final String remoteId;
  final String name;

  const SavedDevice({required this.remoteId, required this.name});

  Map<String, String> toJson() => {'remoteId': remoteId, 'name': name};

  factory SavedDevice.fromJson(Map<String, dynamic> json) => SavedDevice(
        remoteId: json['remoteId'] as String,
        name: json['name'] as String,
      );
}
