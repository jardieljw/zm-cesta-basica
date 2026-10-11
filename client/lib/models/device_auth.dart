class DeviceAuthCredentials {
  final String deviceId;
  final String deviceName;
  final String devicePublicId;
  final String deviceToken;
  final String message;

  DeviceAuthCredentials({
    required this.deviceId,
    required this.deviceName,
    required this.devicePublicId,
    required this.deviceToken,
    required this.message,
  });

  factory DeviceAuthCredentials.fromJson(Map<String, dynamic> json) {
    return DeviceAuthCredentials(
      deviceId: json['device_id'] as String,
      deviceName: json['device_name'] as String,
      devicePublicId: json['device_public_id'] as String,
      deviceToken: json['device_token'] as String,
      message: json['message'] as String? ?? '',
    );
  }
}
