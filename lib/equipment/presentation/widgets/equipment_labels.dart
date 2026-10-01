import '../../../shared/presentation/l10n/app_localizations.dart';
import '../../../shared/presentation/widgets/status_badge.dart';
import '../../domain/equipment.dart';

extension EquipmentStatusPresentation on EquipmentStatus {
  BadgeTone get tone => switch (this) {
    EquipmentStatus.operational => BadgeTone.success,
    EquipmentStatus.maintenance => BadgeTone.warning,
    EquipmentStatus.outOfService => BadgeTone.critical,
    EquipmentStatus.inactive => BadgeTone.neutral,
    EquipmentStatus.unknown => BadgeTone.neutral,
  };

  String label(AppLocalizations l10n) => switch (this) {
    EquipmentStatus.operational => l10n.equipmentOperational,
    EquipmentStatus.maintenance => l10n.equipmentMaintenance,
    EquipmentStatus.outOfService => l10n.equipmentOutOfService,
    EquipmentStatus.inactive => l10n.inactive,
    EquipmentStatus.unknown => l10n.unknown,
  };
}

extension EquipmentLabel on Equipment {
  String statusLabel(AppLocalizations l10n) =>
      status == EquipmentStatus.unknown && rawStatus != null ? rawStatus! : status.label(l10n);
}
