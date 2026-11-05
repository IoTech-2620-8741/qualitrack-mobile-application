/// `EquipmentStatus` of the Equipment Management context. The API exposes it
/// as a String, so unknown values are preserved in [Equipment.rawStatus].
enum EquipmentStatus {
  operational('OPERATIONAL'),
  maintenance('MAINTENANCE'),
  outOfService('OUT_OF_SERVICE'),
  inactive('INACTIVE'),
  unknown('UNKNOWN');

  const EquipmentStatus(this.code);

  final String code;

  static EquipmentStatus fromCode(String? code) {
    for (final value in values) {
      if (value.code == code) return value;
    }
    return EquipmentStatus.unknown;
  }
}
