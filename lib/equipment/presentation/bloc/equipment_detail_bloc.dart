import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../compliance/api/index.dart';
import '../../../laboratory/api/index.dart';
import '../../../reporting/api/index.dart';
import '../../../common/domain/failure.dart';
import '../../../common/domain/value_objects.dart';
import '../../../common/presentation/remote_state.dart';
import '../../../common/presentation/section.dart';
import '../../../tracking/api/index.dart';
import '../../application/equipment_facade_service.dart';
import '../../domain/entities/bpm_parameter_config.dart';
import '../../domain/entities/equipment.dart';
import '../../domain/entities/maintenance_record.dart';

/// Everything shown on the equipment detail screen. Secondary sections are
/// loaded independently so one failing endpoint does not hide the others.
final class EquipmentDetail extends Equatable {
  const EquipmentDetail({
    required this.equipment,
    this.environmentName,
    this.connection,
    this.bpmConfigs = const Section.empty(),
    this.maintenance = const Section.empty(),
    this.trends = const Section.empty(),
    this.events = const Section.empty(),
    this.auditLogs = const Section.empty(),
    this.people = const {},
  });

  final Equipment equipment;
  final String? environmentName;
  final DeviceConnection? connection;
  final Section<BpmParameterConfig> bpmConfigs;
  final Section<MaintenanceRecord> maintenance;

  /// Deviation indicators of the device in the last 7 days.
  final Section<DeviationTrend> trends;
  final Section<ComplianceEvent> events;
  final Section<AuditLogEntry> auditLogs;
  final Map<int, String> people;

  @override
  List<Object?> get props => [
    equipment,
    environmentName,
    connection,
    bpmConfigs,
    maintenance,
    trends,
    events,
    auditLogs,
    people,
  ];
}

final class EquipmentDetailRequested extends Equatable {
  const EquipmentDetailRequested({this.refresh = false});

  final bool refresh;

  @override
  List<Object?> get props => [refresh];
}

class EquipmentDetailBloc extends Bloc<EquipmentDetailRequested, RemoteState<EquipmentDetail>> {
  EquipmentDetailBloc({
    required this.equipmentId,
    required EquipmentFacadeService equipmentService,
    required LaboratoryApi laboratoryApi,
    required TelemetryApi telemetryApi,
    required GetDeviationTrends getTrends,
    required ComplianceApi complianceApi,
    required GetEquipmentAuditLogs getAuditLogs,
    required LaboratoryId Function() laboratoryId,
  }) : _equipmentService = equipmentService,
       _laboratoryApi = laboratoryApi,
       _telemetryApi = telemetryApi,
       _getTrends = getTrends,
       _complianceApi = complianceApi,
       _getAuditLogs = getAuditLogs,
       _laboratoryId = laboratoryId,
       super(const RemoteState()) {
    on<EquipmentDetailRequested>(_onRequested);
  }

  final int equipmentId;
  final EquipmentFacadeService _equipmentService;
  final LaboratoryApi _laboratoryApi;
  final TelemetryApi _telemetryApi;
  final GetDeviationTrends _getTrends;
  final ComplianceApi _complianceApi;
  final GetEquipmentAuditLogs _getAuditLogs;
  final LaboratoryId Function() _laboratoryId;

  Future<void> _onRequested(EquipmentDetailRequested event, Emitter<RemoteState<EquipmentDetail>> emit) async {
    emit(event.refresh && state.hasData ? state.refreshingState() : state.loading());
    try {
      final lab = _laboratoryId();
      final equipment = await _equipmentService.getEquipment(lab, equipmentId);
      final target = targetOf(equipment);
      final environmentId = equipment.environmentId;
      final results = await Future.wait<Object?>([
        _optional(() async {
          for (final environment in await _laboratoryApi.getEnvironments(lab)) {
            if (environment.id == environmentId) return environment.displayName;
          }
          return null;
        }),
        target == null ? Future<DeviceConnection?>.value() : _optional(() => _telemetryApi.getConnection(lab, target)),
        Section.load(() => _equipmentService.getBpmConfigs(lab, equipmentId)),
        Section.load(() => _equipmentService.getMaintenanceHistory(lab, equipment)),
        Section.load(() async {
          if (target == null) return const <DeviationTrend>[];
          final trends = await _getTrends(lab, [target.environmentId], ReportPeriod.last7Days);
          return trends.where((t) => t.equipmentId == equipmentId).toList();
        }),
        Section.load(() => _complianceApi.getEquipmentEvents(lab, equipmentId)),
        Section.load(() => _getAuditLogs(lab, equipmentId)),
        _optional(() => _laboratoryApi.getUserDirectory(lab)),
      ]);
      emit(state.success(EquipmentDetail(
        equipment: equipment,
        environmentName: results[0] as String?,
        connection: results[1] as DeviceConnection?,
        bpmConfigs: results[2]! as Section<BpmParameterConfig>,
        maintenance: results[3]! as Section<MaintenanceRecord>,
        trends: results[4]! as Section<DeviationTrend>,
        events: results[5]! as Section<ComplianceEvent>,
        auditLogs: results[6]! as Section<AuditLogEntry>,
        people: (results[7] as Map<int, String>?) ?? const {},
      )));
    } catch (error) {
      emit(state.failed(Failure.from(error)));
    }
  }

  Future<T?> _optional<T>(Future<T?> Function() read) async {
    try {
      return await read();
    } on UnauthorizedFailure {
      rethrow;
    } on Failure {
      return null;
    }
  }
}
