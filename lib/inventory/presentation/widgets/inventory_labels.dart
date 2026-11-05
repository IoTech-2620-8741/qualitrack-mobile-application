import '../../../common/presentation/i18n/app_localizations.dart';
import '../../../common/presentation/widgets/status_badge.dart';
import '../../domain/entities/inventory_material.dart';
import '../../domain/entities/receipt_status.dart';

extension ReceiptStatusPresentation on ReceiptStatus {
  BadgeTone get tone => switch (this) {
    ReceiptStatus.quarantined => BadgeTone.warning,
    ReceiptStatus.released => BadgeTone.success,
    ReceiptStatus.observed => BadgeTone.info,
    ReceiptStatus.rejected => BadgeTone.critical,
    ReceiptStatus.unknown => BadgeTone.neutral,
  };

  String label(AppLocalizations i18n) => switch (this) {
    ReceiptStatus.quarantined => i18n.receiptQuarantined,
    ReceiptStatus.released => i18n.receiptReleased,
    ReceiptStatus.observed => i18n.receiptObserved,
    ReceiptStatus.rejected => i18n.receiptRejected,
    ReceiptStatus.unknown => i18n.unknown,
  };
}

extension InventoryMaterialPresentation on InventoryMaterial {
  BadgeTone get stockTone => isBelowMinimum ? BadgeTone.critical : BadgeTone.success;

  String stockLabel(AppLocalizations i18n) => isBelowMinimum ? i18n.belowMinimum : i18n.stockOk;
}

/// `RECEIPT`, `REVIEW`, `STORAGE` or `CONSUMPTION`.
String movementTypeLabel(AppLocalizations i18n, String type) => switch (type) {
  'RECEIPT' => i18n.movementReceipt,
  'REVIEW' => i18n.movementReview,
  'STORAGE' => i18n.movementStorage,
  'CONSUMPTION' => i18n.movementConsumption,
  _ => type,
};

/// Why a lot cannot be consumed: expired, not received yet, depleted or its status.
String lotAvailabilityLabel(AppLocalizations i18n, String? availability) => switch (availability) {
  'EXPIRED' => i18n.lotExpired,
  'NOT_YET_RECEIVED' => i18n.lotNotYetReceived,
  'DEPLETED' => i18n.lotDepleted,
  _ => ReceiptStatus.fromCode(availability).label(i18n),
};
