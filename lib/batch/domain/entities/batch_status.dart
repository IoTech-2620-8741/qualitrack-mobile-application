enum BatchStatus {
  pending('PENDING'),
  inProgress('IN_PROGRESS'),
  released('RELEASED'),
  rejected('REJECTED'),
  unknown('UNKNOWN');

  const BatchStatus(this.code);

  final String code;

  static BatchStatus fromCode(String? code) {
    for (final value in values) {
      if (value.code == code) return value;
    }
    return BatchStatus.unknown;
  }
}
