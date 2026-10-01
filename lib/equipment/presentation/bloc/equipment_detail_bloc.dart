import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../compliance/application/compliance_queries.dart';
import '../../../compliance/domain/compliance.dart';
import '../../../reporting/application/reporting_queries.dart';
import '../../../reporting/domain/reporting.dart';
import '../../../shared/domain/failure.dart';
import '../../../shared/infrastructure/http/api_exception_mapper.dart';
import '../../../shared/presentation/remote_state.dart';
import '../../../shared/presentation/section.dart';
import '../../../tracking/application/telemetry_queries.dart';
import '../../../tracking/domain/telemetry.dart';
import '../../application/equipment_queries.dart';
import '../../domain/equipment.dart';

/// Everything shown on the equipment detail screen. Secondary sections are
/// loaded independently so one failing endpoint does not hide the others.
final class EquipmentDetail extends Equatable {
  const EquipmentDetail({
    required this.equipment,
    this.telemetry,
    this.bpmConfigs = const Section.empty(),
    this.maintenance = const Section.empty(),
    this.trends = const Section.empty(),
    this.events = const Section.empty(),
    this.auditLogs = const Section.empty(),
  });

  final Equipment equipment;
  final EquipmentTelemetryStatus? telemetry;
  final Section<BpmParameterConfig> bpmConfigs;
  final Section<MaintenanceRecord> maintenance;
  final Section<DeviationTrend> trends;
  final Section<ComplianceEvent> events;
  final Section<AuditLogEntry> auditLogs;

  @override
  List<Object?> get props => [equipment, telemetry, bpmConfigs, maintenance, trends, events, auditLogs];
}

sealed class EquipmentDetailEvent extends Equatable {
  const EquipmentDetailEvent();

  @override
  List<Object?> get props => [];
}

final class EquipmentDetailRequested extends EquipmentDetailEvent {
  const EquipmentDetailRequested({this.refresh = false});

  final bool refresh;

  @override
  List<Object?> get props => [refresh];
}

class EquipmentDetailBloc extends Bloc<EquipmentDetailEvent, RemoteState<EquipmentDetail>> {
  EquipmentDetailBloc({
    required this.equipmentId,
    required GetEquipment getEquipment,
    required GetTelemetryStatus getTelemetryStatus,
    required GetBpmConfigs getBpmConfigs,
    required GetMaintenanceHistory getMaintenance,
    required GetDeviationTrends getTrends,
    required GetEquipmentComplianceEvents getEvents,
    required GetEquipmentAuditLogs getAuditLogs,
  }) : _getEquipment = getEquipment,
       _getTelemetryStatus = getTelemetryStatus,
       _getBpmConfigs = getBpmConfigs,
       _getMaintenance = getMaintenance,
       _getTrends = getTrends,
       _getEvents = getEvents,
       _getAuditLogs = getAuditLogs,
       super(const RemoteState()) {
    on<EquipmentDetailRequested>(_onRequested);
  }

  final int equipmentId;
  final GetEquipment _getEquipment;
  final GetTelemetryStatus _getTelemetryStatus;
  final GetBpmConfigs _getBpmConfigs;
  final GetMaintenanceHistory _getMaintenance;
  final GetDeviationTrends _getTrends;
  final GetEquipmentComplianceEvents _getEvents;
  final GetEquipmentAuditLogs _getAuditLogs;

  Future<void> _onRequested(
    EquipmentDetailRequested event,
    Emitter<RemoteState<EquipmentDetail>> emit,
  ) async {
    emit(event.refresh && state.hasData ? state.refreshingState() : state.loading());
    try {
      final equipment = await _getEquipment(equipmentId);
      final results = await Future.wait<Object?>([
        _statusOrNull(),
        Section.load(() => _getBpmConfigs(equipmentId)),
        Section.load(() => _getMaintenance(equipmentId)),
        Section.load(() => _getTrends(equipmentId)),
        Section.load(() => _getEvents(equipmentId)),
        Section.load(() => _getAuditLogs(equipmentId)),
      ]);
      emit(state.success(EquipmentDetail(
        equipment: equipment,
        telemetry: results[0] as EquipmentTelemetryStatus?,
        bpmConfigs: results[1]! as Section<BpmParameterConfig>,
        maintenance: results[2]! as Section<MaintenanceRecord>,
        trends: results[3]! as Section<DeviationTrend>,
        events: results[4]! as Section<ComplianceEvent>,
        auditLogs: results[5]! as Section<AuditLogEntry>,
      )));
    } catch (error) {
      emit(state.failed(ApiExceptionMapper.map(error)));
    }
  }

  Future<EquipmentTelemetryStatus?> _statusOrNull() async {
    try {
      return await _getTelemetryStatus(equipmentId);
    } on UnauthorizedFailure {
      rethrow;
    } on Failure {
      return null;
    }
  }
}
