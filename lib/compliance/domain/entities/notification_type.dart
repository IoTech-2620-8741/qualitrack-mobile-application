/// `NotificationType` of the in-app notifications (the bell).
enum NotificationType {
  alertOpened('ALERT_OPENED'),
  alertEscalated('ALERT_ESCALATED'),
  alertAcknowledged('ALERT_ACKNOWLEDGED'),
  alertResolved('ALERT_RESOLVED'),
  batchReleased('BATCH_RELEASED'),
  batchRejected('BATCH_REJECTED'),
  unknown('UNKNOWN');

  const NotificationType(this.code);

  final String code;

  static NotificationType fromCode(String? code) {
    for (final value in values) {
      if (value.code == code) return value;
    }
    return NotificationType.unknown;
  }
}
