enum ReceiptStatus {
  quarantined('QUARANTINED'),
  released('RELEASED'),
  observed('OBSERVED'),
  rejected('REJECTED'),
  unknown('UNKNOWN');

  const ReceiptStatus(this.code);

  final String code;

  static ReceiptStatus fromCode(String? code) {
    for (final value in values) {
      if (value.code == code) return value;
    }
    return ReceiptStatus.unknown;
  }
}
