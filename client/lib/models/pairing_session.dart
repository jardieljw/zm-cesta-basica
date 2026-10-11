class PairingInitData {
  final String pinCode;
  final DateTime expiresAt;
  final String serverUrl;
  final String tlsFingerprintSha256;
  final String qrPayload;

  PairingInitData({
    required this.pinCode,
    required this.expiresAt,
    required this.serverUrl,
    required this.tlsFingerprintSha256,
    required this.qrPayload,
  });

  factory PairingInitData.fromJson(Map<String, dynamic> json) {
    return PairingInitData(
      pinCode: json['pin_code'] as String,
      expiresAt: DateTime.parse(json['expires_at'] as String),
      serverUrl: json['server_url'] as String,
      tlsFingerprintSha256: json['tls_fingerprint_sha256'] as String,
      qrPayload: json['qr_payload'] as String,
    );
  }
}

class QrPayloadData {
  final String serverUrl;
  final String tlsFingerprintSha256;
  final String pinCode;
  final DateTime expiresAt;

  QrPayloadData({
    required this.serverUrl,
    required this.tlsFingerprintSha256,
    required this.pinCode,
    required this.expiresAt,
  });

  factory QrPayloadData.fromJson(Map<String, dynamic> json) {
    return QrPayloadData(
      serverUrl: json['server_url'] as String,
      tlsFingerprintSha256: json['tls_fingerprint_sha256'] as String,
      pinCode: json['pin_code'] as String,
      expiresAt: DateTime.parse(json['expires_at'] as String),
    );
  }
}
