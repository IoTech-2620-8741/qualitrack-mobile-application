import 'package:flutter/material.dart';

import '../../../common/presentation/i18n/app_localizations.dart';
import '../../../common/presentation/widgets/status_badge.dart';
import '../../domain/entities/equipment.dart';
import '../../domain/entities/equipment_status.dart';
import '../../domain/entities/iot_device_type.dart';

extension EquipmentStatusPresentation on EquipmentStatus {
  BadgeTone get tone => switch (this) {
    EquipmentStatus.operational => BadgeTone.success,
    EquipmentStatus.maintenance => BadgeTone.warning,
    EquipmentStatus.outOfService => BadgeTone.critical,
    EquipmentStatus.inactive => BadgeTone.neutral,
    EquipmentStatus.unknown => BadgeTone.neutral,
  };

  String label(AppLocalizations i18n) => switch (this) {
    EquipmentStatus.operational => i18n.equipmentOperational,
    EquipmentStatus.maintenance => i18n.equipmentMaintenance,
    EquipmentStatus.outOfService => i18n.equipmentOutOfService,
    EquipmentStatus.inactive => i18n.inactive,
    EquipmentStatus.unknown => i18n.unknown,
  };
}

extension EquipmentLabel on Equipment {
  String statusLabel(AppLocalizations i18n) =>
      status == EquipmentStatus.unknown && rawStatus != null ? rawStatus! : status.label(i18n);

  /// IoT devices are named by their role, as in QualiTrack Web: the backend
  /// stores the role code (`CONTAINER_MONITOR`) as their type.
  /// An Edge Gateway is named "Edge Gateway" instead of its type code.
  String? typeLabel(AppLocalizations i18n) =>
      deviceType?.label(i18n) ?? (isEdgeGateway ? i18n.edgeGateway : type);
}

/// Icon of the kind of equipment, the same in the list and the detail.
extension EquipmentKindIcon on Equipment {
  IconData get kindIcon =>
      isIotDevice ? Icons.sensors : (isEdgeGateway ? Icons.router_outlined : Icons.precision_manufacturing_outlined);
}

extension IotDeviceTypePresentation on IotDeviceType {
  String label(AppLocalizations i18n) => switch (this) {
    IotDeviceType.environmentalDevice => i18n.environmentalDevice,
    IotDeviceType.containerMonitor => i18n.containerMonitor,
  };
}
