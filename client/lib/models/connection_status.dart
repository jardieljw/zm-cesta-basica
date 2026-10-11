enum ConnectionState {
  disconnected,
  connecting,
  connected,
  unpaired,
  error,
}

class ServerStatus {
  final bool isOnline;
  final String? version;
  final String? databaseStatus;
  final String? tlsFingerprint;
  final String? errorMessage;

  ServerStatus({
    required this.isOnline,
    this.version,
    this.databaseStatus,
    this.tlsFingerprint,
    this.errorMessage,
  });
}
