/// `DeviceConnectionStatus` (TS41): a device that has not communicated within
/// its expected period requires review.
enum ConnectionStatus {
  connected('CONNECTED'),
  requiresReview('REQUIRES_REVIEW'),
  unknown('');

  const ConnectionStatus(this.code);

  final String code;

  static ConnectionStatus fromCode(String? code) {
    for (final value in values) {
      if (value != unknown && value.code == code) return value;
    }
    return ConnectionStatus.unknown;
  }
}
