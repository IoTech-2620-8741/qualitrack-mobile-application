import '../../../shared/presentation/l10n/app_localizations.dart';
import '../../../shared/presentation/widgets/status_badge.dart';
import '../../domain/inventory.dart';

extension ReceiptStatusPresentation on ReceiptStatus {
  BadgeTone get tone => switch (this) {
    ReceiptStatus.quarantined => BadgeTone.warning,
    ReceiptStatus.released => BadgeTone.success,
    ReceiptStatus.observed => BadgeTone.info,
    ReceiptStatus.rejected => BadgeTone.critical,
    ReceiptStatus.unknown => BadgeTone.neutral,
  };

  String label(AppLocalizations l10n) => switch (this) {
    ReceiptStatus.quarantined => l10n.receiptQuarantined,
    ReceiptStatus.released => l10n.receiptReleased,
    ReceiptStatus.observed => l10n.receiptObserved,
    ReceiptStatus.rejected => l10n.receiptRejected,
    ReceiptStatus.unknown => l10n.unknown,
  };
}

extension InventoryMaterialPresentation on InventoryMaterial {
  BadgeTone get stockTone => isBelowMinimum ? BadgeTone.critical : BadgeTone.success;

  String stockLabel(AppLocalizations l10n) => isBelowMinimum ? l10n.belowMinimum : l10n.stockOk;
}

/// `RECEIPT`, `REVIEW`, `STORAGE` or `CONSUMPTION`.
String movementTypeLabel(AppLocalizations l10n, String type) => switch (type) {
  'RECEIPT' => l10n.movementReceipt,
  'REVIEW' => l10n.movementReview,
  'STORAGE' => l10n.movementStorage,
  'CONSUMPTION' => l10n.movementConsumption,
  _ => type,
};

/// Why a lot cannot be consumed: expired, not received yet, depleted or its status.
String lotAvailabilityLabel(AppLocalizations l10n, String? availability) => switch (availability) {
  'EXPIRED' => l10n.lotExpired,
  'NOT_YET_RECEIVED' => l10n.lotNotYetReceived,
  'DEPLETED' => l10n.lotDepleted,
  _ => ReceiptStatus.fromCode(availability).label(l10n),
};
