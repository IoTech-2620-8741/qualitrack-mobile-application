import 'package:equatable/equatable.dart';

/// Raw material of an environment (`RawMaterialResource`). Stock values are
/// derived by the backend from its lots.
class InventoryMaterial extends Equatable {
  const InventoryMaterial({
    required this.id,
    required this.laboratoryId,
    required this.environmentId,
    required this.code,
    required this.name,
    required this.unit,
    required this.minimumStock,
    required this.usableStock,
    required this.physicalStock,
    this.stockStatus,
    this.legacyId,
  });

  final int id;
  final int laboratoryId;
  final int environmentId;
  final String code;
  final String name;
  final String unit;
  final double minimumStock;
  final double usableStock;
  final double physicalStock;

  /// `LOW` or `SUFFICIENT`, classified by the backend (TS27).
  final String? stockStatus;
  final int? legacyId;

  /// Same rule as the Web dashboard: usable stock below the minimum.
  bool get isBelowMinimum => stockStatus == null ? usableStock < minimumStock : stockStatus == 'LOW';

  /// Physical stock exists but part of it is not usable (quarantine, observed,
  /// rejected or expired receipts).
  bool get hasBlockedStock => physicalStock > usableStock;

  bool matches(String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return true;
    return name.toLowerCase().contains(q) || code.toLowerCase().contains(q);
  }

  @override
  List<Object?> get props => [
    id,
    laboratoryId,
    environmentId,
    code,
    name,
    unit,
    minimumStock,
    usableStock,
    physicalStock,
    stockStatus,
    legacyId,
  ];
}
